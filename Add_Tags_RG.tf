provider "azurerm" {
  features {}
}

###############################
# Resource Group with Tags
###############################
resource "azurerm_resource_group" "rg" {
  name     = "tw-rg01"
  location = "westeurope"
  tags = {
    costcenter = "1987"
    ManagedBy  = "Bob"
    Status     = "Approved"
  }
}

###############################
# Sample Resource: Windows Virtual Machine with Tags
###############################
resource "azurerm_windows_virtual_machine" "winsrv" {
  name                = "tw-winsrv"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"  # Use a secure method in production!
  
  network_interface_ids = []  # In a complete configuration, define a NIC resource and reference its ID here.

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
  
  tags = {
    Dept        = "IT"
    Environment = "Test"
    Status      = "Approved"
  }
}

###############################
# Outputs (Optional)
###############################
output "resource_group_tags" {
  description = "Tags applied to the resource group"
  value       = azurerm_resource_group.rg.tags
}

output "winsrv_tags" {
  description = "Tags applied to the tw-winsrv resource"
  value       = azurerm_windows_virtual_machine.winsrv.tags
}
