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
# Variables
###############################
variable "domain" {
  description = "The domain used for the user principal name"
  default     = "wechsler.onmicrosoft.com"
}

variable "user_password" {
  description = "The password to assign to all users"
  default     = "agxsFX72xwsSAi"
  sensitive   = true
}

###############################
# Read CSV Data
###############################
# The CSV file should be placed in the same directory as this configuration.
data "local_file" "fake_users" {
  filename = "Fake_User_data.csv"
}

# Convert CSV content into a list of maps.
locals {
  users = csvdecode(data.local_file.fake_users.content)
}

###############################
# Create Azure AD Users
###############################
resource "azuread_user" "users" {
  # Use each user's Username as the unique key.
  for_each = { for user in local.users : user.Username => user }

  user_principal_name   = "${each.value.Username}@${var.domain}"
  display_name          = "${each.value.GivenName} ${each.value.Surname}"
  mail_nickname         = each.value.Username
  password              = var.user_password
  force_password_change = false
  account_enabled       = true

  given_name       = each.value.GivenName
  surname          = each.value.Surname
  job_title        = each.value.Occupation
  department       = each.value.Department
  city             = each.value.City
  state            = each.value.State
  country          = each.value.Country
  postal_code      = each.value.ZipCode
  street_address   = each.value.StreetAddress
  telephone_number = each.value.TelephoneNumber
}

###############################
# Outputs (optional)
###############################
output "created_user_ids" {
  description = "The object IDs of the created Azure AD users"
  value       = { for key, user in azuread_user.users : key => user.object_id }
}
