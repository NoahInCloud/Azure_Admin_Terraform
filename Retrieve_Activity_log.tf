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

###############################
# Query: Logs from a Specific Start Time to Present
###############################
data "azurerm_monitor_activity_log" "from_start" {
  start_time = "2020-08-14T10:30:00Z"
}

###############################
# Query: Logs Between a Specific Time Range
###############################
data "azurerm_monitor_activity_log" "in_range" {
  start_time = "2020-08-14T10:30:00Z"
  end_time   = "2020-08-14T11:30:00Z"
}

###############################
# Query: Logs for a Specific Resource Group
###############################
data "azurerm_monitor_activity_log" "rg_logs" {
  resource_group_name = "tw-rg01"
}

###############################
# Query: Logs for a Specific Resource Provider (e.g., Microsoft.Web) within a Time Range
###############################
data "azurerm_monitor_activity_log" "provider_logs" {
  resource_provider = "Microsoft.Web"
  start_time        = "2020-08-14T10:30:00Z"
  end_time          = "2020-08-14T11:30:00Z"
}

###############################
# Query: Logs with a Specific Caller
###############################
data "azurerm_monitor_activity_log" "caller_logs" {
  caller      = "Noah@example.io"
  max_records = 10
}

###############################
# Query: Last 10 Activity Log Events
###############################
data "azurerm_monitor_activity_log" "last_10" {
  max_records = 10
}

###############################
# Outputs
###############################
output "logs_from_start" {
  description = "Log entries from 2020-08-14T10:30 to present"
  value       = data.azurerm_monitor_activity_log.from_start.events
}

output "logs_in_range" {
  description = "Log entries from 2020-08-14T10:30 to 2020-08-14T11:30"
  value       = data.azurerm_monitor_activity_log.in_range.events
}

output "resource_group_logs" {
  description = "Log entries for resource group 'tw-rg01'"
  value       = data.azurerm_monitor_activity_log.rg_logs.events
}

output "provider_logs" {
  description = "Log entries for provider 'Microsoft.Web' between 2020-08-14T10:30 and 2020-08-14T11:30"
  value       = data.azurerm_monitor_activity_log.provider_logs.events
}

output "caller_logs" {
  description = "Last 10 log entries with caller 'Noah@example.io'"
  value       = data.azurerm_monitor_activity_log.caller_logs.events
}

output "last_10_logs" {
  description = "The last 10 activity log events"
  value       = data.azurerm_monitor_activity_log.last_10.events
}
