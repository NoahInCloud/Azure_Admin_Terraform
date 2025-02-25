provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group" {
  description = "Name of the resource group"
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region"
  default     = "westeurope"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

###############################
# Storage Account
###############################
resource "azurerm_storage_account" "storage" {
  name                     = "twstorageazure"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

###############################
# Blob Container
###############################
resource "azurerm_storage_container" "container" {
  name                  = "quickstartblobs"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

###############################
# Storage Blobs (Upload Files)
###############################
resource "azurerm_storage_blob" "mustang_blob" {
  name                   = "Mustang_1.JPG"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "C:/azure_bilder/Mustang_1.JPG"
}

resource "azurerm_storage_blob" "trackhawk_blob" {
  name                   = "Trackhawk_2.jpg"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "C:/azure_bilder/Trackhawk_2.jpg"
}

###############################
# Outputs
###############################
output "mustang_blob_url" {
  description = "URL for the Mustang blob"
  value       = azurerm_storage_blob.mustang_blob.url
}

output "trackhawk_blob_url" {
  description = "URL for the Trackhawk blob"
  value       = azurerm_storage_blob.trackhawk_blob.url
}
