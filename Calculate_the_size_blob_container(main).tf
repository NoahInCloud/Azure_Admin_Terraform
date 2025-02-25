terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# Variables for your storage account and container.
variable "resource_group" {
  description = "The resource group containing the storage account"
  default     = "tw-rg100"
}

variable "storage_account_name" {
  description = "The storage account name"
  default     = "twstacc2020"
}

variable "container_name" {
  description = "The container name containing the blobs"
  default     = "testblobs"
}

# Use the external data source to run a script that retrieves blob sizes.
data "external" "blob_info" {
  program = ["python3", "${path.module}/get_blob_sizes.py"]
  query = {
    resource_group  = var.resource_group
    storage_account = var.storage_account_name
    container       = var.container_name
  }
}

output "blob_info" {
  description = "A list of blobs with their sizes and the total size of all blobs"
  value       = data.external.blob_info.result
}
