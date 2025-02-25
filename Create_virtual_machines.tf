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
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group"
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
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!!"  # Replace with a secure password or supply via a secrets manager.
}

###############################
# Random Suffix for Public DNS Name
###############################
resource "random_string" "dns_suffix" {
  length  = 4
  special = false
  upper   = false
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Virtual Network and Subnet
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = "MYvNET"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

###############################
# Public IP Address with Random DNS Name
###############################
resource "azurerm_public_ip" "pip" {
  name                     = "mypublicdns${random_string.dns_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  allocation_method        = "Static"
  sku                      = "Basic"
  idle_timeout_in_minutes  = 4
}

###############################
# Network Security Group with RDP Rule
###############################
resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  security_rule {
    name                       = "myNetworkSecurityGroupRuleRDP"
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
  location            = var.location

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
  location            = var.location
  size                = "Standard_DS1_v2"
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
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}
