terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
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

###############################
# Variables and Random Suffix
###############################
variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "myResourceGroup"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "MyVM"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "NoahinCloud"
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

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Linux Virtual Machine (Ubuntu 18.04 LTS)
###############################
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2S_V3"
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
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

###############################
# Virtual Network and Subnet (required for the VM)
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

###############################
# Public IP Address and NSG for the VM
###############################
resource "azurerm_public_ip" "pip" {
  name                     = "myPublicIp"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  allocation_method        = "Static"
  sku                      = "Basic"
  idle_timeout_in_minutes  = 4
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
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
# Key Vault for Disk Encryption
###############################
resource "azurerm_key_vault" "kv" {
  name                = lower("${var.prefix}-key-vault-${random_integer.id.result}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Enable for disk encryption and deployment
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
}

data "azurerm_client_config" "current" {}

###############################
# VM Extension for Disk Encryption (Linux)
###############################
resource "azurerm_virtual_machine_extension" "disk_encryption" {
  name                 = "DiskEncryptionExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Security"
  type                 = "AzureDiskEncryptionForLinux"
  type_handler_version = "1.1"
  location             = azurerm_resource_group.rg.location

  settings = jsonencode({
    EncryptionOperation    = "EnableEncryption",
    KeyVaultURL            = azurerm_key_vault.kv.vault_uri,
    KeyVaultResourceId     = azurerm_key_vault.kv.id,
    SkipVmBackup           = true,
    VolumeType             = "All"
  })
}

###############################
# Outputs
###############################
output "key_vault_uri" {
  description = "The URI of the Key Vault used for disk encryption"
  value       = azurerm_key_vault.kv.vault_uri
}

output "vm_id" {
  description = "The ID of the encrypted virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}
