terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

# Retrieve a specific directory role by display name
data "azuread_directory_role" "global_admin" {
  display_name = "Global Administrator"
}

# Retrieve the members of that directory role
data "azuread_directory_role_members" "global_admin_members" {
  role_object_id = data.azuread_directory_role.global_admin.id
}

output "global_admin_members" {
  description = "List of members in the Global Administrator role"
  value       = data.azuread_directory_role_members.global_admin_members.members
}
