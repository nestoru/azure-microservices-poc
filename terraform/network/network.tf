resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "vnet1_subnet"
  resource_group_name  = "devops-microservices"
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "vnet2_subnet"
  resource_group_name  = "devops-microservices"
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.1.0/24"]
}

output "subnet1_id" {
  value = azurerm_subnet.subnet1.id
}

output "subnet2_id" {
  value = azurerm_subnet.subnet2.id
}

