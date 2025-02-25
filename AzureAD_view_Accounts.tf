terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

###############################
# Retrieve a Specific User
###############################
data "azuread_user" "jane_ford" {
  # Use the user principal name; alternatively, you can specify the object_id.
  user_principal_name = "jane.Noah@example.io"
}

###############################
# Outputs (simulate "Select *" or specific property selection)
###############################
output "jane_ford_all_properties" {
  description = "All available properties for jane.Noah@example.io"
  value       = data.azuread_user.jane_ford
}

output "jane_ford_selected_properties" {
  description = "Selected properties for jane.Noah@example.io"
  value = {
    display_name      = data.azuread_user.jane_ford.display_name
    department        = data.azuread_user.jane_ford.department
    usage_location    = data.azuread_user.jane_ford.usage_location
    account_enabled   = data.azuread_user.jane_ford.account_enabled
  }
}
