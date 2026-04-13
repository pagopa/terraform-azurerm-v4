# Module Development Instructions

## Overview
Guidelines for developing, maintaining, and documenting Terraform modules in this repository.

## Module Creation Checklist

### File Structure
- [ ] Create module directory: `modulename/`
- [ ] Create `main.tf` with resource definitions
- [ ] Create `variables.tf` with input variables
- [ ] Create `outputs.tf` with resource outputs
- [ ] Create `versions.tf` with provider requirements
- [ ] Create `README.md` with full documentation
- [ ] Add `.gitignore` if needed
- [ ] Include `test/` subdirectory with usage examples

### Variable Definition Standards
- [ ] All variables have `description` attribute
- [ ] Sensitive variables marked with `sensitive = true`
- [ ] Required variables have no `default` value
- [ ] Optional variables include sensible `default` values
- [ ] Include `validation` blocks for restricted values
- [ ] Include `validation` blocks for mutually exclusive variables
- [ ] Add `nullable = false` for required inputs

### Output Definition Standards
- [ ] All outputs have `description` attribute
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] Include all important resource properties
- [ ] Output resource IDs for dependency management


### README.md Documentation
Include the following sections:
1. **Overview** - What the module does
2. **IDH resources available** - only for IDH modules, link to LIBRARY.md for details on available tiers
3. **Examples** - Common usage patterns
4. **Notes** - Limitations, special considerations
5. **Troubleshooting** - Common issues and solutions

Never update the README below the auto-generated section beginning with `<!-- BEGIN_TF_DOCS -->`

### Code Quality Standards
- [ ] Run `terraform fmt` on all files
- [ ] Run `terraform validate` successfully
- [ ] Include helpful comments for complex logic
- [ ] Use meaningful variable and resource names
- [ ] Follow DRY principle; avoid duplication
- [ ] Use `count` or `for_each` for multiple resources
- [ ] Handle null/optional inputs gracefully with `try()` or conditionals

### Testing Before Commit
- [ ] `terraform init` completes without errors
- [ ] `terraform validate` passes
- [ ] `terraform fmt` doesn't suggest changes
- [ ] README is accurate and up-to-date; use terraform-doc-validator agent to very the documentation
- [ ] Example code is current and functional

## Versioning
- Follow semantic versioning in git tags
- Document breaking changes in release notes
- Maintain backward compatibility when possible
- Mark deprecated functionality clearly

## Common Patterns

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

## Maintenance Tasks
- Regular dependency updates for providers
- Audit for deprecated resource types
- Review examples for accuracy
- Test with new Azure provider versions
- Document any provider version constraints
