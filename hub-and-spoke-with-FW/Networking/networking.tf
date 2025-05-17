##############################################################
### Create VNET - Hub:

resource "azurerm_virtual_network" "VNET-hub" {
  name                = "VNET-Hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space = [
    "10.0.0.0/16"
  ]
}
resource "azurerm_subnet" "Subnet-Firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.location
  virtual_network_name = azurerm_virtual_network.VNET-hub.name
  address_prefixes     = ["10.0.1.0/24"]
}
##############################################################
### Create Public IP address for FW:

resource "azurerm_public_ip" "public_ip_fw" {
  name                = "PubIP_FW"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

##############################################################
### Create Firewall:

resource "azurerm_firewall" "FW-Hub" {
  name                = "Firewall-1"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier

  ip_configuration {
    name                 = "FW-ip-config"
    subnet_id            = azurerm_subnet.Subnet-Firewall.id
    public_ip_address_id = azurerm_public_ip.public_ip_fw.id
  }
  firewall_policy_id = azurerm_firewall_policy.Firewall_Policy.id
}
##############################################################
### Create IP group for subnets:

resource "azurerm_ip_group" "internal_ip_group" {
  name                = "Internal_IP_Group"
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs = [
    azurerm_subnet.Subnet-Firewall.id,
    azurerm_subnet.Subnet-Spoke1.id,
    azurerm_subnet.Subnet-Spoke2.id,
  ]
}
##############################################################
### Firewall policies:

resource "azurerm_firewall_policy" "Firewall_Policy" {
  name                     = "Firewall_Policy"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Alert"
}
##############################################################
### Firewall policy rule collections:

resource "azurerm_firewall_policy_rule_collection_group" "DefaulApplicationtRuleCollectionGroup" {
  name               = "DefaulApplicationtRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.Firewall_Policy.id
  priority           = 300
  application_rule_collection {
    name     = "DefaultApplicationRuleCollection"
    action   = "Allow"
    priority = 500
    rule {
      name = "AllowWindowsUpdate"

      description = "Allow Windows Update"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [
        azurerm_ip_group.internal_ip_group.id
      ]
      destination_fqdn_tags = ["WindowsUpdate"]
    }
    rule {
      name        = "Global Rule"
      description = "Allow access to Microsoft.com"
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.microsoft.com"]
      terminate_tls     = false
      source_ip_groups = [
        azurerm_ip_group.internal_ip_group.id
      ]
    }
  }
}
##############################################################
### Create VNET - Spoke1:

resource "azurerm_virtual_network" "VNET-Spoke1" {
  name                = "VNET-Spoke1"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space = [
    "10.1.0.0/16"
  ]
}
resource "azurerm_subnet" "Subnet-Spoke1" {
  name                 = "SUBNET-Spoke1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET-Spoke1.name
  address_prefixes     = ["10.1.1.0/24"]
}
##############################################################
### Create VNET - Spoke2:

resource "azurerm_virtual_network" "VNET-Spoke2" {
  name                = "VNET-Spoke2"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space = [
    "10.2.0.0/16"
  ]
}
resource "azurerm_subnet" "Subnet-Spoke2" {
  name                 = "SUBNET-Spoke2"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET-Spoke2.name
  address_prefixes     = ["10.2.1.0/24"]
}
##############################################################
### Create NSG - Hub

resource "azurerm_network_security_group" "NSG-Firewall" {
  name                = "NSG-Firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
}
##############################################################
### Create NSG - Spoke1

resource "azurerm_network_security_group" "NSG-Spoke1" {
  name                = "NSG-Spoke1"
  location            = var.location
  resource_group_name = var.resource_group_name
}
##############################################################
### Create NSG - Hub

resource "azurerm_network_security_group" "NSG-Spoke2" {
  name                = "NSG-Spoke2"
  location            = var.location
  resource_group_name = var.resource_group_name
}
##############################################################
### NSG-Firewall association:

resource "azurerm_subnet_network_security_group_association" "NSG-Hub" {
  network_security_group_id = azurerm_network_security_group.NSG-Firewall.id
  subnet_id                 = azurerm_subnet.Subnet-Firewall.id
}
##############################################################
### NSG-Spoke1 association:

resource "azurerm_subnet_network_security_group_association" "NSG-Spoke1" {
  network_security_group_id = azurerm_network_security_group.NSG-Spoke1.id
  subnet_id                 = azurerm_subnet.Subnet-Spoke1.id
}
##############################################################
### NSG-Spoke2 association:

resource "azurerm_subnet_network_security_group_association" "NSG-Spoke2" {
  network_security_group_id = azurerm_network_security_group.NSG-Spoke2.id
  subnet_id                 = azurerm_subnet.Subnet-Spoke2.id
}
##############################################################
### Peer Spoke1 to Hub:

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "spoke1-to-hub-"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.VNET-Spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.VNET-hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
}
##############################################################
### Peer Spoke1 to Hub:

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "spoke2-to-hub-"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.VNET-Spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.VNET-hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true
}
##############################################################
### User-defined route - Spoke1 to Hub:

resource "azurerm_route_table" "route-spoke1-to-hub" {
  name                = "route-spoke1-to-hub"
  location            = var.location
  resource_group_name = var.resource_group_name

  route = [
    {
      name                   = "force-outbound-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.FW-Hub.id
    }
  ]
}
##############################################################
### Associate route1 to spoke1:

resource "azurerm_subnet_route_table_association" "RTA-Spoke1" {
  route_table_id = azurerm_route_table.route-spoke1-to-hub.id
  subnet_id      = azurerm_subnet.Subnet-Spoke1.id
}
##############################################################
### User-defined route - Spoke2 to Hub:

resource "azurerm_route_table" "route-spoke2_to_hub" {
  name                = "route-spoke2-to-hub"
  location            = var.location
  resource_group_name = var.resource_group_name

  route = [
    {
      name                   = "route-table-spoke2"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.FW-Hub.ip_configuration[0].private_ip_address
    }
  ]
}
##############################################################
### Associate route1 to spoke2:

resource "azurerm_subnet_route_table_association" "RTA-Spoke2" {
  route_table_id = azurerm_route_table.route-spoke2_to_hub.id
  subnet_id      = azurerm_subnet.Subnet-Spoke2.id
}