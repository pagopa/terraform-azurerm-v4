# Copilot Instructions for terraform-azurerm-v4

## Repository Overview
Production-ready Terraform modules for Azure resources using the azurerm provider. Two layered approach:
- **v4 Modules** (root level): Low-level, highly configurable modules wrapping individual Azure resources or logical groupings
- **IDH Modules** (`/IDH`): Simplified, pre-configured modules for common use cases with environment/tier-specific defaults

## Architecture

### Module Organization
```
module_name/
├── main.tf              # Resource definitions (may reference other modules)
├── variables.tf         # Input variables with defaults and validation
├── outputs.tf           # Resource properties exported for downstream use
├── versions.tf          # Provider requirements (terraform, azurerm version)
├── README.md            # Generated documentation (auto-synced by pre-commit)
└── tests/               # Optional Terraform test configurations showing module usage
    ├── main.tf
    ├── variables.tf
    └── terraform.sh    # Script to run tests
```

### Key Design Patterns
- **Dynamic blocks** for optional nested resources: `for_each = condition ? ["dummy"] : []`
- **Variables with `try()`** for optional properties to avoid errors when nested attributes don't exist
- **SystemAssigned identities** preferred over managed credentials where possible
- **Outputs export full resource IDs**, not just names (enables dependency chaining)
- **Test folders** (optional) within each module show real-world usage and validate module behavior

### IDH Layer
Infrastructure Design Handbook provides simplified abstractions. Key concepts:
- YAML-based configuration per product/environment in `IDH/00_product_configs/`
- Loader module (`IDH/01_idh_loader/`) reads config and exposes values via `module.idh_loader.idh_resource_configuration.*`
- Eliminates repetitive variable configuration across environments
- Subject to CODEOWNERS: `/IDH/` is maintained by `@pagopa/payments-cloud-admin`

## Build, Test & Lint Commands

### Local Development Workflow
```bash
# 1. Set Terraform version (required before any terraform commands)
tfenv use 1.10.1

# 2. Initialize all modules (needed for format/validate checks)
bash .utils/terraform_run_all.sh init local

# 3. Run pre-commit checks (format, validate, docs generation, linting)
pre-commit run -a

# 4. For a specific module, test the configuration
cd api_management/tests
./terraform.sh init
./terraform.sh plan
cd ../..
```

### GitHub rules
- Never push to a branch
- Never delete a branch
- All changes must be finally reviewed by humans

### Individual Commands
| Command | Purpose |
|---------|---------|
| `terraform fmt -recursive` | Format all .tf files to standard |
| `terraform validate` | Check syntax (excludes `*/tests/` and `.utils/`) |
| `tflint --format compact` | Lint with azurerm rules (TFLint v0.25.1) |
| `pre-commit run -a` | Run all checks: fmt, validate, docs, custom scripts |
| `bash .utils/terraform_run_all.sh init local` | Initialize all modules for validation |
| `bash .scripts/terraform.sh <action>` | Run action in single module (init/plan/apply/destroy/clean) |

### Pre-Commit Hooks (`.pre-commit-config.yaml`)
Runs on every commit:
1. **generate-idh-docs** - Auto-generates IDH documentation
2. **check-variables-tf** - Enforces variable naming/structure conventions
3. **terraform_fmt** - Auto-formats Terraform code
4. **terraform_validate** - Validates all modules
5. **terraform_docs** - Generates/updates README tables (hides providers section)
6. **check-unused-vars** - Detects unused variables in modules

## Code Conventions

### File Structure (for all modules)
- **versions.tf**: Specify `required_version`, `required_providers` with min versions. Lock to Azure Commercial cloud by default.
- **variables.tf**: Every variable needs `description`. Mark secrets/credentials with `sensitive = true`. Add validation blocks for restricted values. Include `nullable = false` for required inputs.
- **main.tf**: Define all resources. Use `dynamic` blocks sparingly (prefer explicit configs). Use `local {}` block for intermediate calculations.
- **outputs.tf**: Export resource IDs first, then descriptive attributes. Mark secrets as `sensitive = true`.
- **README.md**: Contains the documentation related to each module, usage examples, and an auto-generated section by pre-commit hook (derived from `variables.tf` and `outputs.tf`). For IDH modules contains a paragraph pointing to the LIBRARY.md file for details on the available tiers.

### Naming & Formatting
- All identifiers: `snake_case`
- Resource types follow azurerm provider naming
- For optional blocks, use: `for_each = var.feature_enabled ? [var.config] : []`
- For optional attributes in dynamic blocks: `for_each = var.config != null ? [var.config] : []`


## Versioning & Release
- **Semantic versioning**: Follows [conventionalcommits.org](https://www.conventionalcommits.org)
- **PR title keywords determine version bump**:
  - `breaking:` → major version
  - `feat:` → minor version  
  - `fix:`, `docs:`, `chore:` → patch version
- **First commit differs from PR title** → add second commit to trigger correct version
- Release automation via `.releaserc.json` on `main` branch

## When Modifying Modules

1. **Before changes**: Run `tfenv use 1.10.1` to lock Terraform version
2. **Structure changes**: Update `variables.tf` with descriptions and validation
3. **Resource changes**: Keep outputs consistent; add new output if adding resource properties
4. **Format & validate**: 
   ```bash
   pre-commit run -a
   ```
5. **Update README**: Pre-commit auto-generates from `variables.tf` and `outputs.tf`, or manually update for examples
6. **Test**: Add/update test config in `module_name/tests/` showing new functionality
7. **Commit**: Use conventional commit format (fix:, feat:, breaking:, docs:, chore:)

## MCP Server Configuration

### Terraform Registry MCP
For enhanced documentation lookup and version information about azurerm provider and published modules:

**User-level configuration** (applies to all projects):
Edit or create `~/.copilot/mcp-config.json`:
```json
{
  "mcp_servers": [
    {
      "name": "terraform-registry",
      "command": "npx",
      "args": ["@modelcontextprotocol/server-terraform-docs"],
      "env": {
        "REGISTRY_HOSTNAME": "registry.terraform.io"
      }
    }
  ]
}
```

**Activate in CLI**: Use `/mcp` command to manage MCP servers, or run:
```bash
copilot --with-mcp terraform-registry
```

**Benefits**:
- Lookup azurerm provider documentation while developing
- Check published module versions and requirements
- Reference Terraform documentation for resource types
