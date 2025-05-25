##############################################################
### Providers:

terraform {
  backend "local" {
    path = "./state/terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "=1.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
  }
}
provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  #resource_provider_registrations = "none" # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

provider "azuread" {
  tenant_id = var.tenant_id
}
provider "azapi" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
##############################################################
### Resoucre Group:

resource "azurerm_resource_group" "strg_acc_group" {
  name     = "strg_account_rg"
  location = var.location
}

##############################################################
### Create storage account:

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = true
}
locals {
  strg_acc_name = "str_acc_${random_string.random.result}"
}
resource "azurerm_storage_account" "storage_account" {
  name                      = local.strg_acc_name
  resource_group_name       = azurerm_resource_group.strg_acc_group.name
  location                  = var.location
  account_tier              = var.strg_acc_tier
  account_replication_type  = var.strg_acc_tier
  account_kind              = var.strg_acc_kind
  large_file_share_enabled  = true
  min_tls_version           = "TLS1_2"
  shared_access_key_enabled = true

  tags = {
    Type    = "StorageAccount"
    Service = "Storage"
    RG      = azurerm_resource_group.strg_acc_group.name
  }

}
##############################################################
### Create the FileShare1 and FileShare2 file shares:

resource "azurerm_storage_share" "FileShare1" {
  name               = "FileShare1"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 100

}

resource "azurerm_storage_share" "FileShare2" {
  name               = "FileShare2"
  storage_account_id = azurerm_storage_account.storage_account.id
  quota              = 100

}
##############################################################
