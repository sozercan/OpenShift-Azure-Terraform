resource "azurerm_availability_set" "osmasteras" {
  name                = "osmasteras"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osmasternic" {
  name                = "osmasternic"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  ip_configuration {
    name                                    = "configuration"
    subnet_id                               = "${azurerm_subnet.osmastersubnet.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.osmasterlbbepool.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${azurerm_lb_nat_rule.osmasterlbnatrule.id}"]
  }
}

resource "azurerm_lb_backend_address_pool" "osmasterlbbepool" {
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id     = "${azurerm_lb.osmasterlb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "osmasterlbnatrule" {
  resource_group_name            = "${azurerm_resource_group.osrg.name}"
  loadbalancer_id                = "${azurerm_lb.osmasterlb.id}"
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_public_ip" "osmasterip" {
  name                         = "osmasterip"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${azurerm_resource_group.osrg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.openshift_azure_resource_group}"
}

resource "azurerm_lb" "osmasterlb" {
  name                = "osmasterlb"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osmasterip.id}"
  }
}

resource "azurerm_virtual_machine" "osmastervm" {
  name                  = "osmastervm"
  count                 = "${var.openshift_azure_master_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${azurerm_network_interface.osmasternic.id}"]
  availability_set_id   = "${azurerm_availability_set.osmasteras.id}"
  vm_size               = "${var.openshift_azure_master_vm_size}"

  storage_image_reference {
    publisher = "Openlogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdiskmaster"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "datadiskmaster"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "128"
  }

  os_profile {
    computer_name  = "osmaster"
    admin_username = "azureuser"
    admin_password = "password123"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${var.openshift_azure_ssh_key}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "osmastervmextension" {
  name                 = "osmastervmextension"
  count                = "${var.openshift_azure_master_vm_count}"
  location             = "${var.openshift_azure_region}"
  resource_group_name  = "${azurerm_resource_group.osrg.name}"
  depends_on           = ["azurerm_virtual_machine.osmastervm"]
  virtual_machine_name = "${azurerm_virtual_machine.osmastervm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [
            "https://raw.githubusercontent.com/julienstroheker/OpenShift-Azure-Terraform/master/scripts/masterPrep.sh", "https://raw.githubusercontent.com/julienstroheker/OpenShift-Azure-Terraform/master/scripts/deployOpenShift.sh"
        ],
        "commandToExecute": "bash masterPrep.sh ospvstorage567 azureuser && bash deployOpenShift.sh azureuser password123 ${var.openshift_azure_ssh_key} osmaster ${azurerm_public_ip.osmasterip.fqdn} ${azurerm_public_ip.osmasterip.ip_address} osinfra osnode 1 1 1 xip.io ${azurerm_storage_account.osstorage.name} ${azurerm_storage_account.osstorage.primary_access_key} ${var.azure_tenant_id} ${var.azure_subscription_id} ${var.azure_client_id} ${var.azure_client_secret} ${var.openshift_azure_resource_group} ${var.openshift_azure_region} ospvstorage567 ${azurerm_storage_account.osstorage.primary_access_key}"
    }
SETTINGS
}
