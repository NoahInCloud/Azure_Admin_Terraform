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

# Data source to fetch details for an existing Windows VM.
data "azurerm_windows_virtual_machine" "example_vm" {
  name                = "tw-winsrv"
  resource_group_name = "tw-rg01"
}

# Output all available attributes as JSON (similar to Select-Object *)
output "vm_full_details" {
  description = "Full details of the VM as retrieved from Azure"
  value       = data.azurerm_windows_virtual_machine.example_vm
}

# Output selected attributes (similar to: Select-Object Name, VmId, ProvisioningState)
output "vm_selected_details" {
  description = "Selected details of the VM"
  value = {
    Name              = data.azurerm_windows_virtual_machine.example_vm.name
    VmId              = data.azurerm_windows_virtual_machine.example_vm.id
    ProvisioningState = data.azurerm_windows_virtual_machine.example_vm.provisioning_state
  }
}
