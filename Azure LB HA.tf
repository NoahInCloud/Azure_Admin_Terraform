provider "azurerm" {
  features {}
}

#####################
# Variables
#####################
variable "resource_group_name" {
  default = "tw-azure-01"
}

variable "location" {
  default = "westeurope"
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machines"
  type        = string
  sensitive   = true
}

#####################
# Resource Group
#####################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

#####################
# Virtual Network and Subnet
#####################
resource "azurerm_virtual_network" "vnet" {
  name                = "MyVnet"
  address_space       = ["192.168.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "MySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

#####################
# Public IP
#####################
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

#####################
# Load Balancer
#####################
resource "azurerm_lb" "lb" {
  name                = "MyLoadBalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "myFrontEndPool"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  backend_address_pool {
    name = "myBackEndPool"
  }

  probe {
    name                = "myHealthProbe"
    protocol            = "Http"
    port                = 80
    request_path        = "/"
    interval_in_seconds = 360
    number_of_probes    = 5
  }

  loadbalancing_rule {
    name                           = "myLoadBalancerRuleWeb"
    protocol                       = "Tcp"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "myFrontEndPool"
    backend_address_pool_id        = azurerm_lb.lb.backend_address_pool[0].id
    probe_id                       = azurerm_lb.lb.probe[0].id
    enable_floating_ip             = false
    idle_timeout_in_minutes        = 4
  }

  inbound_nat_rule {
    name                           = "myLoadBalancerRDP1"
    protocol                       = "Tcp"
    frontend_port                  = 4221
    backend_port                   = 3389
    frontend_ip_configuration_name = "myFrontEndPool"
  }

  inbound_nat_rule {
    name                           = "myLoadBalancerRDP2"
    protocol                       = "Tcp"
    frontend_port                  = 4222
    backend_port                   = 3389
    frontend_ip_configuration_name = "myFrontEndPool"
  }

  inbound_nat_rule {
    name                           = "myLoadBalancerRDP3"
    protocol                       = "Tcp"
    frontend_port                  = 4223
    backend_port                   = 3389
    frontend_ip_configuration_name = "myFrontEndPool"
  }
}

#####################
# Network Security Group
#####################
resource "azurerm_network_security_group" "nsg" {
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "myNetworkSecurityGroupRuleRDP"
    description                = "Allow RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "myNetworkSecurityGroupRuleHTTP"
    description                = "Allow HTTP"
    priority                   = 2000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#####################
# Network Interfaces
#####################
resource "azurerm_network_interface" "nic_vm1" {
  name                = "MyNic1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pool_ids = [
      azurerm_lb.lb.backend_address_pool[0].id
    ]
    load_balancer_inbound_nat_rules_ids = [
      azurerm_lb.lb.inbound_nat_rule[0].id
    ]
  }
}

resource "azurerm_network_interface" "nic_vm2" {
  name                = "MyNic2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pool_ids = [
      azurerm_lb.lb.backend_address_pool[0].id
    ]
    load_balancer_inbound_nat_rules_ids = [
      azurerm_lb.lb.inbound_nat_rule[1].id
    ]
  }
}

resource "azurerm_network_interface" "nic_vm3" {
  name                = "MyNic3"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_id = azurerm_network_security_group.nsg.id

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    load_balancer_backend_address_pool_ids = [
      azurerm_lb.lb.backend_address_pool[0].id
    ]
    load_balancer_inbound_nat_rules_ids = [
      azurerm_lb.lb.inbound_nat_rule[2].id
    ]
  }
}

#####################
# Availability Set
#####################
resource "azurerm_availability_set" "avset" {
  name                         = "MyAvailabilitySet"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  sku                          = "Aligned"
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3
}

#####################
# Virtual Machines
#####################
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "myVM1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id
  ]
  availability_set_id = azurerm_availability_set.avset.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "myVM2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic_vm2.id
  ]
  availability_set_id = azurerm_availability_set.avset.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm3" {
  name                = "myVM3"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic_vm3.id
  ]
  availability_set_id = azurerm_availability_set.avset.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
