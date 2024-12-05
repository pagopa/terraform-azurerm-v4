# Migration from azurerm v3

In version 4.0 of the Azure Provider, it's now required to specify the Azure Subscription ID when configuring a provider instance in your configuration. This can be done by specifying the `subscription_id` provider property, or by exporting the `ARM_SUBSCRIPTION_ID` environment variable. For example:

Specify the subscription ID in the provider block:

```hcl
provider "azurerm" {
  subscription_id = "00000000-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Specify the subscription ID using an environment variable:

```sh
# Bash etc.
export ARM_SUBSCRIPTION_ID=00000000-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

```powershell
# PowerShell
[System.Environment]::SetEnvironmentVariable('ARM_SUBSCRIPTION_ID', '00000000-xxxx-xxxx-xxxx-xxxxxxxxxxxx', [System.EnvironmentVariableTarget]::User)
```

More information can be found in the [official documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide).
