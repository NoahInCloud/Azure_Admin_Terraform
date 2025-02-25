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

# Create a management group named "TomRocks"
# (Initially you might have set the display name to "TomRocks Group"; here we declare it as "Wechsler Group" to represent an update.)
resource "azurerm_management_group" "tomrocks" {
  group_id     = "TomRocks"
  display_name = "Wechsler Group"
}

# Create a child management group under "TomRocks"
resource "azurerm_management_group" "tomrockssubgroup" {
  group_id                   = "TomRocksSubGroup"
  display_name               = "TomRocksSubGroup"
  parent_management_group_id = azurerm_management_group.tomrocks.id
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
