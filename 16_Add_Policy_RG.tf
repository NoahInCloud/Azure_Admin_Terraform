provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "The name of the resource group where the policy will be assigned."
  default     = "tw-web-rg"
}

# Replace with the built-in policy definition ID for "Audit VMs that do not use managed disks"
variable "policy_definition_id" {
  description = "The built-in policy definition ID for auditing VMs that do not use managed disks."
  # Example value (update this value with the correct one for your tenant)
  default     = "/providers/Microsoft.Authorization/policyDefinitions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

###############################
# Data Sources
###############################
# Reference the existing resource group
data "azurerm_resource_group" "tw_web_rg" {
  name = var.resource_group_name
}

###############################
# Policy Assignment
###############################
resource "azurerm_policy_assignment" "audit_vm_manageddisks" {
  name                 = "audit-vm-manageddisks"
  display_name         = "Audit VMs without managed disks Assignment"
  scope                = data.azurerm_resource_group.tw_web_rg.id
  policy_definition_id = var.policy_definition_id
}

###############################
# Outputs (optional)
###############################
output "policy_assignment_id" {
  description = "The ID of the policy assignment."
  value       = azurerm_policy_assignment.audit_vm_manageddisks.id
}
