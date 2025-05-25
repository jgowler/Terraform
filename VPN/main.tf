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
### Resource Group:

resource "azurerm_resource_group" "vpn-rg" {
  name     = "vpn-rg"
  location = var.location
}
##############################################################
### Create VPN VNET:

resource "azurerm_virtual_network" "VNET-VPN" {
  name                = "VNET-VPN"
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn-rg.name
  address_space       = ["10.2.0.0/16"]

  tags = {
    Type    = "VNET"
    Service = "VPN"
    RG      = azurerm_resource_group.vpn-rg.name
  }
}
##############################################################
### Create VPN Subnet:

resource "azurerm_subnet" "Subnet-VPN" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vpn-rg.name
  virtual_network_name = azurerm_virtual_network.VNET-VPN.name
  address_prefixes     = ["10.2.0.0/24"]

  depends_on = [
    azurerm_virtual_network.VNET-VPN
  ]
}
##############################################################
### Create VPN Gateway public IP:

resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "VPNGW-PubIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Type    = "PublicIP"
    Service = "VPN"
    RG      = azurerm_resource_group.vpn-rg.name
  }
}
##############################################################
### Create VPN Gateway:

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "vpngw-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn-rg.name

  type       = "Vpn"
  vpn_type   = "RouteBased"
  enable_bgp = false

  sku = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip.id
    subnet_id                     = azurerm_subnet.Subnet-VPN.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Type    = "VPNGateway"
    Service = "VPN"
    RG      = azurerm_resource_group.vpn-rg.name
  }
}
##############################################################
### Create Local Network Gateway:

resource "azurerm_local_network_gateway" "local_gateway" {
  name                = "vpngw-local-site1"
  resource_group_name = azurerm_resource_group.vpn-rg.name
  location            = var.location
  gateway_address     = var.gateway_address
  address_space       = [var.local_address_space]
}
##############################################################
### Generate gateway connection shared key:

resource "random_password" "VPN_connection_shared_key" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}
##############################################################
### Create VNET Gateway Connection:

resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                = "vpn-connection-site1"
  location            = var.location
  resource_group_name = azurerm_resource_group.vpn-rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_gateway.id

  shared_key          = random_password.VPN_connection_shared_key.result
  connection_protocol = "IKEv2"

  depends_on = [
    azurerm_virtual_network_gateway.vpn_gateway,
    azurerm_local_network_gateway.local_gateway,
  ]
}
