terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################
# Management Group Resources
###############################

# Create a management group named "Contoso"
resource "azurerm_management_group" "contoso" {
  group_id     = "Contoso"
  display_name = "Contoso"
}

# Create a management group named "NoahinCloud"
# (Initially you might have set the display name to "NoahinCloud Group"; here we declare it as "Wechsler Group" to represent an update.)
resource "azurerm_management_group" "NoahinCloud" {
  group_id     = "NoahinCloud"
  display_name = "Wechsler Group"
}

# Create a child management group under "NoahinCloud"
resource "azurerm_management_group" "NoahinCloudsubgroup" {
  group_id                   = "NoahinCloudSubGroup"
  display_name               = "NoahinCloudSubGroup"
  parent_management_group_id = azurerm_management_group.NoahinCloud.id
}

###############################
# Data Source Example
###############################
# Retrieve the "Contoso" management group details.
data "azurerm_management_group" "contoso_data" {
  group_id = "Contoso"
}

# (Optional) Retrieve a management group and its hierarchy.
# Note: The expand and recurse arguments may be supported in newer provider versions.
data "azurerm_management_group" "testgroupparent" {
  group_id = "TestGroupParent"
  # expand  = true
  # recurse = true
}

###############################
# Outputs
###############################
output "contoso_management_group_details" {
  description = "Details for the Contoso management group"
  value       = data.azurerm_management_group.contoso_data
}

output "testgroupparent_hierarchy" {
  description = "The TestGroupParent management group and its hierarchy (if available)"
  value       = data.azurerm_management_group.testgroupparent
}
