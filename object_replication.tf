provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "rg_name" {
  description = "Resource group name"
  default     = "ctt-prod-sta-rg"
}

variable "src_account_name" {
  description = "Name of the source storage account"
  default     = "cttprodsta2025"
}

variable "dest_account_name" {
  description = "Name of the destination storage account"
  default     = "cttsta4625"
}

variable "src_container_name1" {
  description = "Name of the first source container"
  default     = "source-container1"
}

variable "dest_container_name1" {
  description = "Name of the first destination container"
  default     = "dest-container1"
}

variable "src_container_name2" {
  description = "Name of the second source container"
  default     = "source-container2"
}

variable "dest_container_name2" {
  description = "Name of the second destination container"
  default     = "dest-container2"
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = "westeurope"
}

###############################
# Source Storage Account
###############################
resource "azurerm_storage_account" "src" {
  name                     = var.src_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"

  enable_blob_versioning = true
  enable_change_feed     = true
}

###############################
# Destination Storage Account
###############################
resource "azurerm_storage_account" "dest" {
  name                     = var.dest_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"

  enable_blob_versioning = true
}

###############################
# Containers in Source and Destination
###############################
resource "azurerm_storage_container" "src_container1" {
  name                 = var.src_container_name1
  storage_account_name = azurerm_storage_account.src.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "src_container2" {
  name                 = var.src_container_name2
  storage_account_name = azurerm_storage_account.src.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "dest_container1" {
  name                 = var.dest_container_name1
  storage_account_name = azurerm_storage_account.dest.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "dest_container2" {
  name                 = var.dest_container_name2
  storage_account_name = azurerm_storage_account.dest.name
  container_access_type = "private"
}

###############################
# Object Replication Policy
###############################
resource "azurerm_storage_object_replication_policy" "replication_policy" {
  # This resource is created on the destination storage account.
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_name = azurerm_storage_account.dest.name

  # Reference the source storage account by its resource ID.
  source_storage_account_id = azurerm_storage_account.src.id

  rule {
    name                  = "rule1"
    source_container      = azurerm_storage_container.src_container1.name
    destination_container = azurerm_storage_container.dest_container1.name
    prefix_match          = ["b"]
  }

  rule {
    name                  = "rule2"
    source_container      = azurerm_storage_container.src_container2.name
    destination_container = azurerm_storage_container.dest_container2.name
    prefix_match          = ["b", "abc", "dd"]
  }
}

###############################
# Outputs (Optional)
###############################
output "replication_policy_id" {
  description = "The ID of the storage object replication policy"
  value       = azurerm_storage_object_replication_policy.replication_policy.id
}
