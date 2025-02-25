terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
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
  default     = "tw-prod-rg"
}

variable "location" {
  description = "Azure region"
  default     = "westeurope"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "tw-prod-vnet"
}

variable "subnet_name" {
  description = "Name of the subnet"
  default     = "Production"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "dc01"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "domadmin"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "yourpassword"
}

variable "private_ip_address" {
  description = "Static private IP address to assign to the VM's NIC"
  default     = "10.10.3.4"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Virtual Network
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.10.0.0/16"]
}

###############################
# Subnet: Production
###############################
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.3.0/24"]
}

###############################
# Public IP
###############################
resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

###############################
# Network Interface (NIC)
###############################
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-NIC"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

###############################
# Windows Virtual Machine
###############################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
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
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent       = true
    enable_automatic_updates = true
  }
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the created VM"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "nic_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.nic.id
}

output "private_ip" {
  description = "The static private IP address assigned to the VM"
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}

output "public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}
