provider "azurerm" {
  features {}
}

provider "local" {}

###############################
# Variables & Random Suffix
###############################
variable "location" {
  default = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  name     = "tw-azfile-rg"
  location = var.location
}

resource "random_string" "storage_suffix" {
  length  = 4
  upper   = false
  special = false
}

###############################
# Storage Account
###############################
resource "azurerm_storage_account" "storage" {
  name                     = "mystorageacct${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"
}

###############################
# Azure File Share 1 and Directory
###############################
resource "azurerm_storage_share" "share1" {
  name                 = "myshare"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "dir1" {
  name                 = "myDirectory"
  share_name           = azurerm_storage_share.share1.name
  storage_account_name = azurerm_storage_account.storage.name
}

###############################
# Create Local File with Current Timestamp
###############################
resource "local_file" "sample_upload" {
  filename = "C:/Temp/SampleUpload.txt"
  content  = timestamp()
}

###############################
# Upload the File to File Share (simulate Set-AzStorageFileContent)
###############################
resource "azurerm_storage_share_file" "uploaded_file" {
  name                 = "SampleUpload.txt"
  share_name           = azurerm_storage_share.share1.name
  storage_account_name = azurerm_storage_account.storage.name
  directory            = azurerm_storage_share_directory.dir1.name
  source               = local_file.sample_upload.filename
}

###############################
# Azure File Share 2 and Directory (for Copy Operation)
###############################
resource "azurerm_storage_share" "share2" {
  name                 = "myshare2"
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "dir2" {
  name                 = "myDirectory2"
  share_name           = azurerm_storage_share.share2.name
  storage_account_name = azurerm_storage_account.storage.name
}

###############################
# Simulate File Copy by Uploading the Same File
###############################
resource "azurerm_storage_share_file" "copied_file" {
  name                 = "SampleCopy.txt"
  share_name           = azurerm_storage_share.share2.name
  storage_account_name = azurerm_storage_account.storage.name
  directory            = azurerm_storage_share_directory.dir2.name
  source               = local_file.sample_upload.filename
}

###############################
# Outputs
###############################
output "uploaded_file_id" {
  description = "ID of the uploaded file in the first share"
  value       = azurerm_storage_share_file.uploaded_file.id
}

output "copied_file_id" {
  description = "ID of the copied file in the second share"
  value       = azurerm_storage_share_file.copied_file.id
}
