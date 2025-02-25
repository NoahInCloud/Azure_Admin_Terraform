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
# Variables and Random ID
###############################
variable "prefix" {
  description = "Prefix for resource names"
  default     = "tw"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

resource "random_integer" "id" {
  min = 1000
  max = 9999
}

locals {
  resource_group_name  = "${var.prefix}-rg-${random_integer.id.result}"
  # Storage account names must be lowercase and unique
  storage_account_name = lower("${var.prefix}sa${random_integer.id.result}")
}

###############################
# Create Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

###############################
# Create a General-Purpose v2 Storage Account
###############################
resource "azurerm_storage_account" "storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"  # Read-access geo-redundant storage
  kind                     = "StorageV2"
}

###############################
# Outputs
###############################
output "resource_group_name" {
  description = "The name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "The name of the created storage account."
  value       = azurerm_storage_account.storage.name
}
