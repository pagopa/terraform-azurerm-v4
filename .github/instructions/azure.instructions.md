# Azure Resource Development Instructions

## Overview
Guidelines for implementing Azure resources using the terraform-azurerm provider.

## Azure Resource Guidelines

### Provider Configuration
- Always specify provider version constraints in `versions.tf`
- Use `azurerm` provider with appropriate API versions
- Support multiple Azure environments (Public, Government, China, Stack)
- Include provider authentication documentation

### Resource Naming
- Follow Azure naming conventions and restrictions
- Include location and environment context in names
- Document naming patterns in module README
- Use resource-specific abbreviations (rg for resource groups, aks for Kubernetes, etc.)

### Security Best Practices
- Never hardcode sensitive values (passwords, keys, connection strings)
- Use `sensitive = true` for outputs containing credentials
- Implement proper RBAC role assignments
- Enable diagnostic logging where available
- Use managed identities instead of access keys when possible
- Document security considerations in README

### Common Azure Patterns
- **Resource Groups**: Group related resources logically
- **Tagging**: Implement consistent tagging for billing and organization
- **Monitoring**: Enable Application Insights or Log Analytics integration
- **Networking**: Implement proper VNet, subnet, and NSG configurations
- **Identity**: Use managed identities for service-to-service authentication

### Resource-Specific Notes
- **Storage Accounts**: Enable versioning, soft delete, and encryption
- **Key Vaults**: Implement access policies and enable purge protection
- **App Services**: Configure auto-scaling, deployment slots, and health checks
- **Kubernetes**: Document node pool configuration and networking requirements
- **Databases**: Include backup, high availability, and connection string outputs

## Documentation Requirements
- Explain Azure-specific configuration options in README
- Include terraform.tfvars.example with realistic values
- Document any Azure-specific limitations or prerequisites
- Provide links to Azure documentation for complex resources

## Testing Azure Resources
- Validate module deploys in non-production environment first
- Test with minimal configuration before adding optional features
- Verify outputs match actual Azure resource properties
- Check cost implications of default configurations
