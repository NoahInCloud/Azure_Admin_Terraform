terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.29.0"  # Use an appropriate version
    }
  }
}

provider "azuread" {}

# Data source to fetch an existing user by Object ID
data "azuread_user" "example" {
  object_id = "157a6f3f-52f2-4fee-af64-dbca2db07926"
}

# Manage the user license assignment.
# Note: If the user is already created outside Terraform,
# you can import the user or use a data source to reference it.
resource "azuread_user" "managed_user" {
  # These attributes are populated from the existing user.
  user_principal_name = data.azuread_user.example.user_principal_name
  display_name        = data.azuread_user.example.display_name
  mail_nickname       = data.azuread_user.example.mail_nickname
  usage_location      = "CH"

  # Declare the desired license assignments.
  # Replace the SKU ID with one from your subscribed SKUs.
  assigned_licenses {
    sku_id = "06ebc4ee-1bb5-47dd-8120-11324bc54e06"
  }
}

output "assigned_licenses" {
  description = "The list of licenses assigned to the user"
  value       = azuread_user.managed_user.assigned_licenses
}
