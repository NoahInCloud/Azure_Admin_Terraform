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

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "myKeyVaultRG"
  location = "westeurope"
}

resource "azurerm_key_vault" "kv" {
  name                = "mykeyvault123"  # Must be globally unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_enabled = true
}

# Create the Root Certificate (self-signed)
resource "azurerm_key_vault_certificate" "root_cert" {
  name         = "P2SRootCert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      key_size   = 2048
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject            = "CN=P2SRootCert"
      validity_in_months = 12
    }
  }
}

# Create the Child Certificate (self-signed with extended key usage)
resource "azurerm_key_vault_certificate" "child_cert" {
  name         = "P2SChildCert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      # In your PowerShell, you used the root certificate as the signer.
      # Terraform's resource does not yet support specifying an external signer.
      # Therefore, we generate a self-signed certificate.
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      key_size   = 2048
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject            = "CN=P2SChildCert"
      validity_in_months = 12
      # Specify Extended Key Usage to match OID 1.3.6.1.5.5.7.3.2 (Client Authentication)
      extended_key_usage = ["ClientAuth"]
    }
  }
}

output "root_certificate_url" {
  description = "The certificate URL for the root certificate"
  value       = azurerm_key_vault_certificate.root_cert.certificate_url
}

output "child_certificate_url" {
  description = "The certificate URL for the child certificate"
  value       = azurerm_key_vault_certificate.child_cert.certificate_url
}
