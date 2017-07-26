provider "azurerm" {}

resource "azurerm_resource_group" "osrg" {
  name     = "${var.openshift_azure_resource_group}"
  location = "${var.openshift_azure_region}"
}

resource "azurerm_storage_account" "osstorage" {
  name                = "osregistry987"
  resource_group_name = "${var.openshift_azure_resource_group}"

  location     = "${var.openshift_azure_region}"
  account_type = "Standard_LRS"
}
