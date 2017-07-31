# OpenShift-Azure-Terraform
Deploy OpenShift 1.5.1 on Azure using Terraform and Ansible
==================

This script allow you to deploy an OpenShift 1.5.1 in best practices on Microsoft Azure.

# Terraform Usage #

#### WARNING: Be sure that you are not overriding existing Azure resources that are in use. This Terraform process will create a resource group to contain all dependent resources within. This makes it easy to cleanup.

#### NOTE: This deployment is not meant to obviate the need to understand the install process or read the docs. Please spend some time to understand both [OpenShift](https://www.openshift.com/) and the [install process](https://install.openshift.com/).

## Preperation Steps ##

* It is assumed that you have a functioning Azure client installed. You can do so [here](https://github.com/Azure/azure-cli)

* Install [Terraform](https://www.terraform.io/downloads.html) and create credentials for Terraform to access Azure. To do so, you will need to following environment variables :

  * ARM_SUBSCRIPTION_ID=<subscription id>
  * ARM_CLIENT_ID=<client id>
  * ARM_CLIENT_SECRET=<cient secret>
  * ARM_TENANT_ID=<tenant id>

* You can also fill the following values in the tfvars file if you prefeer.

* The values for the above environment variables can be obtained through the Azure CLI. 

[Click here to get the step by step about it](/docs/CreateAzureSpn.md)

## Deploy the Azure infrastructure and OpenShift

* First rename the `terraform.tfvars.example` to `terraform.tfvars` and review the default configuration. Most common options are available inside. The full list of available options are in `config.tf`. CentOS is the default as it has pre-requirements built in.

* Update `terraform.tfvars` with the path to your passwordless SSH public and private keys. (openshift_azure_public_key and openshift_azure_private_key)

* Change `openshift_azure_resource_prefix` (and optionally `openshift_azure_resource_suffix`) to something unique

* Optionally, customize the `openshift_azure_master_vm_count` (default 1), the `openshift_azure_node_vm_count` (default 1) and `openshift_azure_infra_vm_count` for master (default 1), the agents size is Standard_D2_V2 per default, but you can change it for your need.

* Create the OpenShift cluster by executing:
```bash
$ EXPORT ARM_SUBSCRIPTION_ID=<your subscription id>
$ EXPORT ARM_CLIENT_ID=<your client id>
$ EXPORT ARM_CLIENT_SECRET=<your cient secret>
$ EXPORT ARM_TENANT_ID=<your tenant id>

$ cd <repo> && terraform apply
```
### Connection to console

After your deployment your should be able to reach the OS console 

```https://<masterFQDN>.<location>.cloudapp.azure.com:8443/console```

The cluster will use self-signed certificates. Accept the warning and proceed to the login page.

* If you didn't change it, the default username/password is `ocpadmin/password123`.

## ADDITIONAL ##

### Cleanup ###

To restart and cleanup the Azure assets run the following commands from the <repo> directory

```bash
$ az group delete <yourResourceGroup>
info:    Executing command group delete
Delete resource group <yourResourceGroup>? [y/n] y
+ Deleting resource group <yourResourceGroup>                                        
info:    group delete command OK

$ cd <repo> && rm *terraform.tfstate

```

### Troubleshooting ###

If the deployment gets in an inconsistent state (repeated `terraform apply` commands fail, or output references to leases that no longer exist), you may need to manually reconcile. Destroy the `<yourResourceGroup>` resource group, run `terraform remote config -disable` and delete all `terraform.tfstate*` files from `os`, follow the above instructions again.

* You could also check this repo : [Microsoft/openshift-origin](https://github.com/Microsoft/openshift-origin) to get more informations