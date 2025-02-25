terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# This external data source calls a PowerShell script that retrieves the LAPS password.
data "external" "laps_credentials" {
  program = ["pwsh", "-File", "${path.module}/get_laps.ps1"]
  query = {
    devName = "cl01"
  }
}

# Output the result (mark as sensitive)
output "laps_credentials" {
  description = "Retrieved LAPS credentials for the device"
  value       = data.external.laps_credentials.result
  sensitive   = true
}
