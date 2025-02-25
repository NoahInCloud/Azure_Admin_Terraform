terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {}
}

###############################
# Retrieve a Specific Directory Role
###############################
# Replace the object_id below with your role's object ID.
data "azuread_directory_role" "example_role" {
  object_id = "5b3fe201-fa8b-4144-b6f1-875829ff7543"
}

###############################
# Retrieve Members of the Directory Role
###############################
data "azuread_directory_role_members" "role_members" {
  role_object_id = data.azuread_directory_role.example_role.object_id
}

###############################
# Output the Role and its Members
###############################
output "directory_role_info" {
  description = "Details of the directory role and its members"
  value = {
    RoleDisplayName = data.azuread_directory_role.example_role.display_name
    RoleObjectId    = data.azuread_directory_role.example_role.object_id
    Members         = data.azuread_directory_role_members.role_members.members
  }
}
