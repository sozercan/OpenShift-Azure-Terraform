provider "azurerm" {
  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

resource "azurerm_resource_group" "osrg" {
  name     = "${var.openshift_azure_resource_group}"
  location = "${var.openshift_azure_region}"
}

resource "random_id" "randomId" {
  byte_length = 4
}

resource "azurerm_storage_account" "osstorage" {
  name                = "osregistry${random_id.randomId.hex}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  location     = "${var.openshift_azure_region}"
  account_type = "Standard_LRS"
}
