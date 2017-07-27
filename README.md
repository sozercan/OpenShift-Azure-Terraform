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

* The values for the above environment variables can be obtained through the Azure CLI commands below.

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

```bash
$ az login
```

* Run the following commands. This will print 2 lines, the first is the tenant ID and the second is the subscription ID.

```bash
$ az account show

{
  "environmentName": "AzureCloud",
  "id": "a97d7ca2-18ca-426f-b7c4-1a2cdaa4d9d1",
  "isDefault": true,
  "name": "My_Azure_Subscription",
  "state": "Enabled",
  "tenantId": "34a934ff-86a1-34af-34cd-2d7cd0134bd34",
  "user": {
    "name": "juliens@microsoft.com",
    "type": "user"
  }
}

export SUBSCRIPTIONID=`az account show --output tsv | cut -f2`

```

* Create an Azure application 

```bash
$ export PASSWORD=`openssl rand -base64 24`

$ az ad app create --display-name osterraform--identifier-uris http://docs.mesosphere.com --homepage http://www.mesosphere.com --password $PASSWORD

$ unset PASSWORD
```

* Create A Service Principal

```bash
$ APPID=`az ad app list --display-name osterraform -o tsv --out tsv | grep os | cut -f1`

$ az ad sp create --id $APPID
```

* Grant Permissions To Your Application

```bash
$ az role assignment create --assignee http://docs.mesosphere.com --role "Owner" --scope /subscriptions/$SUBSCRIPTIONID

```

* Print the Client ID

```bash
$ az ad app list --display-name osterraform
```

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

## Deploy the Azure infrastructure and DC/OS

* First, review the default configuratiion. Most common options are available in `terraform.tfvars`. The full list of available options are in `config.tf`. CentOS is the default as it has pre-requirements built in.

* Update `terraform.tfvars` with the path to your passwordless SSH public and private keys.

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
### Connection to the cluster

* Initiate a SSH tunnel to `<masterVIP>.<location>.cloudapp.azure.com` and you should be able to reach the DC/OS UI.
```bash
$ sudo ssh <userName>@<masterVIP>.<location>.cloudapp.azure.com -p 2200 -k <sshPrivateKey>
```
* The default username/password is `ocpadmin/Passw0rd`.

## ADDITIONAL ##

### Cleanup ###

To restart and cleanup the Azure assets run the following commands from the <repo> directory

```bash
$ az group delete osterraform
info:    Executing command group delete
Delete resource group osterraform? [y/n] y
+ Deleting resource group osterraform                                        
info:    group delete command OK

$ cd <repo> && rm *terraform.tfstate

```

### Troubleshooting ###

If the deployment gets in an inconsistent state (repeated `terraform apply` commands fail, or output references to leases that no longer exist), you may need to manually reconcile. Destroy the `<osterrform>` resource group, run `terraform remote config -disable` and delete all `terraform.tfstate*` files from `os`, follow the above instructions again.