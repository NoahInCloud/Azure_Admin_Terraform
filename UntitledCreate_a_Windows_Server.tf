provider "azurerm" {
  features {}
}

#####################
# Variables
#####################
variable "resource_group" {
  description = "The name of the resource group"
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "vm_name" {
  description = "The name of the virtual machine"
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
}

#####################
# Random Suffix for DNS Name
#####################
resource "random_integer" "dns_suffix" {
  min = 1000
  max = 9999
}

#####################
# Resource Group
#####################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

#####################
# Virtual Network and Subnet
#####################
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

#####################
# Public IP Address with DNS Name
#####################
resource "azurerm_public_ip" "pip" {
  name                = "mypublicdns${random_integer.dns_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  idle_timeout_in_minutes = 4
  sku                 = "Basic"

  dns_settings {
    domain_name_label = "mypublicdns${random_integer.dns_suffix.result}"
  }
}

#####################
# Network Security Group with RDP Rule
#####################
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

#####################
# Network Interface
#####################
resource "azurerm_network_interface" "nic" {
  name                = "myNic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  network_security_group_id = azurerm_network_security_group.nsg.id
}

#####################
# Windows Virtual Machine
#####################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_D2s_v3"
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
