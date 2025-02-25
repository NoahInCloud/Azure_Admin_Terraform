terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

variable "domain" {
  description = "The domain for user principal names"
  default     = "Example.onmicrosoft.com"
}

resource "azuread_user" "fred_prefect" {
  user_principal_name   = "frPrefect@${var.domain}"
  display_name          = "Fred Prefect"
  mail_nickname         = "FrPrefect"
  password              = "agxsFX72xwsSAi"
  force_password_change = false
  account_enabled       = true

  given_name         = "Fred"
  surname            = "Prefect"
  job_title          = "Azure Administrator"
  department         = "Information Technology"
  city               = "Oberbuchsiten"
  state              = "SO"
  country            = "Switzerland"
  postal_code        = "4625"
  street_address     = "Hiltonstrasse"
  telephone_number   = "455-233-22"
  usage_location     = "CH"
}

output "fred_prefect_user_id" {
  description = "The object ID of the newly created Azure AD user"
  value       = azuread_user.fred_prefect.object_id
}
