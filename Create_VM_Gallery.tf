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
variable "resource_group" {
  description = "Resource group for the VM"
  default     = "myVMfromImage"
}

variable "location" {
  description = "Azure region for resources"
  default     = "WestEurope"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "myVMfromImage"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"  # Replace with a secure value or use a secrets manager.
}

###############################
# Data Source: Latest Shared Image Version
###############################
data "azurerm_shared_image_version" "latest" {
  resource_group_name       = "elme-SIG-rg"
  shared_image_gallery_name = "elmesig2021"
  shared_image_name         = "Win10Multi20H2"
  name                      = "latest"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

###############################
# Virtual Network and Subnet
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = "MYvNET"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

###############################
# Public IP with Random Suffix
###############################
resource "random_string" "public_ip_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_public_ip" "public_ip" {
  name                     = "mypublicdns${random_string.public_ip_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
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
  location            = azurerm_resource_group.rg.location

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
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
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
  size                = "Standard_D1_v2"
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
    shared_image_id = data.azurerm_shared_image_version.latest.id
  }
}
