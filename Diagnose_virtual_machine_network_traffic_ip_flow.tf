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

###############################
# Variables and Random Suffix
###############################
variable "resource_group_name" {
  description = "Name of the resource group for the VM"
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "myVm"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"  # Replace with a secure password
}

# Generate a random string for public DNS name uniqueness
resource "random_string" "dns_suffix" {
  length  = 4
  upper   = false
  special = false
}

###############################
# Resource Group for VM
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
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
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
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  allocation_method        = "Static"
  sku                      = "Basic"
  idle_timeout_in_minutes  = 4
}

###############################
# Network Security Group with RDP Rule
###############################
resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
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
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

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
# Network Watcher Resource
###############################
# Create a separate resource group for Network Watcher if it doesn't exist
resource "azurerm_resource_group" "nw_rg" {
  name     = "NetworkWatcherRG"
  location = var.location
}

resource "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_westeurope"
  location            = var.location
  resource_group_name = azurerm_resource_group.nw_rg.name
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "network_watcher_id" {
  description = "The ID of the Network Watcher"
  value       = azurerm_network_watcher.nw.id
}
