resource "azurerm_resource_group" "os" {
  name     = "osrg"
  location = "${var.openshift_azure_region}"
}
