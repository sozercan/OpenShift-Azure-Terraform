# Create a Service Principal for your Subscription

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

* Login with the [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

```bash
 az login
```

* After a succesfull login, you will get a list of all the subscriptions related to your account.

```bash
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
```

* Store the subscription ID from the default subsciption.

```bash
export SUBSCRIPTIONID=`az account show --output tsv | cut -f2`
```

* Create a Service Principal as a contributor to your Subscription

```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTIONID}"
```

* Store Service Principal, you will use it in your tfvars file.

```json
{
  "appId": "23xxxxx-xxxx-xxxx-xxxx-7e83xxxb1",
  "displayName": "azure-cli-2017-07-31-xx-xx-xx",
  "name": "http://azure-cli-2017-07-31-xx-xx-xx",
  "password": "1219e938-72ad-439c-xxx-517ab8b60xxx",
  "tenant": "72f988bf-xxxx-xxxx-xxxx-2d7cd011db47"
}
```

Now, you can fill up your `terraform.tfvars`

```csharp
azure_client_id => appId
azure_client_secret => password
azure_tenant_id => tenant
azure_subscription_id => SUBSCRIPTIONID
```

*NOTE: A more detailed overview can be found on the [Terraform Site](https://www.terraform.io/docs/providers/azurerm/index.html)*

### Create a Client ID / Password using Docker

You just have to run the following command :

```docker run -it julienstroheker/add-azure-spn <NameApp> <PasswordApp>```

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