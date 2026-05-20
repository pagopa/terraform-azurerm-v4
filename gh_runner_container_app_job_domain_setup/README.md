# Domain setup for Azure Container App Job as GitHub Runners

This module creates and manages GitHub self-hosted runners as Azure Container App Jobs. It provisions federated identities for GitHub repositories, configures the required permissions, and sets up the infrastructure for runners to securely authenticate and deploy resources to Azure.

## How to use it

```hcl
module "gh_runner_job" {
  source = "github.com/pagopa/terraform-azurerm-v4//gh_runner_container_app_job_domain_setup"

  # Required variables
  domain_name         = "paymentoptions"
  env_short           = "p"
  environment_name    = "paymcloud-tools-cae"
  environment_rg      = "paymcloud-core-tools-rg"
  gh_repositories = [
    {
      name       = "pagopa-payment-options-service"
      short_name = "payopt"
    }
  ]
  gh_env              = "prod"
  job = {
    scale_max_executions = 5
    scale_min_executions = 0
  }
  key_vault = {
    name        = "paymcloud-kv"
    rg          = "paymcloud-sec-rg"
    secret_name = "gh-runner-job-pat"
  }
  prefix              = "pay"
  resource_group_name = azurerm_resource_group.identity_rg.name

  # Optional variables
  kubernetes_deploy = {
    enabled      = true          # optional
    namespaces   = ["payopt"]    # optional
    cluster_name = "paymcloud-eus-001-aks"  # optional
    rg           = "paymcloud-eus-001-aks-rg"  # optional
  }

  custom_rg_permissions = [     # optional
    {
      rg_name     = "my-app-rg"
      permissions = ["Contributor", "Reader"]
    }
  ]

  tags = var.tags
}
```

## Managing permissions

This module automatically manages Role-Based Access Control (RBAC) permissions for the GitHub runner identity across multiple Azure resources:

- **Subscription-level**: `Contributor` role for broad resource management
- **Container App Resource Group**: `Key Vault Reader` and `Reader` roles
- **Kubernetes (AKS)**: Configure via `kubernetes_deploy` to enable deployment to specific namespaces
- **Custom Resource Groups**: Configure via `custom_rg_permissions` for tailored access control

## Examples

### Basic Setup with AKS Access

```hcl
module "gh_runner_job" {
  source = "github.com/pagopa/terraform-azurerm-v4//gh_runner_container_app_job_domain_setup"

  domain_name         = "paymentoptions"
  env_short           = "p"
  environment_name    = azurerm_container_app_environment.cae.name
  environment_rg      = azurerm_resource_group.cae_rg.name
  gh_repositories = [
    {
      name       = "pagopa-payment-options-service"
      short_name = "payopt"
    },
    {
      name       = "pagopa-payment-auth-service"
      short_name = "payauth"
    }
  ]
  gh_env              = var.environment
  job = {
    scale_max_executions = 3
    scale_min_executions = 0
  }
  key_vault = {
    name        = azurerm_key_vault.gh_secrets.name
    rg          = azurerm_resource_group.secrets_rg.name
    secret_name = "gh-runner-pat"
  }
  prefix              = var.project_prefix
  resource_group_name = azurerm_resource_group.identities_rg.name

  kubernetes_deploy = {
    enabled      = true
    namespaces   = ["payment-services", "shared"]
    cluster_name = azurerm_kubernetes_cluster.aks.name
    rg           = azurerm_kubernetes_cluster.aks.resource_group_name
  }

  tags = var.tags
}
```

### Multi-Tier Setup with Custom Permissions

```hcl
module "gh_runner_job" {
  source = "github.com/pagopa/terraform-azurerm-v4//gh_runner_container_app_job_domain_setup"

  domain_name         = "core-services"
  env_short           = "p"
  environment_name    = azurerm_container_app_environment.cae.name
  environment_rg      = azurerm_resource_group.cae_rg.name
  gh_repositories = [
    {
      name       = "repository-1"
      short_name = "repo1"
    }
  ]
  gh_env              = "prod"
  job = {
    scale_max_executions = 2
  }
  key_vault = {
    name        = azurerm_key_vault.secrets.name
    rg          = azurerm_resource_group.security.name
    secret_name = "github-pat"
  }
  prefix              = "core"
  resource_group_name = azurerm_resource_group.identities.name

  custom_rg_permissions = [
    {
      rg_name     = azurerm_resource_group.app1.name
      permissions = ["Contributor"]
    },
    {
      rg_name     = azurerm_resource_group.app2.name
      permissions = ["Reader", "Monitoring Metrics Publisher"]
    }
  ]

  domain_security_rg_name = azurerm_resource_group.security.name  # optional
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}
```

