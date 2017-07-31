resource "azurerm_availability_set" "osnodeas" {
  name                = "${var.openshift_azure_resource_prefix}-as-node-${var.openshift_azure_resource_suffix}"
  location            = "${azurerm_resource_group.osrg.location}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osnodenic" {
  name                      = "${var.openshift_azure_resource_prefix}-nic-node-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
  count                     = "${var.openshift_azure_node_vm_count}"
  location                  = "${azurerm_resource_group.osrg.location}"
  resource_group_name       = "${azurerm_resource_group.osrg.name}"
  network_security_group_id = "${azurerm_network_security_group.osnodensg.id}"

  ip_configuration {
    name                          = "configuration-${count.index}"
    subnet_id                     = "${azurerm_subnet.osnodesubnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "osnodevm" {
  name                  = "${var.openshift_azure_resource_prefix}-vm-node-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
  count                 = "${var.openshift_azure_node_vm_count}"
  location              = "${azurerm_resource_group.osrg.location}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.osnodenic.*.id, count.index)}"]
  availability_set_id   = "${azurerm_availability_set.osnodeas.id}"
  vm_size               = "${var.openshift_azure_node_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_azure_vm_os["publisher"]}"
    offer     = "${var.openshift_azure_vm_os["offer"]}"
    sku       = "${var.openshift_azure_vm_os["sku"]}"
    version   = "${var.openshift_azure_vm_os["version"]}"
  }

  storage_os_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-os-node-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-data-node-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.openshift_azure_data_disk_size}"
  }

  os_profile {
    computer_name  = "${var.openshift_azure_resource_prefix}-vm-node-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
    admin_username = "${var.openshift_azure_vm_username}"
    admin_password = "${uuid()}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.openshift_azure_vm_username}/.ssh/authorized_keys"
      key_data = "${file(var.openshift_azure_public_key)}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "osnodevmextension" {
  name                 = "osnodevmextension"
  count                = "${var.openshift_azure_node_vm_count}"
  location             = "${azurerm_resource_group.osrg.location}"
  resource_group_name  = "${azurerm_resource_group.osrg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.osnodevm.*.name, count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [
            "${var.openshift_azure_node_prep_script}"
        ],
        "commandToExecute": "bash nodePrep.sh ${azurerm_storage_account.osstoragepv.name} ${var.openshift_azure_vm_username}"
    }
SETTINGS
}
