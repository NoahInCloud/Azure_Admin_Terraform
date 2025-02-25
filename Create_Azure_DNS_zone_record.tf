provider "azurerm" {
  features {}
}

###############################
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "MyResourceGroup"
}

variable "location" {
  description = "Azure region for resources"
  default     = "westeurope"
}

variable "dns_zone_name" {
  description = "DNS zone name"
  default     = "Noah@example.io"
}

variable "dns_record_name" {
  description = "DNS record name"
  default     = "www"
}

variable "ipv4_address" {
  description = "IPv4 address for the A record"
  default     = "10.10.10.10"
}

variable "ttl" {
  description = "Time-to-live for the DNS record"
  default     = 3600
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# DNS Zone
###############################
resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

###############################
# DNS A Record
###############################
resource "azurerm_dns_a_record" "a_record" {
  name                = var.dns_record_name
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = var.ttl
  records             = [var.ipv4_address]
}

###############################
# Outputs
###############################
output "dns_zone_name_servers" {
  description = "The name servers for the DNS zone."
  value       = azurerm_dns_zone.dns_zone.name_servers
}
