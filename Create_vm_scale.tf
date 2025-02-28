provider "azurerm" {
  features {}
}

#####################
# Variables
#####################
variable "resource_group" {
  description = "The name of the resource group for the scale set"
  default     = "myResourceGroupScaleSet"
}

variable "location" {
  description = "Azure location for all resources"
  default     = "WestEurope"
}

variable "vnet_name" {
  description = "The name of the virtual network"
  default     = "myVnet"
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "mySubnet"
}

variable "scale_set_name" {
  description = "The name of the VM scale set"
  default     = "myScaleSet"
}

variable "public_ip_name" {
  description = "The name of the public IP for the load balancer"
  default     = "myPublicIPAddress"
}

variable "load_balancer_name" {
  description = "The name of the load balancer"
  default     = "myLoadBalancer"
}

variable "admin_username" {
  description = "Admin username for the VM scale set"
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM scale set"
  type        = string
  sensitive   = true
}

#####################
# Resource Group
#####################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

#####################
# Virtual Network and Subnet
#####################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_frontend" {
  name                = "myFrontendNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "myFrontendNSGRule"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  # Associate the NSG (allowing HTTP traffic)
  network_security_group_id = azurerm_network_security_group.nsg_frontend.id
}

#####################
# Public IP and Load Balancer
#####################
resource "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_lb" "lb" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "backendpool"
  }
}

#####################
# Windows VM Scale Set
#####################
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = var.scale_set_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_policy_mode = "Automatic"
  overprovision       = true

  sku {
    name     = "Standard_D2s_v3"
    tier     = "Standard"
    capacity = 3
  }

  # OS profile and credentials
  os_profile {
    computer_name_prefix = var.scale_set_name
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent           = true
    enable_automatic_upgrades    = true
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  # Network profile: attach the scale set to the subnet and load balancer
  network_profile {
    name = "networkprofile"

    ip_configuration {
      name      = "ipconfig"
      subnet_id = azurerm_subnet.subnet.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb.lb.backend_address_pool[0].id
      ]
      # If you wish to add NAT rules, use the load_balancer_inbound_nat_rules_ids attribute
    }
  }
}

#####################
# Custom Script Extension (to deploy IIS)
#####################
resource "azurerm_virtual_machine_scale_set_extension" "custom_script" {
  name                         = "customScript"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.8"
  settings = jsonencode({
    "fileUris"         = ["#"],
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis.tf"
  })
}

#####################
# Autoscale Settings
#####################
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autosetting"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "autoprofile"

    capacity {
      minimum = "2"
      maximum = "10"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