## Notes

### Important Constraints

- **Repository Limit**: Maximum of 20 repositories per module instance. For more repositories, create additional module instances with different `gh_identity_suffix` values.
- **Naming Constraints**:
  - `prefix`: Max 6 characters (validated in variables)
  - `env_short`: Exactly 1 character (validated in variables)
  - Repository `short_name`: Max 15 characters (validated in variables)
- **Terraform Version**: Requires Terraform >= 1.9.0
- **Azure Provider**: Requires azurerm provider ~> 4

### Prerequisites

1. **GitHub Personal Access Token (PAT)**:
   - The PAT must be stored in the specified KeyVault with the secret name provided
   - Token must have appropriate scopes for runner registration (typically `admin:repo_hook`, `public_repo`, `workflow`)

2. **Azure Resources**:
   - Container App Environment must already exist
   - KeyVault containing the GitHub PAT must exist with appropriate access policies
   - Resource groups specified must exist
   - For AKS access, the cluster must exist and be accessible

3. **Permissions**:
   - Service principal deploying this module must have sufficient permissions to:
     - Create managed identities and federated credentials
     - Manage KeyVault access policies
     - Assign RBAC roles at subscription and resource group scopes
     - Create Kubernetes role bindings (when `kubernetes_deploy.enabled = true`)

### Multiple Repositories Configuration

When configuring more than 20 repositories, use the `gh_identity_suffix` variable to distinguish multiple module instances:

```hcl
module "gh_runner_job_batch_1" {
  # ... configuration ...
  gh_repositories = var.repositories[0:20]
  gh_identity_suffix = "01"
}

module "gh_runner_job_batch_2" {
  # ... configuration ...
  gh_repositories = var.repositories[20:40]
  gh_identity_suffix = "02"
}
```

### Scaling Configuration

The `job` variable controls container app job scaling:
- `scale_max_executions`: Maximum concurrent job replicas (default: 5)
- `scale_min_executions`: Minimum concurrent job replicas (default: 0)

Adjust these values based on your workload demands and resource availability.

### Container Image

The module uses a default GitHub runner image: `ghcr.io/pagopa/github-self-hosted-runner-azure:latest`. You can customize the image, CPU, and memory via the `container` variable if needed.



