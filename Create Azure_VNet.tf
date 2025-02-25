provider "azurerm" {
  features {}
  subscription_id = "83bedf1c-859c-471d-831a-fae20a378f44"
}

#####################
# Variables
#####################
variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  default     = "myVirtualNetwork"
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "default"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the Windows VMs"
  type        = string
  sensitive   = true
}

#####################
# Resource Group
#####################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#####################
# Virtual Network and Subnet
#####################
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

#####################
# Public IP Addresses
#####################
resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "myVm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_public_ip" "vm2_public_ip" {
  name                = "myVm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

#####################
# Network Interfaces
#####################
resource "azurerm_network_interface" "nic_vm1" {
  name                = "myVm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
  }
}

resource "azurerm_network_interface" "nic_vm2" {
  name                = "myVm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2_public_ip.id
  }
}

#####################
# Windows Virtual Machines
#####################
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "myVm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id
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

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "myVm2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic_vm2.id
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

#####################
# Outputs
#####################
output "vm1_public_ip" {
  description = "Public IP address of myVm1"
  value       = azurerm_public_ip.vm1_public_ip.ip_address
}

output "vm2_public_ip" {
  description = "Public IP address of myVm2"
  value       = azurerm_public_ip.vm2_public_ip.ip_address
}
