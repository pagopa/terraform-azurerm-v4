# kubernetes_argocd_setup

Purpose: installs and configures Argo CD on AKS via Helm with Azure Entra ID (OIDC) and Azure Workload Identity.

Notes

- Change `argocd_force_reinstall_version` to force Helm reinstallation when needed.
- Admin password: provide `admin_password` or a secure one is generated and stored.
- Fine‑tune feature flags via the `enable_*` variables to skip parts you manage elsewhere.

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
