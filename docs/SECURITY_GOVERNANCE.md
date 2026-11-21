# Security and Governance

## Identity and access

- GitHub Actions authenticates to Azure with an OIDC federated identity.
- Deployment uses a user-assigned or workload identity with the minimum subscription/resource-group permissions needed for Terraform.
- Runtime application workloads use a separate user-assigned managed identity.
- Cosmos DB keys and shared local authentication are disabled.
- Blob shared-access keys are disabled.
- Key Vault uses Azure RBAC; application access is limited to `Key Vault Secrets User`.
- Cosmos DB application access is limited to the built-in SQL `Cosmos DB Built-in Data Reader` role for the account.
- Storage application access is limited to `Storage Blob Data Reader`.
- Cost access is limited to `Cost Management Reader`.

The Cost Management Reader scope is configurable. The default is the current subscription. Reduce it where organizational policy permits, for example to a management group or resource group.

## Network and data controls

- Storage and blob containers are private, HTTPS-only, and TLS 1.2 minimum.
- Nested public blob access is disabled.
- Storage infrastructure encryption is enabled.
- Key Vault network default action is deny, with Azure trusted services allowed.
- Cosmos DB local authentication is disabled. Public network access is explicit and should be replaced with private endpoints for production.
- Infrastructure encryption and retention policies are enabled where supported.

Terraform AzureRM provider version 4 can report provider deprecation notices for renamed authentication and authorization properties. This configuration uses `local_authentication_disabled = true` and `enable_rbac_authorization = true` to preserve explicit v4 compatibility. AzureRM 4.81 replaces these names with `local_authentication_enabled = false` and `rbac_authorization_enabled = true`, respectively, and both deprecated v4 names remain valid in the v4 provider range. Review provider release notes before upgrading to AzureRM v5 and preserve key-based authentication and RBAC settings as disabled/enabled.

## Required tags

Every deployable resource receives:

- `project`
- `environment`
- `owner`
- `cost_center`
- `managed_by`
- `data_classification`

The Terraform modules reject unsupported environment and data-classification values. Additional tags can be supplied through `tags`.

## Cosmos DB free tier

`enable_cosmos_free_tier` is false by default. Azure permits only one free-tier account per subscription. Enable it only after confirming that the subscription has an available free-tier slot.

## CI/CD controls

The deploy workflow performs format and validation checks, a plan, environment review, and apply. State and secrets must be stored in secured remote state and secret stores. Pull requests should use read-only plans and never print secret values.

The SecOps workflow runs Terraform format, validation, and Trivy on every run. Mend and Checkmarx run only when their credentials or configuration variables are present.
