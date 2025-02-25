terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Resource group for the VM and Key Vault"
  default     = "myResourceGroup"
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
  default     = "sysadmin"
}

variable "admin_password" {
  description = "Admin password for the VM (will be stored in Key Vault)"
  type        = string
  sensitive   = true
  default     = "hVFkk965BuUv"
}

variable "key_vault_user_upn" {
  description = "User Principal Name to grant Key Vault permissions"
  default     = "user@domain.com"
}

###############################
# Data Sources
###############################
data "azurerm_client_config" "current" {}

data "azuread_user" "key_vault_user" {
  user_principal_name = var.key_vault_user_upn
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Azure Key Vault
###############################
resource "azurerm_key_vault" "kv" {
  name                = "tw-vault2020"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id         = data.azurerm_client_config.current.tenant_id
    object_id         = data.azuread_user.key_vault_user.object_id
    secret_permissions = ["get", "set", "delete"]
  }
}

###############################
# Key Vault Secret
###############################
resource "azurerm_key_vault_secret" "sysadmin_secret" {
  name         = "SysadminSecret"
  value        = var.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

###############################
# Virtual Network and Subnet
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

###############################
# Public IP and NSG
###############################
resource "azurerm_public_ip" "pip" {
  name                     = "myPublicIp"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  allocation_method        = "Static"
  sku                      = "Basic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-SG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

###############################
# Network Interface
###############################
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
# Windows Virtual Machine
###############################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = azurerm_key_vault_secret.sysadmin_secret.value
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
}

###############################
# Outputs
###############################
output "key_vault_secret_value" {
  description = "The secret value stored in Key Vault (sensitive)"
  value       = azurerm_key_vault_secret.sysadmin_secret.value
  sensitive   = true
}

output "vm_id" {
  description = "The ID of the created virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}
