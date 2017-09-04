variable "azure_client_id" {
  type        = "string"
  description = "Azure Client ID"
  default     = ""
}

variable "azure_client_secret" {
  type        = "string"
  description = "Azure Client Secret"
  default     = ""
}

variable "azure_tenant_id" {
  type        = "string"
  description = "Azure Tenant ID"
  default     = ""
}

variable "azure_subscription_id" {
  type        = "string"
  description = "Azure Subscription ID"
  default     = ""
}

variable "openshift_azure_resource_prefix" {
  type        = "string"
  description = "Prefix for all the resources"
  default     = "os"
}

variable "openshift_azure_resource_suffix" {
  type        = "string"
  description = "Suffix for all the resources"
  default     = "tf"
}

variable "openshift_azure_resource_group" {
  type        = "string"
  description = "Azure resource group"
  default     = "azure"
}

variable "openshift_azure_region" {
  type        = "string"
  description = "Azure region for deployment"
  default     = "East US"
}

variable "openshift_azure_public_key" {
  type        = "string"
  description = "SSH Public key"
  default     = ""
}

variable "openshift_azure_private_key" {
  type        = "string"
  description = "SSH Private key"
  default     = ""
}

variable "openshift_azure_master_vm_count" {
  description = "Master VM count"
  default     = 1
}

variable "openshift_azure_infra_vm_count" {
  description = "Infra VM count"
  default     = 1
}

variable "openshift_azure_node_vm_count" {
  description = "Node VM count"
  default     = 1
}

variable "openshift_azure_master_vm_size" {
  type        = "string"
  description = "Master VM size"
  default     = "Standard_DS2_v2"
}

variable "openshift_azure_infra_vm_size" {
  type        = "string"
  description = "Infra VM size"
  default     = "Standard_DS2_v2"
}

variable "openshift_azure_node_vm_size" {
  type        = "string"
  description = "Node VM size"
  default     = "Standard_DS2_v2"
}

variable "openshift_azure_data_disk_size" {
  description = "Size of Datadisk in GB for Docker volume"
  default     = 128
}

variable "openshift_azure_vm_os" {
  type = "map"

  default = {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }
}

variable "openshift_azure_vm_username" {
  type        = "string"
  description = "VM Username"
  default     = "ocpadmin"
}

variable "openshift_master_dns_name" {
  type        = "string"
  description = "DNS prefix name for the master"
  default     = "osmaster"
}

variable "openshift_infra_dns_name" {
  type        = "string"
  description = "DNS prefix name for the infra"
  default     = "osinfra"
}

variable "openshift_initial_password" {
  type        = "string"
  description = "initial password for OpenShift"
  default     = "password123"
}

variable "openshift_azure_default_subdomain" {
  type        = "string"
  description = "The wildcard DNS name you would like to use for routing"
  default     = "xip.io"
}

variable "openshift_azure_master_prep_script" {
  type        = "string"
  description = "URL for Master Prep script"
  default     = "https://raw.githubusercontent.com/sozercan/OpenShift-Azure-Terraform/master/scripts/masterPrep.sh"
}

variable "openshift_azure_node_prep_script" {
  type        = "string"
  description = "URL for Node Prep script"
  default     = "https://raw.githubusercontent.com/sozercan/OpenShift-Azure-Terraform/master/scripts/nodePrep.sh"
}

variable "openshift_azure_deploy_openshift_script" {
  type        = "string"
  description = "URL for Deploy Openshift script"
  default     = "https://raw.githubusercontent.com/sozercan/OpenShift-Azure-Terraform/master/scripts/deployOpenShift.sh"
}

variable "openshift_ansible_url" {
  type        = "string"
  description = "URL for openshift-ansible repo"
  default     = "https://github.com/openshift/openshift-ansible.git"
}

variable "openshift_ansible_branch" {
  type        = "string"
  description = "Branch of the openshift-ansible repo"
  default     = "master"
}