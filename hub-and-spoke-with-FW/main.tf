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
      source = "Azure/azapi"
      #version = ">1.10.0"
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
### Create Resource Groups:

module "ResourceGroups" {
  source = "./ResourceGroups"

  location = var.location
}
##############################################################
### Create Networks:

module "Networking" {
  source = "./Networking"

  location            = var.location
  resource_group_name = module.ResourceGroups.resource_group_name
}
##############################################################