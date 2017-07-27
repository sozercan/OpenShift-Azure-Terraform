resource "azurerm_availability_set" "osinfraas" {
  name                = "${var.openshift_azure_resource_prefix}-as-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osinfranic" {
  name                = "${var.openshift_azure_resource_prefix}-nic-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  ip_configuration {
    name                                    = "configuration"
    subnet_id                               = "${azurerm_subnet.osinfrasubnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.osinfralbbepool.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${azurerm_lb_nat_rule.osinfralbnatrule.id}"]
  }
}

resource "azurerm_lb_backend_address_pool" "osinfralbbepool" {
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id     = "${azurerm_lb.osinfralb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "osinfralbnatrule" {
  resource_group_name            = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id                = "${azurerm_lb.osinfralb.id}"
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_public_ip" "osinfraip" {
  name                         = "${var.openshift_azure_resource_prefix}-vip-infra-${var.openshift_azure_resource_suffix}"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${azurerm_resource_group.osrg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.openshift_azure_resource_prefix}-${var.openshift_infra_dns_name}-${var.openshift_azure_resource_suffix}"
}

resource "azurerm_lb" "osinfralb" {
  name                = "${var.openshift_azure_resource_prefix}-nlb-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osinfraip.id}"
  }
}

resource "azurerm_virtual_machine" "osinfravm" {
  name                  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
  count                 = "${var.openshift_azure_infra_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${azurerm_network_interface.osinfranic.id}"]
  availability_set_id   = "${azurerm_availability_set.osinfraas.id}"
  vm_size               = "${var.openshift_azure_infra_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_azure_vm_os["publisher"]}"
    offer     = "${var.openshift_azure_vm_os["offer"]}"
    sku       = "${var.openshift_azure_vm_os["sku"]}"
    version   = "${var.openshift_azure_vm_os["version"]}"
  }

  storage_os_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-os-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.openshift_azure_resource_prefix}-disk-data-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "128"
  }

  os_profile {
    computer_name  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
    admin_username = "${var.openshift_azure_vm_username}"
    admin_password = "${uuid()}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.openshift_azure_vm_username}/.ssh/authorized_keys"
      key_data = "${var.openshift_azure_ssh_key}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "osinfravmextension" {
  name                 = "osinfravmextension"
  count                = "${var.openshift_azure_infra_vm_count}"
  location             = "${var.openshift_azure_region}"
  resource_group_name  = "${azurerm_resource_group.osrg.name}"
  virtual_machine_name = "${azurerm_virtual_machine.osinfravm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [
            "https://raw.githubusercontent.com/julienstroheker/OpenShift-Azure-Terraform/master/scripts/nodePrep.sh"
        ],
        "commandToExecute": "bash nodePrep.sh ospvstorage567 ${var.openshift_azure_vm_username}"
    }
SETTINGS
}
