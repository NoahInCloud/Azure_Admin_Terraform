resource "null_resource" "perform_maintenance" {
  triggers = {
    vm_id = azurerm_windows_virtual_machine.vm.id
  }

  provisioner "local-exec" {
    command = "az vm restart --ids ${azurerm_windows_virtual_machine.vm.id} --perform-maintenance"
  }
}
