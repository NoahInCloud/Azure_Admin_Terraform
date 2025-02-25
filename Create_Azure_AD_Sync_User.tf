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
variable "user_name" {
  description = "The username to create (without the domain part)"
  default     = "aadsyncuser"
}

variable "password" {
  description = "The password for the new user"
  default     = "Pa55w.rd1234"
  sensitive   = true
}

variable "domain_name" {
  description = "The Azure AD domain name (verified domain)"
  default     = "63k57q.onmicrosoft.com"
}

###############################
# Create the Azure AD User
###############################
resource "azuread_user" "new_user" {
  user_principal_name   = "${var.user_name}@${var.domain_name}"
  display_name          = var.user_name
  mail_nickname         = var.user_name
  password              = var.password
  force_password_change = false
  account_enabled       = true
}

###############################
# Look Up the Global Administrator Role
###############################
data "azuread_directory_role" "global_admin" {
  display_name = "Global administrator"
}

###############################
# Assign the Global Administrator Role to the New User
###############################
resource "azuread_directory_role_member" "assign_global_admin" {
  group_object_id  = data.azuread_directory_role.global_admin.id
  member_object_id = azuread_user.new_user.object_id
}

###############################
# Outputs (Optional)
###############################
output "new_user_object_id" {
  description = "The object ID of the newly created Azure AD user"
  value       = azuread_user.new_user.object_id
}

output "global_admin_role_id" {
  description = "The ID of the Global administrator role"
  value       = data.azuread_directory_role.global_admin.id
}
