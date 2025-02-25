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

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Virtual Network 1 and Subnet
###############################
resource "azurerm_virtual_network" "vnet1" {
  name                = "myVirtualNetwork1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "Subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
}

###############################
# Virtual Network 2 and Subnet
###############################
resource "azurerm_virtual_network" "vnet2" {
  name                = "myVirtualNetwork2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "Subnet1"  # Subnet name can be reused in a different VNet.
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.0.0/24"]
}

###############################
# Virtual Network Peering: VNet1 to VNet2
###############################
resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                          = "myVirtualNetwork1-myVirtualNetwork2"
  resource_group_name           = azurerm_resource_group.rg.name
  virtual_network_name          = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id     = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access  = true
}

###############################
# Virtual Network Peering: VNet2 to VNet1
###############################
resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                          = "myVirtualNetwork2-myVirtualNetwork1"
  resource_group_name           = azurerm_resource_group.rg.name
  virtual_network_name          = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id     = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access  = true
}

###############################
# Outputs
###############################
output "vnet1_peering" {
  description = "Peering from myVirtualNetwork1 to myVirtualNetwork2"
  value       = azurerm_virtual_network_peering.vnet1_to_vnet2.peering_state
}

output "vnet2_peering" {
  description = "Peering from myVirtualNetwork2 to myVirtualNetwork1"
  value       = azurerm_virtual_network_peering.vnet2_to_vnet1.peering_state
}
