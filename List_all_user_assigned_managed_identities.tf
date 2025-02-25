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
# Input: List of User-Assigned Identities to Manage
###############################
variable "user_assigned_identities" {
  description = "List of user-assigned identities to manage, with their names and resource group names."
  type = list(object({
    name              = string
    resource_group    = string
  }))
  default = [
    {
      name           = "identity1"
      resource_group = "rg-identity1"
    },
    {
      name           = "identity2"
      resource_group = "rg-identity2"
    }
  ]
}

###############################
# Import or Create the User-Assigned Identities
###############################
# In Terraform, you either manage these identities or import them.
# Here we assume you want Terraform to manage them.
resource "azurerm_user_assigned_identity" "uas" {
  for_each = { for u in var.user_assigned_identities : u.name => u }

  name                = each.value.name
  resource_group_name = each.value.resource_group
  location            = "westeurope"
}

###############################
# Role Assignment for Each Identity
###############################
# For example, assign the Contributor role to each identity.
variable "subscription_id" {
  description = "The subscription ID."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"  # Replace with your subscription ID
}

variable "role_definition_id" {
  description = "The role definition ID to assign (Contributor role in this example)."
  type        = string
  default     = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor role
}

resource "azurerm_role_assignment" "assign_identity" {
  for_each = azurerm_user_assigned_identity.uas

  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = var.role_definition_id
  principal_id       = each.value.principal_id
}

###############################
# Outputs: Report the Managed Identities and Their Role Assignment Details
###############################
output "user_assigned_identity_info" {
  description = "Mapping of user-assigned identities to their role assignments."
  value = {
    for name, iden in azurerm_user_assigned_identity.uas :
    name => {
      resource_group = iden.resource_group_name
      location       = iden.location
      principal_id   = iden.principal_id
    }
  }
}

output "role_assignment_info" {
  description = "Details of the role assignments for each user-assigned identity."
  value = {
    for name, assignment in azurerm_role_assignment.assign_identity :
    name => {
      principal_id       = assignment.principal_id
      role_definition_id = assignment.role_definition_id
      scope              = assignment.scope
    }
  }
}
