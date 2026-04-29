# Module Development Instructions

## Overview
Guidelines for developing, maintaining, and documenting Terraform modules in the IDH folder of this repository only.

## IDH Module Creation Checklist

### File Structure
- [ ] Create module directory: `IDH/modulename/`
- [ ] Create `main.tf` with resource definitions
- [ ] Create `variables.tf` with input variables
- [ ] Create `outputs.tf` with resource outputs
- [ ] Create `versions.tf` with provider requirements
- [ ] Create `locals.tf` with local values if needed
- [ ] Create `README.md` with full documentation
- [ ] Create `modulename.yml` file in `IDH/00_product_configs/common` with a basic configuration for the module
- [ ] If a subnet is needed, allow the user to optionally create an embedded subnet within the module, but require that either the embedded subnet or an external subnet is provided (mutually exclusive variables)
- [ ] When creating alerts for a resource, expect a list of action groups as input variables, and use `for_each` to create the alert rules. This allows for greater flexibility and scalability in alert configuration.


### Variable Definition Standards
- [ ] All variables have `description` attribute
- [ ] Sensitive variables marked with `sensitive = true`
- [ ] Required variables have no `default` value
- [ ] Optional variables include sensible `default` values
- [ ] Include `validation` blocks for restricted values
- [ ] Include `validation` blocks for mutually exclusive variables
- [ ] Add `nullable = false` for required inputs
- [ ] Include `idh_resource_tier` variable with description linking to LIBRARY.md for available tiers
- [ ] Allow variable controlled parameters only for parameters that can change 

### Output Definition Standards
- [ ] All outputs have `description` attribute
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] Include all important resource properties
- [ ] Output resource IDs for dependency management


### README.md Documentation
Include the following sections:
1. **Overview** - What the module does
2. **IDH resources available** -  link to LIBRARY.md for details on available tiers as documented below 
3. **Examples** - Common usage patterns
4. **Notes** - Limitations, special considerations
5. **Troubleshooting** - Common issues and solutions

Never update the README below the auto-generated section beginning with `<!-- BEGIN_TF_DOCS -->`

### Code Quality Standards
- [ ] Run `git ls-files -- . | xargs pre-commit run --files` in the module folder
- [ ] Include helpful comments for complex logic
- [ ] Use meaningful variable and resource names
- [ ] Follow DRY principle; avoid duplication
- [ ] Use `count` or `for_each` for multiple resources
- [ ] Handle null/optional inputs gracefully with `try()` or conditionals

### Testing Before Commit
- [ ] README is accurate and up-to-date; use terraform-doc-validator agent to very the documentation
- [ ] Example code is current and functional

## Versioning
- Document breaking changes in release notes
- Maintain backward compatibility when possible
- Mark deprecated functionality clearly

## Common Patterns

### IDH library reference
Use this fragment to write the "IDH resources available" section in the README.md of the module
```markdown
## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource_tier` available for this module
```

### Optional Resources
Use `count` to conditionally create resources:
```hcl
resource "azurerm_resource" "example" {
  count = var.enabled ? 1 : 0
  # configuration...
}
```

### Dynamic Configurations
Use `dynamic` blocks for optional nested attributes:
```hcl
dynamic "setting" {
  for_each = var.settings != null ? [var.settings] : []
  content {
    key   = setting.value.key
    value = setting.value.value
  }
}
```

### Outputs for Dependencies
Always export resource IDs for use by other modules:
```hcl
output "resource_id" {
  description = "The ID of the created resource"
  value       = azurerm_resource.example.id
}
```

### Embedded subnet
Use this fragment when defining the embedded_subnet variable for modules that require a subnet
This can be extended with additional properties and validations as needed
```hcl
variable "embedded_subnet" {
  type = object({
    enabled      = bool
    vnet_name    = optional(string, null)
    vnet_rg_name = optional(string, null)
  })
  description = "(Optional) Configuration for creating an embedded Subnet for the EventHub private endpoint. When enabled, 'private_endpoint.subnet_id' must be null."
  default = {
    enabled      = false
    vnet_name    = null
    vnet_rg_name = null
  }
  
  validation {
    condition     = var.embedded_subnet.enabled ? (var.embedded_subnet.vnet_name != null && var.embedded_subnet.vnet_rg_name != null) : true
    error_message = "If 'embedded_subnet' is enabled, both 'vnet_name' and 'vnet_rg_name' must be provided."
  }
}
  ```

## Maintenance Tasks
- Regular dependency updates for providers
- Audit for deprecated resource types
- Review examples for accuracy
- Test with new Azure provider versions
- Document any provider version constraints
