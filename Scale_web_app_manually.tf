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
# Generate Random Suffix (8 hex characters)
###############################
resource "random_id" "rand_suffix" {
  byte_length = 4
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup${random_id.rand_suffix.hex}"
  location = "westeurope"
}

###############################
# App Service Plan
###############################
resource "azurerm_app_service_plan" "asp" {
  name                = "AppServiceManualScalePlan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Basic"
    size = "B1"
  }

  # Scale the App Service Plan to 2 workers.
  number_of_workers = 2
}

###############################
# Web App
###############################
resource "azurerm_web_app" "web" {
  name                = "AppServiceManualScale${random_id.rand_suffix.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id
}

###############################
# Outputs
###############################
output "resource_group_name" {
  description = "The name of the resource group."
  value       = azurerm_resource_group.rg.name
}

output "app_service_plan_id" {
  description = "The ID of the App Service Plan."
  value       = azurerm_app_service_plan.asp.id
}

output "web_app_url" {
  description = "The default URL of the Web App."
  value       = azurerm_web_app.web.default_site_hostname
}
