resource "azurerm_availability_set" "osinfraas" {
  name                = "${var.openshift_azure_resource_prefix}-as-infra-${var.openshift_azure_resource_suffix}"
  location            = "${azurerm_resource_group.osrg.location}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osinfranic" {
  name                      = "${var.openshift_azure_resource_prefix}-nic-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
  count                     = "${var.openshift_azure_infra_vm_count}"
  location                  = "${azurerm_resource_group.osrg.location}"
  resource_group_name       = "${azurerm_resource_group.osrg.name}"
  network_security_group_id = "${azurerm_network_security_group.osinfransg.id}"

  ip_configuration {
    name                                    = "configuration-${count.index}"
    subnet_id                               = "${azurerm_subnet.osmastersubnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.osinfralbbepool.id}"]
  }
}

resource "azurerm_lb_backend_address_pool" "osinfralbbepool" {
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id     = "${azurerm_lb.osinfralb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_public_ip" "osinfraip" {
  name                         = "${var.openshift_azure_resource_prefix}-vip-infra-${var.openshift_azure_resource_suffix}"
  location                     = "${azurerm_resource_group.osrg.location}"
  resource_group_name          = "${azurerm_resource_group.osrg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.openshift_azure_resource_prefix}-${var.openshift_infra_dns_name}-${var.openshift_azure_resource_suffix}"
}

resource "azurerm_lb" "osinfralb" {
  name                = "${var.openshift_azure_resource_prefix}-nlb-infra-${var.openshift_azure_resource_suffix}"
  location            = "${azurerm_resource_group.osrg.location}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osinfraip.id}"
  }
}

resource "azurerm_lb_rule" "osinfralbrule80" {
  resource_group_name            = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id                = "${azurerm_lb.osinfralb.id}"
  name                           = "OpenShiftRouterHTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.osinfralbprobe80.id}"
}

resource "azurerm_lb_probe" "osinfralbprobe80" {
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id     = "${azurerm_lb.osinfralb.id}"
  name                = "httpProbe"
  port                = 80
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "osinfralbrule443" {
  resource_group_name            = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id                = "${azurerm_lb.osinfralb.id}"
  name                           = "OpenShiftRouterHTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.osinfralbprobe443.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.osinfralbbepool.id}"
}

resource "azurerm_lb_probe" "osinfralbprobe443" {
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id     = "${azurerm_lb.osinfralb.id}"
  name                = "httpsProbe"
  port                = 443
  number_of_probes    = 2
}

resource "azurerm_virtual_machine" "osinfravm" {
  name                  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
  count                 = "${var.openshift_azure_infra_vm_count}"
  location              = "${azurerm_resource_group.osrg.location}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.osinfranic.*.id, count.index)}"]
  availability_set_id   = "${azurerm_availability_set.osinfraas.id}"
  vm_size               = "${var.openshift_azure_infra_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_azure_vm_os["publisher"]}"
    offer     = "${var.openshift_azure_vm_os["offer"]}"
    sku       = "${var.openshift_azure_vm_os["sku"]}"
    version   = "${var.openshift_azure_vm_os["version"]}"
  }

  storage_os_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-os-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-data-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.openshift_azure_data_disk_size}"
  }

  os_profile {
    computer_name  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index)}"
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

resource "azurerm_virtual_machine_extension" "osinfravmextension" {
  name                 = "osinfravmextension"
  count                = "${var.openshift_azure_infra_vm_count}"
  location             = "${azurerm_resource_group.osrg.location}"
  resource_group_name  = "${azurerm_resource_group.osrg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.osinfravm.*.name, count.index)}"
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
