provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "The name of the resource group."
  default     = "tw-rg01"
}

variable "location" {
  description = "The Azure region."
  default     = "westeurope"
}

variable "vm_name" {
  description = "The name of the virtual machine."
  default     = "tw-win2019"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Virtual Network and Subnet (required for the VM)
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

###############################
# Network Interface
###############################
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

###############################
# Windows Virtual Machine
###############################
resource "azurerm_windows_virtual_machine" "winvm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"  # Use a secure method to manage passwords in production

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
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  # The VM is created in a running state by default.
}

###############################
# Outputs
###############################
output "vm_id" {
  description = "The ID of the virtual machine."
  value       = azurerm_windows_virtual_machine.winvm.id
}
