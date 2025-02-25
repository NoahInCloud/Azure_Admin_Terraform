terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

###############################
# Providers and Subscription
###############################
provider "azurerm" {
  features {}
}

provider "azuread" {}

data "azurerm_subscription" "primary" {}

###############################
# Role Definitions Data Sources
###############################
data "azurerm_role_definition" "owner" {
  name  = "Owner"
  scope = data.azurerm_subscription.primary.id
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_subscription.primary.id
}

data "azurerm_role_definition" "vm_contributor" {
  name  = "Virtual Machine Contributor"
  scope = data.azurerm_subscription.primary.id
}

###############################
# Lookup Existing User (NoahinCloud)
###############################
data "azuread_user" "NoahinCloud" {
  user_principal_name = "Noah@example.io"
}

###############################
# Reference an Existing Resource Group
###############################
data "azurerm_resource_group" "tw_web_rg" {
  name = "tw-web-rg"
}

###############################
# Create a Role Assignment
###############################
resource "azurerm_role_assignment" "NoahinCloud_vm_contributor" {
  scope              = data.azurerm_resource_group.tw_web_rg.id
  role_definition_id = data.azurerm_role_definition.vm_contributor.id
  principal_id       = data.azuread_user.NoahinCloud.object_id
}

###############################
# Outputs (Simulating PowerShell “Get-AzRoleDefinition” & “Get-AzRoleAssignment”)
###############################
output "owner_role_definition" {
  description = "Details for the Owner role"
  value       = data.azurerm_role_definition.owner
}

output "contributor_role_permissions" {
  description = "Contributor role permissions (Actions and NotActions)"
  value       = data.azurerm_role_definition.contributor.permissions
}

output "vm_contributor_actions" {
  description = "Actions permitted by the Virtual Machine Contributor role"
  value       = data.azurerm_role_definition.vm_contributor.permissions[0].actions
}

output "NoahinCloud_role_assignment" {
  description = "The role assignment for Noah@example.io on resource group tw-web-rg"
  value       = azurerm_role_assignment.NoahinCloud_vm_contributor
}
