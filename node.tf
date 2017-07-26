resource "azurerm_availability_set" "osnodeas" {
  name                = "osnodeas"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"
}

resource "azurerm_virtual_network" "osnodevnet" {
  name                = "osnodevnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"
}

resource "azurerm_subnet" "osnodesubnet" {
  name                 = "osnodesubnet"
  resource_group_name  = "${var.openshift_azure_resource_group}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "osnodenic" {
  name                = "osnodenic"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = "${azurerm_subnet.osnodesubnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "osnodeip" {
  name                         = "osnodeip"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${var.openshift_azure_resource_group}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "osnodelb" {
  name                = "osnodelb"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osnodeip.id}"
  }
}

resource "azurerm_virtual_machine" "osnodevm" {
  name                  = "osnodevm"
  count                 = "${var.openshift_azure_node_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${var.openshift_azure_resource_group}"
  network_interface_ids = ["${azurerm_network_interface.osnodenic.id}"]
  availability_set_id   = "${azurerm_availability_set.osnodeas.id}"
  vm_size               = "${var.openshift_azure_node_vm_size}"

  storage_image_reference {
    publisher = "Openlogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "osnode"
    admin_username = "azureuser"
    admin_password = "password123"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys                        = "${var.openshift_azure_ssh_keys}"
  }
}

resource "azurerm_virtual_machine_extension" "osnodevmextension" {
  name                 = "osnodevmextension"
  count                = "${var.openshift_azure_infra_vm_count}"
  location             = "${var.openshift_azure_region}"
  resource_group_name  = "${var.openshift_azure_resource_group}"
  virtual_machine_name = "${azurerm_virtual_machine.osnodevm.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"

  settings = <<SETTINGS
    {
        "commandToExecute": "./scripts/nodePrep.sh"
    }
SETTINGS
}
