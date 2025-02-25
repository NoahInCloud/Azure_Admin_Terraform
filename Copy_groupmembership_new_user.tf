provider "azuread" {}

# Look up the source and target users by UPN
data "azuread_user" "source" {
  user_principal_name = "AdeleV@63k57q.onmicrosoft.com"
}

data "azuread_user" "target" {
  user_principal_name = "LeeG@63k57q.onmicrosoft.com"
}

# Provide a list of group IDs where the source user is a member.
# (Terraform does not natively query this; you must supply it or generate it externally.)
variable "source_group_ids" {
  description = "List of group IDs that the source user is a member of"
  type        = list(string)
  default     = [
    "group-id-1",
    "group-id-2",
    "group-id-3"
  ]
}

# For each group in the provided list, ensure the target user is a member.
resource "azuread_group_member" "target_membership" {
  for_each         = toset(var.source_group_ids)
  group_object_id  = each.value
  member_object_id = data.azuread_user.target.object_id
}
