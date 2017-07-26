resource "azurerm_virtual_network" "os" {
  name                = "vnet${azurerm_resource_group.os.name}"
  resource_group_name = "${azurerm_resource_group.os.name}"
  location            = "${azurerm_resource_group.os.location}"
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "osmasters" {
  name                      = "os-mastersSubnet"
  resource_group_name       = "${azurerm_resource_group.os.name}"
  virtual_network_name      = "${azurerm_virtual_network.os.name}"
  address_prefix            = "10.1.0.0/16"
}
resource "azurerm_subnet" "osnodes" {
  name                      = "os-nodesSubnet"
  resource_group_name       = "${azurerm_resource_group.os.name}"
  virtual_network_name      = "${azurerm_virtual_network.os.name}"
  network_security_group_id = "${azurerm_network_security_group.dcospublic.id}"
  address_prefix            = "10.0.0.0/11"
}
resource "azurerm_subnet" "dcosprivate" {
  name                      = "dcos-agentPrivateSubnet"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  virtual_network_name      = "${azurerm_virtual_network.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.dcosprivate.id}"
  address_prefix            = "10.32.0.0/11"
}

resource "azurerm_network_security_group" "osmasters" {
  name                = "os-masters-nsg"
  location            = "${azurerm_resource_group.os.location}"
  resource_group_name = "${azurerm_resource_group.os.name}"

  security_rule {
    name                       = "allowSSHin_all"
    description                = "Allow SSH in from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowHTTPS_all"
    description                = "Allow HTTPS connections from all locations"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowOpenShiftConsoleIn_all"
    description                = "Allow OpenShift Console connections from all locations"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "osnodes" {
  name                = "os-nodes-nsg"
  location            = "${azurerm_resource_group.os.location}"
  resource_group_name = "${azurerm_resource_group.os.name}"

  security_rule {
    name                       = "allowSSHin_all"
    description                = "Allow SSH in from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowHTTPSIn_all"
    description                = "Allow HTTPS traffic from the Internet to Public Agents"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowHTTPIn_all"
    description                = "Allow HTTP connections from all locations"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

