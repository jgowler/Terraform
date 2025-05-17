##############################################################
### Create Resource Group:

resource "azurerm_resource_group" "RG-hub-and-spoke" {
  name     = "RG-hub-and-spoke"
  location = var.location
}