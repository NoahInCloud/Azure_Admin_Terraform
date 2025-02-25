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
# Variables
###############################
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "tw-prod-rg"
}

variable "location" {
  description = "Azure region"
  default     = "West Europe"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "tw-prod-vnet"
}

variable "address_space" {
  description = "Address space for the virtual network"
  default     = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "List of subnets with name and address prefix"
  type = list(object({
    name           = string
    address_prefix = string
  }))
  default = [
    {
      name           = "AzureBastionSubnet"
      address_prefix = "10.10.0.0/26"
    },
    {
      name           = "AzureFirewallSubnet"
      address_prefix = "10.10.1.0/26"
    },
    {
      name           = "Production"
      address_prefix = "10.10.3.0/24"
    }
  ]
}

variable "dns_servers" {
  description = "DNS servers for the virtual network"
  default     = ["10.10.3.4"]
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

###############################
# Virtual Network
###############################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space

  # Set the DNS server
  dns_servers = var.dns_servers
}

###############################
# Subnets
###############################
resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

###############################
# Outputs (optional)
###############################
output "vnet_dns_servers" {
  description = "The DNS servers configured for the virtual network"
  value       = azurerm_virtual_network.vnet.dns_servers
}
