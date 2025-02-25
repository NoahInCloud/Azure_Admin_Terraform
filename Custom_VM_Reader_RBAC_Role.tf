terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
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

provider "azuread" {}

###############################
# Variables and Random ID
###############################
variable "subscription_id" {
  description = "The subscription ID where the role will be created and assigned."
  default     = "cff58289-560f-42b2-9bb6-b532d52b928c"
}

variable "target_user_upn" {
  description = "User principal name of the target user to receive the custom role"
  default     = "Noah@example.io"
}

# Generate a random GUID to use as the custom role's ID.
resource "random_uuid" "vm_reader_role_id" {}

###############################
# Create the Custom Role: VM Reader
###############################
resource "azurerm_role_definition" "vm_reader" {
  # The role_definition_id must be a GUID; we generate one.
  role_definition_id = random_uuid.vm_reader_role_id.result

  # The scope for the custom role is the subscription.
  scope = "/subscriptions/${var.subscription_id}"

  # Display name and description.
  name        = "VM Reader"
  description = "Can see VMs"

  permissions {
    actions = [
      "Microsoft.Storage/*/read",
      "Microsoft.Network/*/read",
      "Microsoft.Compute/*/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}"
  ]
}

###############################
# Look Up the Target User in Azure AD
###############################
data "azuread_user" "target" {
  user_principal_name = var.target_user_upn
}

###############################
# Assign the Custom Role to the Target User
###############################
resource "azurerm_role_assignment" "assign_vm_reader" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = azurerm_role_definition.vm_reader.role_definition_id
  principal_id       = data.azuread_user.target.object_id
}

###############################
# Outputs
###############################
output "vm_reader_role_id" {
  description = "The ID of the custom VM Reader role"
  value       = azurerm_role_definition.vm_reader.role_definition_id
}

output "assigned_user_object_id" {
  description = "The object ID of the user assigned the VM Reader role"
  value       = data.azuread_user.target.object_id
}
