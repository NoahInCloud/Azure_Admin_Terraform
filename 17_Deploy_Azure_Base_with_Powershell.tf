provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Enter the Resource Group name"
  type        = string
}

variable "location" {
  description = "Enter the location (e.g. centralus, westeurope)"
  type        = string
}

###############################
# Create the Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Fetch the ARM Template from GitHub
###############################
data "http" "arm_template" {
  url = "https://raw.githubusercontent.com/tomwechsler/arm_templates/master/base-azure.json"
}

###############################
# Deploy the ARM Template to the Resource Group
###############################
resource "azurerm_template_deployment" "base_deployment" {
  name                = "base-azure-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_body = data.http.arm_template.body

  # If your template requires parameters, add them as a map:
  # parameters = {
  #   parameterName = { value = "your-value" }
  # }
}

###############################
# (Optional) Outputs
###############################
output "resource_group_id" {
  description = "The ID of the created resource group"
  value       = azurerm_resource_group.rg.id
}
