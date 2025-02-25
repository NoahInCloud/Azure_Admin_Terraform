terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

data "azuread_service_principal" "example" {
  # Replace with the desired application ID.
  application_id = "461e8683-5575-4561-ac7f-899cc907d62a"
}

output "example_service_principal" {
  description = "Details for the queried service principal"
  value       = data.azuread_service_principal.example
}
