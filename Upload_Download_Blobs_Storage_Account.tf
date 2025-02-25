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
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique and lowercase)"
  default     = "tw75mystorageaccount"
}

variable "container_name" {
  description = "Name of the storage container"
  default     = "quickstartblobs"
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
  account_replication_type = "LRS"
  kind                     = "StorageV2"
}

###############################
# Storage Container
###############################
resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

###############################
# Upload Blobs
###############################
resource "azurerm_storage_blob" "img1" {
  name                   = "IMG_0498.jpg"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "C:/Users/admin/Desktop/Bilder/IMG_0498.jpg"
}

resource "azurerm_storage_blob" "img2" {
  name                   = "IMG_0406.jpg"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "C:/Users/admin/Desktop/Bilder/IMG_0406.jpg"
}

###############################
# Outputs
###############################
output "blob_names" {
  description = "Names of the blobs uploaded to the container"
  value       = [
    azurerm_storage_blob.img1.name,
    azurerm_storage_blob.img2.name
  ]
}
