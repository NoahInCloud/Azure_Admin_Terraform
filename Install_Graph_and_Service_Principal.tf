terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

data "azuread_service_principal" "twwebapp" {
  display_name = "twwebapp2021"
}

output "twwebapp_info" {
  value = {
    DisplayName           = data.azuread_service_principal.twwebapp.display_name
    ObjectId              = data.azuread_service_principal.twwebapp.object_id
    ApplicationId         = data.azuread_service_principal.twwebapp.application_id
    SignInAudience        = data.azuread_service_principal.twwebapp.sign_in_audience
    AppOwnerOrganizationId = data.azuread_service_principal.twwebapp.app_owner_organization_id
  }
}
