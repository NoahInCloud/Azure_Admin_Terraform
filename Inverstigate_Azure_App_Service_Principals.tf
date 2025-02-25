terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

# Reference the service principal for the application "twdemoapp"
data "azuread_service_principal" "twdemoapp" {
  display_name = "twdemoapp"
}

# Optionally, if you want to manage a specific app role assignment,
# declare a resource. For example, to assign a role to a user:
#
# resource "azuread_service_app_role_assignment" "example_assignment" {
#   service_principal_object_id = data.azuread_service_principal.twdemoapp.object_id
#   principal_object_id         = "USER_OBJECT_ID"
#   app_role_id                 = "ROLE_GUID"
# }
#
# To “remove” all assignments, simply do not include any assignment resources.
# Then, if you have imported assignments that you wish to remove, delete their configuration.
