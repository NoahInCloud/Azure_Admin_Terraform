# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroupVM"
  location = "westeurope"
}

# Create a Virtual Network (myVnet)
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Subnet (mySubnet)
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Network Security Group (myNetworkSecurityGroup)
resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Public IP for myVM
resource "azurerm_public_ip" "public_ip_vm1" {
  name                = "myPublicIpAddress"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create a Network Interface for myVM
resource "azurerm_network_interface" "nic_vm1" {
  name                = "myNIC_vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_vm1.id
  }
}

# Create the first Virtual Machine (myVM)
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "myVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # Initially using a size (e.g., Standard_DS3_v2); update this value to resize later.
  size                = "Standard_DS3_v2"

  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"  # Replace with a secure password or use a variable.

  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id,
  ]

  os_disk {
    name                 = "myOSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Use an image from the Azure Marketplace; adjust values as needed.
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"  # Default image for myVM; you can change it.
    version   = "latest"
  }
}

# Create resources for the second VM (myVM2)

# Public IP for myVM2
resource "azurerm_public_ip" "public_ip_vm2" {
  name                = "myPublicIpAddress2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Interface for myVM2
resource "azurerm_network_interface" "nic_vm2" {
  name                = "myNIC_vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_vm2.id
  }
}

# Create the second Virtual Machine (myVM2) with an explicit image
resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "myVM2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size                = "Standard_DS3_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.nic_vm2.id,
  ]

  os_disk {
    name                 = "myOSDisk_vm2"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Using a specific Marketplace image (WindowsServer 2016 Datacenter with Containers)
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-with-Containers"
    version   = "latest"
  }
}

# ------------------------------------------------------------
# VM Resizing (update operations)
#
# To resize a VM in Terraform, simply change the "size" attribute
# in the respective resource (e.g., from "Standard_DS3_v2" to
# "Standard_E2s_v3") and run "terraform apply". Terraform will update
# the resource accordingly.
#
# For example, to update myVM's size, change the size below:
#
# resource "azurerm_windows_virtual_machine" "vm1" {
#   ...
#   size = "Standard_E2s_v3"
#   ...
# }
#
# ------------------------------------------------------------

# Note: VM power operations (stop/start) and deletion of the resource
# group are typically performed using the Azure CLI/Portal or via
# Terraform commands like "terraform destroy" to tear down the resources.
