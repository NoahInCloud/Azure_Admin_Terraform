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

resource "azurerm_recovery_services_vault" "vault" {
  name                = "twrsv2022"
  resource_group_name = "az-104-rg"
  location            = "westeurope"
  sku_name            = "Standard"
}

output "vault_id" {
  description = "The ID of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.vault.id
}
