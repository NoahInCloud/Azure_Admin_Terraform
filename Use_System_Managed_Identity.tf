terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################
# Retrieve Existing VM Info
###############################
# Assumes a Windows VM "tw-winsrv" in resource group "tw-rg01" exists and has a system-assigned managed identity.
data "azurerm_windows_virtual_machine" "target_vm" {
  name                = "tw-winsrv"
  resource_group_name = "tw-rg01"
}

output "managed_identity_principal_id" {
  description = "The system-assigned managed identity principal ID of the VM."
  value       = data.azurerm_windows_virtual_machine.target_vm.identity[0].principal_id
}

###############################
# Download a Blob Using Azure CLI
###############################
resource "null_resource" "download_blob" {
  provisioner "local-exec" {
    command = "az storage blob download --account-name twstg00001 --container-name bilder --name IMG_0498.jpg --destination C:\\Temp\\IMG_0498.jpg --auth-mode login"
  }
}
