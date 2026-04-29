# Terraform Development Instructions

## Overview
This file provides custom instructions for Terraform development within this repository.

## Key Guidelines

### Terraform Best Practices
- Use `terraform fmt` to format all Terraform code
- Follow naming conventions: use `snake_case` for all identifiers
- Always include `description` and `sensitive` attributes for variables
- Use `dynamic` blocks sparingly; prefer explicit configurations
- Validate code with `terraform validate` and `terraform plan`

### Module Structure
- Each module should have: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- Include comprehensive README.md with provider requirements and variable documentation
- Use `terraform-docs` to auto-generate documentation
- Keep modules focused on a single Azure resource type or logical grouping

### Code Quality
- Add validation blocks to variables when appropriate
- Use `try()` function for optional nested attributes
- Implement proper error handling with explicit `null` checks
- Document non-obvious logic with inline comments

### Testing
- Use `terraform console` for quick testing
- Run `terraform init`, `terraform validate`, and `terraform plan` before committing
- Test variable combinations and edge cases

## When Modifying Modules
1. Update variable descriptions if changing behavior
2. Run `terraform fmt` on all modified files
3. Update README.md with any new variables or outputs
4. Include examples of common usage patterns

## Common Commands
```bash
terraform fmt -recursive          # Format all .tf files
terraform validate               # Validate configuration
terraform plan -out=tfplan       # Create execution plan
terraform apply tfplan           # Apply changes
```
