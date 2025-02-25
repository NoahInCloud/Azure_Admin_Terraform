provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

resource "random_uuid" "custom_role_id" {}

resource "azurerm_role_definition" "virtual_machine_starter" {
  name               = random_uuid.custom_role_id.result
  role_definition_id = random_uuid.custom_role_id.result
  role_name          = "Virtual Machine Starter"
  scope              = data.azurerm_subscription.primary.id
  description        = "Provides the ability to start a virtual machine."

  permissions {
    actions = [
      "Microsoft.Storage/*/read",
      "Microsoft.Network/*/read",
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Authorization/*/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Insights/alertRules/*"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}
