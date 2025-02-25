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
# Create the "Fred Group"
###############################
resource "azuread_group" "fred_group" {
  display_name     = "Fred Group"
  mail_enabled     = false
  security_enabled = true
  mail_nickname    = "FredGroup"
  description      = "Group for Fred to use."
}

###############################
# Lookup an existing user "Fred Prefect"
###############################
data "azuread_user" "fred_prefect" {
  # Adjust the user principal name as needed.
  user_principal_name = "frPrefect@wechsler.onmicrosoft.com"
}

###############################
# Set "Fred Prefect" as owner of Fred Group
###############################
resource "azuread_group_owner" "fred_group_owner" {
  group_object_id = azuread_group.fred_group.id
  owner_object_id = data.azuread_user.fred_prefect.object_id
}

###############################
# Add additional members to Fred Group
###############################
variable "so_user_ids" {
  type        = list(string)
  description = "List of Azure AD user object IDs where State equals 'SO'"
  # Supply the object IDs of users who meet the filter.
  default     = []
}

resource "azuread_group_member" "fred_group_members" {
  for_each        = toset(var.so_user_ids)
  group_object_id = azuread_group.fred_group.id
  member_object_id = each.value
}

###############################
# Create a Dynamic Group: "Marketing Group"
###############################
resource "azuread_group" "marketing_group" {
  display_name                   = "Marketing Group"
  mail_enabled                   = false
  security_enabled               = true
  mail_nickname                  = "MarketingGroup"
  description                    = "Dynamic group for Marketing"
  group_types                    = ["DynamicMembership"]
  dynamic_membership_rule        = "(user.department -contains \"Marketing\")"
  membership_rule_processing_state = "On"
}

###############################
# Outputs
###############################
output "fred_group_id" {
  description = "The object ID of the Fred Group"
  value       = azuread_group.fred_group.id
}

output "marketing_group_id" {
  description = "The object ID of the Marketing Group"
  value       = azuread_group.marketing_group.id
}
