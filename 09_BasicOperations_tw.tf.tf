terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

# The provider will use your Azure CLI or environment credentials.
provider "azuread" {}

# Get details about the current Azure AD client (tenant, object ID, etc.)
data "azuread_client_config" "current" {}

# Retrieve the list of domains for your tenant
data "azuread_domains" "all" {}

#####################
# Outputs
#####################
output "tenant_id" {
  description = "The tenant ID from the current Azure AD session"
  value       = data.azuread_client_config.current.tenant_id
}

output "object_id" {
  description = "The object ID of the current Azure AD client"
  value       = data.azuread_client_config.current.object_id
}

output "domains" {
  description = "A list of domain names in the tenant"
  value       = data.azuread_domains.all.domain_names
}
