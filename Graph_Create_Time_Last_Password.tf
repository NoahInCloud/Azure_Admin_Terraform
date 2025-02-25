terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# Call an external script to retrieve Microsoft Graph user data.
data "external" "mg_users" {
  # This will run the PowerShell script get_mg_users.ps1 (make sure it’s in the same directory).
  program = ["pwsh", "-File", "${path.module}/get_mg_users.ps1"]
  
  # Pass query parameters: a date threshold (60 days ago) and a comma‐separated list of properties.
  query = {
    date_threshold = formatdate("2006-01-02T15:04:05Z", timeadd(timestamp(), "-60d"))
    properties     = "AccountEnabled,UserPrincipalName,Id,CreatedDateTime,LastPasswordChangeDateTime"
  }
}

output "filtered_mg_users" {
  description = "Filtered Microsoft Graph users as JSON"
  value       = data.external.mg_users.result
}
