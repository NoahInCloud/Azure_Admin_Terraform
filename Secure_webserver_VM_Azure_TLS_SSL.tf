terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

###############################
# Variables and Random Suffix
###############################
variable "resource_group_name" {
  description = "Name of the resource group for the deployment"
  default     = "myResourceGroupSecureWeb"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "myVM"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!!"  # Replace with a secure password or use a secrets manager.
}

variable "prefix" {
  description = "Prefix for resource names"
  default     = "tw"
}

resource "random_integer" "id" {
  min = 1000
  max = 9999
}

locals {
  keyvault_name = "${var.prefix}key-vault-${random_integer.id.result}"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Azure Key Vault and Certificate
###############################
resource "azurerm_key_vault" "kv" {
  name                        = local.keyvault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_deployment      = true
  # Soft delete and purge protection can be enabled as needed.
}

resource "azurerm_key_vault_certificate" "cert" {
  name         = "mycert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject            = "CN=www.tomwechsler.ch"
      validity_in_months = 12
    }
  }
}

###############################
# Networking: Virtual Network, Subnet, Public IP, NSG, NIC
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "myPublicIpAddress"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "myNic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  network_security_group_id = azurerm_network_security_group.nsg.id
}

###############################
# Windows Virtual Machine with Key Vault Certificate Secret
###############################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS2_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_updates  = true

    secrets {
      source_vault_id = azurerm_key_vault.kv.id

      vault_certificates {
        certificate_url   = azurerm_key_vault_certificate.cert.certificate_url
        certificate_store = "My"
      }
    }
  }
}

###############################
# VM Extension: Install IIS via Custom Script
###############################
resource "azurerm_virtual_machine_extension" "install_iis" {
  name                 = "IISInstall"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"
  location             = azurerm_windows_virtual_machine.vm.location

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature Web-Server -IncludeManagementTools\""
  })
}

###############################
# VM Extension: Configure IIS to use the certificate
###############################
resource "azurerm_virtual_machine_extension" "configure_iis" {
  name                 = "ConfigureIIS"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"
  location             = azurerm_windows_virtual_machine.vm.location

  settings = jsonencode({
    fileUris         = ["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/secure-iis.ps1"],
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File secure-iis.ps1"
  })
}

###############################
# Output the Public IP Address
###############################
output "public_ip" {
  description = "The public IP address of the secure web app"
  value       = azurerm_public_ip.pip.ip_address
}
