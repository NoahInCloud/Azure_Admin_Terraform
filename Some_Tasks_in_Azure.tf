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

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "westeurope"
}

# Create a DNS Zone
resource "azurerm_dns_zone" "zone" {
  name                = "exampledomain.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a DNS A Record
resource "azurerm_dns_a_record" "a_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  records             = ["10.10.10.10"]
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.zone.name_servers
}
