# Azure Container App Job as GitHub Runners

This module creates the infrastructure to host GitHub self hosted runners using Azure Container Apps jobs and can be used by GitHub repositories which need access to private resources on Azure.

- [Azure Container App Job as GitHub Runners](#azure-container-app-job-as-github-runners)
  - [How to use it](#how-to-use-it)
    - [Requirements](#requirements)
    - [What the module does](#what-the-module-does)
    - [Example](#example)
  - [Design](#design)
    - [Notes](#notes)
  - [Requirements](#requirements-1)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

## How to use it

### Requirements

Before using the module, developer needs the following existing resources:

- a Container App Environment provisioned in a resource group named `<prefix>-<short_env>-github-runner-rg`
- a VNet
- a KeyVault
- a Log Analytics Workspace
- a secret in the mentioned KeyVault containing a GitHub PAT with access to the desired repos
  - PATs can be generated using [`bot` GitHub users](https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/466716501/Github+-+bots+for+projects). An Admin must approve the request
  - PATs have an expiration date
  - PAT must have [these permissions](https://keda.sh/docs/2.12/scalers/github-runner/#setting-up-the-github-app) on selected repositories

### What the module does

The module creates:

- a Container App job with the name `<prefix>-<short_env>-github-runner-job` on the specified Container App Environment
- a role assignment to allow the Container App Job to read secrets from the existing KeyVault (`Get` permission over KeyVault's secrets access policies)

### Input variables

Use `environment` and `key_vault` to specify name and resource group name of the Container App Environment and the KeyVault to use.
`container` variable is optional but useful to customize the container properties such as CPU and memory limits and the container's image.
Use `job` variable to specify target repository and optionally customize scaling rules.

### Example

Give a try to the example saved in `terraform-azurerm-v3/container_app_job_gh_runner/tests` to see a working demo of this module.

## Design

A Container App Job scales containers (jobs) based on event-driven rules (KEDA). A Container App Job might have multiple containers, each of them with different properties (VM size, secrets, images, volumes, etc.).
To support GitHub Actions, you need to use `github-runner` [scale rule](https://keda.sh/docs/2.12/scalers/github-runner/) with these metadata:

- owner: `pagopa`
- runnerScope: `repo`
  - most tighten
- repos: *the repository* you want to support
  - it supports multiple repositories but this module is designed to have a 1:1 match between containers and repositories
- targetWorkflowQueueLength: `1`
  - indicates how many job requests are necessary to trigger the container

With the above settings, the scale rules start to poll the GitHub repositories (be careful to quota limits). You can reduce the polling interval by using `polling_interval` module's variable. It defaults to 30 seconds.

Containers needs these environment variables to connect to GitHub, [grab a registration token and register themself as runners](https://github.com/pagopa/github-self-hosted-runner-azure/blob/main/github-runner-entrypoint.sh):

- GITHUB_PAT: reference to the KeyVault secret (no Kubernetes secrets are used)
- REPO_URL: GitHub repo URL
- REGISTRATION_TOKEN_API_URL: [GitHub API](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository) to get the registration token

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app_job.container_app_job](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_key_vault_access_policy.keyvault_containerapp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_container_app_environment.container_app_environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_app_environment) | data source |
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.github_pat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_resource_group.rg_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container"></a> [container](#input\_container) | Job Container configuration | <pre>object({<br/>    cpu    = number<br/>    memory = string<br/>    image  = string<br/>  })</pre> | <pre>{<br/>  "cpu": 0.5,<br/>  "image": "ghcr.io/pagopa/github-self-hosted-runner-azure:latest",<br/>  "memory": "1Gi"<br/>}</pre> | no |
| <a name="input_env_short"></a> [env\_short](#input\_env\_short) | Short environment prefix | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | (Required) Container App Environment configuration (Log Analytics Workspace) | `string` | n/a | yes |
| <a name="input_environment_rg"></a> [environment\_rg](#input\_environment\_rg) | (Required) Container App Environment configuration (Log Analytics Workspace) | `string` | n/a | yes |
| <a name="input_job"></a> [job](#input\_job) | Container App job configuration | <pre>object({<br/>    name                 = string<br/>    scale_max_executions = optional(number, 5)<br/>    scale_min_executions = optional(number, 0)<br/>  })</pre> | n/a | yes |
| <a name="input_job_meta"></a> [job\_meta](#input\_job\_meta) | Scaling rules metadata. | <pre>object({<br/>    repo                         = string<br/>    repo_owner                   = optional(string, "pagopa")<br/>    runner_scope                 = optional(string, "repo")<br/>    target_workflow_queue_length = optional(string, "1")<br/>    github_runner                = optional(string, "https://api.github.com") #<br/>  })</pre> | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the KeyVault which stores PAT as secret | `string` | n/a | yes |
| <a name="input_key_vault_rg"></a> [key\_vault\_rg](#input\_key\_vault\_rg) | Resource group of the KeyVault which stores PAT as secret | `string` | n/a | yes |
| <a name="input_key_vault_secret_name"></a> [key\_vault\_secret\_name](#input\_key\_vault\_secret\_name) | Data of the KeyVault which stores PAT as secret | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Resource group and resources location | `string` | n/a | yes |
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

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Container App job id |
| <a name="output_name"></a> [name](#output\_name) | Container App job name |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Container App job resource group name |
<!-- END_TF_DOCS -->
