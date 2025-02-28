terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# Variables for the subscription and resource group
variable "subscription_id" {
  description = "The subscription ID where the VMs reside."
  default     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "resource_group" {
  description = "The resource group name."
  default     = "tw-rg01"
}

variable "report_name" {
  description = "The CSV report file name."
  default     = "myReport.csv"
}

# Call an external script to retrieve VM reporting data.
data "external" "vm_report" {
  program = ["python3", "${path.module}/get_vm_report.py"]
  query = {
    subscription_id = var.subscription_id
    resource_group  = var.resource_group
  }
}

# Write the CSV output (returned by the external script) to a local file.
resource "local_file" "csv_report" {
  filename = "${path.module}/${var.report_name}"
  content  = data.external.vm_report.result.csv
}

output "report_csv" {
  description = "The CSV report content."
  value       = local_file.csv_report.content
}
