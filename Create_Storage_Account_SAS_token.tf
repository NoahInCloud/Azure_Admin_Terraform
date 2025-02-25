terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "local" {}

###############################
# Variables
###############################
variable "location" {
  description = "Azure location for resources"
  default     = "westeurope"
}

variable "rg_name" {
  description = "Resource group name"
  default     = "twstoragedemo"
}

variable "storage_account_name" {
  description = "Storage account name (must be globally unique)"
  default     = "twstorage75"
}

variable "container_name" {
  description = "Name of the storage container"
  default     = "bilder"
}

variable "blob_name" {
  description = "Name of the blob to be uploaded"
  default     = "test.txt"
}

variable "sas_start" {
  description = "SAS token start time"
  # For example, you can use a fixed start time
  default     = "2021-01-01T00:00:00Z"
}

variable "sas_expiry" {
  description = "SAS token expiry time"
  # Adjust expiry as needed
  default     = "2030-01-01T00:00:00Z"
}

variable "sas_permissions" {
  description = "Permissions for the SAS token (r=read, w=write, d=delete)"
  default     = "rwd"
}

###############################
# Create a local file with current timestamp
###############################
resource "local_file" "test_file" {
  content  = timestamp()
  filename = "C:/Temp/test.txt"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
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
  container_access_type = "private"
}

###############################
# Generate a SAS Token for the container
###############################
data "azurerm_storage_container_sas" "container_sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  container_name    = azurerm_storage_container.container.name

  start       = var.sas_start
  expiry      = var.sas_expiry
  permissions = var.sas_permissions
}

###############################
# Upload the file as a blob
###############################
resource "azurerm_storage_blob" "blob" {
  name                   = var.blob_name
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = local_file.test_file.filename
}

###############################
# Outputs
###############################
output "storage_account_primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.storage.primary_connection_string
}

output "container_sas_token" {
  description = "SAS token for the container with permissions: ${var.sas_permissions}"
  value       = data.azurerm_storage_container_sas.container_sas.sas_token
}

output "blob_url" {
  description = "URL of the uploaded blob"
  value       = azurerm_storage_blob.blob.url
}
