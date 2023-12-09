data "azurerm_resource_group" "this" {
  name = "${var.deployment_prefix}"
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.deployment_prefix}-vnet"
  address_space       = ["192.168.10.0/24"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "${var.deployment_prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["192.168.10.0/25"]
}


resource "azurerm_subnet" "this2" {
  name                 = "${var.deployment_prefix}-subnet2"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["192.168.10.128/25"]
}

