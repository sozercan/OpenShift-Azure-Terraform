resource "azurerm_virtual_network" "osvnet" {
  name                = "osvnet"
  resource_group_name = "${var.openshift_azure_resource_group}"
  location            = "${var.openshift_azure_region}"
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "osmastersubnet" {
  name                      = "osmastersubnet"
  resource_group_name       = "${var.openshift_azure_resource_group}"
  virtual_network_name      = "${azurerm_virtual_network.osvnet.name}"
  network_security_group_id = "${azurerm_network_security_group.osmasternsg.id}"
  address_prefix            = "10.1.0.0/16"
}

resource "azurerm_subnet" "osnodesubnet" {
  name                      = "osnodesubnet"
  resource_group_name       = "${var.openshift_azure_resource_group}"
  virtual_network_name      = "${azurerm_virtual_network.osvnet.name}"
  network_security_group_id = "${azurerm_network_security_group.osnodensg.id}"
  address_prefix            = "10.2.0.0/16"
}

resource "azurerm_subnet" "osinfrasubnet" {
  name                      = "osinfrasubnet"
  resource_group_name       = "${var.openshift_azure_resource_group}"
  virtual_network_name      = "${azurerm_virtual_network.osvnet.name}"
  network_security_group_id = "${azurerm_network_security_group.osinfransg.id}"
  address_prefix            = "10.3.0.0/16"
}

resource "azurerm_network_security_group" "osmasternsg" {
  name                = "os-master-nsg"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

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

resource "azurerm_network_security_group" "osnodensg" {
  name                = "os-node-nsg"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

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
    source_address_prefix      = "*"
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

resource "azurerm_network_security_group" "osinfransg" {
  name                = "os-infra-nsg"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

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
    source_address_prefix      = "*"
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
