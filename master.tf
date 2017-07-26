resource "azurerm_availability_set" "osmasteras" {
  name                = "osmasteras"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"
}

resource "azurerm_virtual_network" "osmastervnet" {
  name                = "osmastervnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"
}

resource "azurerm_subnet" "osmastersubnet" {
  name                 = "osmastersubnet"
  resource_group_name  = "${var.openshift_azure_resource_group}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "osmasternic" {
  name                = "osmasternic"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = "${azurerm_subnet.osmastersubnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "osmasterip" {
  name                         = "osmasterip"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${var.openshift_azure_resource_group}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.openshift_master_dns_name}"
}

resource "azurerm_lb" "osmasterlb" {
  name                = "osmasterlb"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${var.openshift_azure_resource_group}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osmasterip.id}"
  }
}

resource "azurerm_virtual_machine" "osmastervm" {
  name                  = "osmastervm"
  count                 = "${var.openshift_azure_master_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${var.openshift_azure_resource_group}"
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
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "osmaster"
    admin_username = "azureuser"
    admin_password = "password123"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys                        = "${var.openshift_azure_ssh_keys}"
  }
}

resource "azurerm_virtual_machine_extension" "osmastervmextension" {
  name                 = "osmastervmextension"
  count                = "${var.openshift_azure_master_vm_count}"
  location             = "${var.openshift_azure_region}"
  resource_group_name  = "${var.openshift_azure_resource_group}"
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
        ${var.openshift_azure_ssh_keys} \
        osmaster \
        ${azurerm_public_ip.osmasterip.fqdn} \
        ${azurerm_public_ip.osmasterip.ip} \
        osinfra \
        osnode \
        1 \
        1 \
        1 \
        xip.io \
        ${azurerm_storage_account.osstorage.name} \
        ${azurerm_storage_account.osstorage.primary_access_key} \
        ${env.ARM_TENANT_ID} \
        ${env.ARM_SUBSCRIPTION_ID} \
        ${env.ARM_CLIENT_ID} \
        ${env.ARM_CLIENT_SECRET} \
        ${var.openshift_azure_resource_group} \
        ${var.openshift_azure_region} \
        ospvstorage567 \
        ${azurerm_storage_account.osstorage.primary_access_key}"
    }
SETTINGS
}
