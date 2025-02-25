provider "azurerm" {
  features {}
}

###############################
# Resource Group
###############################
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "WestEurope"
}

###############################
# Recovery Services Vault
###############################
resource "azurerm_recovery_services_vault" "vault" {
  name                     = "myRecoveryServicesVault"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  backup_storage_redundancy = "GeoRedundant"  # Sets storage redundancy to GRS
}

###############################
# Backup Policy for VMs (Creating a policy similar to the built-in "DefaultPolicy")
###############################
resource "azurerm_recovery_services_backup_policy_vm" "default_policy" {
  name                = "DefaultPolicy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
    timezone  = "UTC"
  }

  retention_daily {
    count = 30
  }
}

###############################
# Reference to an Existing Virtual Machine
###############################
data "azurerm_virtual_machine" "vm" {
  name                = "myVM"
  resource_group_name = azurerm_resource_group.rg.name
}

###############################
# Enable Backup Protection for the VM
###############################
resource "azurerm_recovery_services_protected_vm" "vm_backup" {
  recovery_vault_id = azurerm_recovery_services_vault.vault.id
  source_vm_id      = data.azurerm_virtual_machine.vm.id
  backup_policy_id  = azurerm_recovery_services_backup_policy_vm.default_policy.id
}

###############################
# Outputs (Optional)
###############################
output "vault_id" {
  description = "The ID of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.vault.id
}

output "protected_vm_id" {
  description = "The ID of the protected virtual machine"
  value       = azurerm_recovery_services_protected_vm.vm_backup.id
}
