### Create a Client ID / Secret using the Azure CLI 2.0

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

### Create a Client ID / Password using Docker

You just have to run the following command :

docker run -it julienstroheker/add-azure-spn <NameApp> <PasswordApp>

For example :

```$ docker run -it julienstroheker/add-azure-spn MyAwesomeApplication MyAw3s0meP@ssw0rd!```

After less than 1 minute, you will have a nice output like this, ready to be copy and paste :

```
================== Informations about your new App ==============================
Subscription ID                    XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX
Subscription Name                  Your Subscription Name
Service Principal Client ID:       XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX
Service Principal Key:             YourPasswordOrGeneratingARandomOne
Tenant ID:                         XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXX
=================================================================================
```