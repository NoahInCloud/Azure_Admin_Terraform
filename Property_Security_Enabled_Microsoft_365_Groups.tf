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
# Create a Dynamic Group
###############################
resource "azuread_group" "dynamic_group_01" {
  display_name                     = "Dynamic Group 01"
  description                      = "Dynamic group created from PS"
  mail_enabled                     = false
  mail_nickname                    = "group"
  security_enabled                 = true
  group_types                      = ["DynamicMembership"]
  membership_rule                  = "(user.department -contains \"Marketing\")"
  membership_rule_processing_state = "On"
}

###############################
# Manage an Existing Group
###############################
# To update an existing group (e.g. changing its SecurityEnabled property), import it into Terraform.
# For example, to manage the group with object ID "a8269c21-1059-4bb1-8937-7f2d6a6f6b92", run:
#
#    terraform import azuread_group.existing_group a8269c21-1059-4bb1-8937-7f2d6a6f6b92
#
resource "azuread_group" "existing_group" {
  # The resource's ID will be set by the import.
  # Declare the desired property values. For example, ensure SecurityEnabled is true.
  security_enabled = true

  # Other properties (like display_name) are computed if not explicitly set.
}