<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container_app_job"></a> [container\_app\_job](#module\_container\_app\_job) | ../container_app_job_gh_runner | n/a |
| <a name="module_identity_cd"></a> [identity\_cd](#module\_identity\_cd) | ../github_federated_identity | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_access_policy.gha_iac_managed_identities](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [null_resource.github_runner_app_permissions_to_namespace_cd](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_cluster) | data source |
| [azurerm_resource_group.gh_runner_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container"></a> [container](#input\_container) | Job Container configuration | <pre>object({<br/>    cpu    = number<br/>    memory = string<br/>    image  = string<br/>  })</pre> | <pre>{<br/>  "cpu": 0.5,<br/>  "image": "ghcr.io/pagopa/github-self-hosted-runner-azure:latest",<br/>  "memory": "1Gi"<br/>}</pre> | no |
| <a name="input_custom_rg_permissions"></a> [custom\_rg\_permissions](#input\_custom\_rg\_permissions) | (Optional) List of resource group permission assigned to the job identity | <pre>list(object({<br/>    # name of the resource group on which the permissions are given<br/>    rg_name = string<br/>    # list of permission assigned on with rg_name scope<br/>    permissions = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | (Required) Domain name for the configured repositories | `string` | n/a | yes |
| <a name="input_domain_security_rg_name"></a> [domain\_security\_rg\_name](#input\_domain\_security\_rg\_name) | (Optional) Security resource group name for the domain | `string` | `null` | no |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | Short environment prefix | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | (Required) Container App Environment configuration (Log Analytics Workspace) | `string` | n/a | yes |
| <a name="input_environment_rg"></a> [environment\_rg](#input\_environment\_rg) | (Required) Container App Environment configuration (Log Analytics Workspace) | `string` | n/a | yes |
| <a name="input_gh_env"></a> [gh\_env](#input\_gh\_env) | Github environment name | `string` | n/a | yes |
| <a name="input_gh_identity_suffix"></a> [gh\_identity\_suffix](#input\_gh\_identity\_suffix) | (Optional) Suffix used in the gh identity name. Necessary to distinguish the identities when more than 20 repos are used | `string` | `"01"` | no |
| <a name="input_gh_repositories"></a> [gh\_repositories](#input\_gh\_repositories) | (Required) List of gh repository names and short names on which the managed identity will have permission. Max 20 repos. All repos must belong to the same organization, check `job_meta` variable | <pre>list(object({<br/>    name       = string<br/>    short_name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_identity_rg_name"></a> [identity\_rg\_name](#input\_identity\_rg\_name) | Resource group name where the identity will be created | `string` | `null` | no |
| <a name="input_identity_role"></a> [identity\_role](#input\_identity\_role) | Identity role should be either ci or cd | `string` | `"cd"` | no |
| <a name="input_job"></a> [job](#input\_job) | Container App job scaling configuration | <pre>object({<br/>    scale_max_executions = optional(number, 5)<br/>    scale_min_executions = optional(number, 0)<br/>  })</pre> | n/a | yes |
| <a name="input_job_meta"></a> [job\_meta](#input\_job\_meta) | Scaling rules metadata. | <pre>object({<br/>    repo_owner                   = optional(string, "pagopa")<br/>    runner_scope                 = optional(string, "repo")<br/>    target_workflow_queue_length = optional(string, "1")<br/>    github_runner                = optional(string, "https://api.github.com")<br/>  })</pre> | <pre>{<br/>  "github_runner": "https://api.github.com",<br/>  "repo_owner": "pagopa",<br/>  "runner_scope": "repo",<br/>  "target_workflow_queue_length": "1"<br/>}</pre> | no |
| <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault) | (Required) KeyVault configuration containing the GitHub PAT (Personal Access Token) used for runner authentication | <pre>object({<br/>    name        = string # Name of the KeyVault which stores PAT as secret<br/>    rg          = string # Resource group of the KeyVault which stores PAT as secret<br/>    secret_name = string # Data of the KeyVault which stores PAT as secret<br/>  })</pre> | n/a | yes |
| <a name="input_kubernetes_deploy"></a> [kubernetes\_deploy](#input\_kubernetes\_deploy) | (Optional) Enables and specifies the kubernetes deploy permissions | <pre>object({<br/>    # enables the permission handling for AKS deploy<br/>    enabled = optional(bool, false)<br/>    # list of namespaces where this identity will be able to operate<br/>    namespaces = optional(list(string), [])<br/>    # AKS cluster name<br/>    cluster_name = optional(string, "")<br/>    # AKS cluster rg name<br/>    rg = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "cluster_name": "",<br/>  "enabled": false,<br/>  "namespaces": [],<br/>  "rg": ""<br/>}</pre> | no |
| <a name="input_parallelism"></a> [parallelism](#input\_parallelism) | (Optional) Number of parallel replicas of a job that can run at a given time. | `number` | `1` | no |
| <a name="input_polling_interval_in_seconds"></a> [polling\_interval\_in\_seconds](#input\_polling\_interval\_in\_seconds) | (Optional) Interval to check each event source in seconds. | `number` | `30` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Project prefix | `string` | n/a | yes |
| <a name="input_replica_completion_count"></a> [replica\_completion\_count](#input\_replica\_completion\_count) | (Optional) Minimum number of successful replica completions before overall job completion. | `number` | `1` | no |
| <a name="input_replica_retry_limit"></a> [replica\_retry\_limit](#input\_replica\_retry\_limit) | (Optional) The maximum number of times a replica is allowed to retry. | `number` | `1` | no |
| <a name="input_replica_timeout_in_seconds"></a> [replica\_timeout\_in\_seconds](#input\_replica\_timeout\_in\_seconds) | (Required) The maximum number of seconds a replica is allowed to run. | `number` | `1800` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_runner_labels"></a> [runner\_labels](#input\_runner\_labels) | Labels that allow a GH action to call a specific runner | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for new resources | `map(any)` | <pre>{<br/>  "CreatedBy": "Terraform"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

