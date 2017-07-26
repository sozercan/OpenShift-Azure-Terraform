variable "openshift_azure_resource_group" {
  type        = "string"
  description = "Azure resource group"
  default     = "osrg"
}

variable "openshift_azure_region" {
  type        = "string"
  description = "Azure region for deployment"
  default     = "East US"
}
