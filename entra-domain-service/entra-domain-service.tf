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
### Locals:

locals {
  aadds_domain = azurerm_active_directory_domain_service.aadds-domain.domain_name
}
data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "config" {}
data "azuread_domains" "default" {}
##############################################################
### Check for Microsoft.AAD registration - ignore if registered, register if not registered:

data "external" "provider_status" {
  program = ["powershell", "-Command", "$status = (az provider show --namespace 'Microsoft.AAD' | ConvertFrom-Json).registrationState; $json = @{status = $status} | ConvertTo-Json -Compress; Write-Output $json"]
}
check "azurerm_resource_provider_registered" {
  assert {
    condition     = data.external.provider_status.result["status"] == "Unregistered"
    error_message = "Microsoft.AAD provider is already registered. Import into state before continuing."
  }
}
resource "azurerm_resource_provider_registration" "aadds" {
  name = "Microsoft.AAD"
}

# terraform import azurerm_resource_provider_registration.aadds /subscriptions/{SUBSCRIPTION_ID}/providers/Microsoft.AAD
##############################################################
### Service Principal:

data "external" "azuread_service_principal_created" {
  program = ["powershell", "-Command", "$sp = az ad sp show --id 2565bd9d-da50-47d4-8b85-4c97f669dc36; if ($sp) { $json = @{exists = \"true\"} | ConvertTo-Json -Compress } else { $json = @{exists = \"false\"} | ConvertTo-Json -Compress }; Write-Output $json"]
}
check "azuread_service_principal_created" {
  assert {
    condition     = data.external.azuread_service_principal_created.result["exists"] == "false"
    error_message = "Domain Controller Service Principal is already present in the tenant. Import it into Terraform state before continuing."
  }
}
resource "azuread_service_principal" "aadds" {
  client_id = "2565bd9d-da50-47d4-8b85-4c97f669dc36"

  depends_on = [
    azurerm_resource_provider_registration.aadds
  ]
}

# terraform import azuread_service_principal.aadds "servicePrincipals/2565bd9d-da50-47d4-8b85-4c97f669dc36"
##############################################################
### Resource Group:

resource "azurerm_resource_group" "AADDS-rg" {
  name     = "AADDS-rg"
  location = var.location
}
##############################################################
### Create VNET - VNET-Entra-Domain:

resource "azurerm_virtual_network" "VNET-AADDS" {
  name                = "VNET-AADDS"
  location            = var.location
  resource_group_name = azurerm_resource_group.AADDS-rg.name
  address_space = [
    "10.1.0.0/16"
  ]
}
resource "azurerm_subnet" "Subnet-AADDS" {
  name                 = "SUBNET-AADDS"
  resource_group_name  = azurerm_resource_group.AADDS-rg.name
  virtual_network_name = azurerm_virtual_network.VNET-AADDS.name
  address_prefixes     = ["10.1.1.0/24"]
}
##############################################################
### Associate NSG with subnet:

resource "azurerm_network_security_group" "NSG-AADDS" {
  name                = "NSG-AADDS"
  location            = azurerm_resource_group.AADDS-rg.location
  resource_group_name = azurerm_resource_group.AADDS-rg.name

  security_rule {
    name                       = "AllowRD"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPSRemoting"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

  tags = {
    Type    = "NSG"
    Service = "Networking"
    RG      = azurerm_resource_group.AADDS-rg.name
  }
}
##############################################################
### NSG association:

resource "azurerm_subnet_network_security_group_association" "aadds_nsg_association" {
  subnet_id                 = azurerm_subnet.Subnet-AADDS.id
  network_security_group_id = azurerm_network_security_group.NSG-AADDS.id
}
##############################################################
### Create Domain service:

resource "azurerm_active_directory_domain_service" "aadds-domain" {
  name                = "aadds.example.com"
  location            = azurerm_resource_group.AADDS-rg.location
  resource_group_name = azurerm_resource_group.AADDS-rg.name

  domain_name           = "aadds.example.com"
  sku                   = "Standard"
  filtered_sync_enabled = false

  initial_replica_set {
    subnet_id = azurerm_subnet.Subnet-AADDS.id
  }

  notifications {
    additional_recipients = var.recipient
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
  }

  tags = {
    Type    = "Service"
    Service = "Domain"
    RG      = azurerm_resource_group.AADDS-rg.name
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.aadds_nsg_association,
    azurerm_resource_provider_registration.aadds,
    azuread_service_principal.aadds,
  ]
}
##############################################################
### Create AADDS DC Admin account:

resource "azuread_user" "dc_admin" {
  user_principal_name = "AADDSAdmin@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "AADDS DC Administrator"
  password            = random_password.dc_admin.result

  depends_on = [
    azurerm_active_directory_domain_service.aadds-domain,
  ]
}
##############################################################
### Create AADDS DC Admin group:
resource "azuread_group" "aad_dc_administrators" {
  display_name     = "AAD DC Administrators"
  security_enabled = true
  members = [
    azuread_user.dc_admin.object_id,
  ]

  depends_on = [
    azurerm_active_directory_domain_service.aadds-domain,
    azuread_user.dc_admin,
  ]
}
##############################################################
### Generate AADDS DC Administrator password:
resource "random_password" "dc_admin" {
  length = 64
}

