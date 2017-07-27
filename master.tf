resource "azurerm_availability_set" "osmasteras" {
  name                = "${var.openshift_azure_resource_prefix}-as-master-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osmasternic" {
  name                = "${var.openshift_azure_resource_prefix}-nic-master-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = "${azurerm_subnet.osmastersubnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "osmasterip" {
  name                         = "${var.openshift_azure_resource_prefix}-vip-master-${var.openshift_azure_resource_suffix}"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${azurerm_resource_group.osrg.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.openshift_azure_resource_group}"
}

resource "azurerm_lb" "osmasterlb" {
  name                = "${var.openshift_azure_resource_prefix}-nlb-master-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osmasterip.id}"
  }
}

resource "azurerm_virtual_machine" "osmastervm" {
  name                  = "${var.openshift_azure_resource_prefix}-vm-master-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
  count                 = "${var.openshift_azure_master_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${azurerm_network_interface.osmasternic.id}"]
  availability_set_id   = "${azurerm_availability_set.osmasteras.id}"
  vm_size               = "${var.openshift_azure_master_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_azure_vm_os["publisher"]}"
    offer     = "${var.openshift_azure_vm_os["offer"]}"
    sku       = "${var.openshift_azure_vm_os["sku"]}"
    version   = "${var.openshift_azure_vm_os["version"]}"
  }

  storage_os_disk {
    name              = "osdiskmaster"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.openshift_azure_resource_prefix}-vm-master-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
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
        "commandToExecute": "bash masterPrep.sh && bash deployOpenShift.sh azureuser \
        password123 \
        ${var.openshift_azure_ssh_key} \
        osmaster \
        ${azurerm_public_ip.osmasterip.fqdn} \
        ${azurerm_public_ip.osmasterip.ip_address} \
        osinfra \
        osnode \
        1 \
        1 \
        1 \
        xip.io \
        ${azurerm_storage_account.osstorage.name} \
        ${azurerm_storage_account.osstorage.primary_access_key} \
        ${var.azure_tenant_id} \
        ${var.azure_subscription_id} \
        ${var.azure_client_id} \
        ${var.azure_client_secret} \
        ${var.openshift_azure_resource_group} \
        ${var.openshift_azure_region} \
        ospvstorage567 \
        ${azurerm_storage_account.osstorage.primary_access_key}"
    }
SETTINGS
}
