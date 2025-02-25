provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "The name of the resource group to create."
}

variable "location" {
  description = "The Azure location (e.g., centralus, westeurope)."
}

variable "storage_account_name" {
  description = "The name of the storage account to create. Must be globally unique."
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Storage Account
###############################
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  kind                     = "StorageV2"
}

###############################
# Outputs (optional)
###############################
output "storage_account_connection_string" {
  description = "The connection string for the storage account."
  value       = azurerm_storage_account.storage.primary_connection_string
}
