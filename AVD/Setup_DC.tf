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
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "ad-ds-rg"
}

variable "location" {
  description = "Azure region"
  default     = "westeurope"
}

variable "vm_name" {
  description = "Name of the VM"
  default     = "ad-ds-vm"
}

variable "admin_username" {
  description = "Admin username for the VM"
  default     = "Administrator"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "YourAdminPassword!"  # Replace with a secure password or manage securely.
}

variable "domain_name" {
  description = "The fully qualified domain name for the new forest"
  default     = "master.pri"
}

variable "netbios_name" {
  description = "The NetBIOS name for the new domain"
  default     = "MASTER"
}

variable "dsrm_password" {
  description = "Password for Directory Services Restore Mode"
  type        = string
  sensitive   = true
  default     = "yourpassword"  # Replace with a secure password.
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
  name                = "ad-ds-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "ad-ds-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

###############################
# Public IP and Network Interface
###############################
resource "azurerm_public_ip" "pip" {
  name                = "ad-ds-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "ad-ds-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
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
  size                = "Standard_DS2_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  computer_name       = var.vm_name

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
    sku       = "2016-Datacenter"  # Use "2016-Datacenter" to match your script; adjust as needed.
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent       = true
    enable_automatic_updates = true
  }
}

###############################
# Custom Script Extension to Install AD DS
###############################
resource "azurerm_virtual_machine_extension" "ad_ds" {
  name                 = "InstallADDS"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  location             = azurerm_windows_virtual_machine.vm.location

  settings = jsonencode({
    "fileUris"         = ["https://raw.githubusercontent.com/YourUser/YourRepo/main/install-ad-ds.ps1"],
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File install-ad-ds.ps1"
  })

  protected_settings = jsonencode({
    "domainName"   = var.domain_name,
    "netbiosName"  = var.netbios_name,
    "dsrmPassword" = var.dsrm_password
  })
}
