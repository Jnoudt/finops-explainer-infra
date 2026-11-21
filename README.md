# FinOps Explainer Infrastructure

Terraform infrastructure for Project 3 of the Cloud Cost & FinOps Anomaly Explainer portfolio.

## Contents

- Azure Resource Group
- HTTPS-only, private Blob container
- Cosmos DB SQL database and anomaly container
- RBAC-enabled Key Vault
- User-assigned managed identity
- Least-privilege Cost Management, Storage, Cosmos, and Key Vault roles
- GitHub Actions OIDC deployment and SecOps workflows

## Requirements

- Terraform >= 1.8
- AzureRM provider ~> 4.0
- Azure CLI or GitHub Actions OIDC credentials
- Azure subscription permissions for resource deployment and role assignment
- Trivy for local configuration checks

## Configure

Create a non-committed `terraform.tfvars`:

```hcl
subscription_id            = "00000000-0000-0000-0000-000000000000"
location                   = "eastus"
environment                = "dev"
owner                      = "FinOps Platform"
cost_center                = "Engineering"
data_classification        = "Internal"
enable_cosmos_free_tier    = false
cosmos_max_throughput      = 1000
```

The Cosmos DB free tier is disabled by default. Azure allows only one free-tier account per subscription, so enable it only after checking available quota.

## Deploy

```powershell
terraform init
terraform fmt
terraform validate
terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan
```

Local governance and Trivy checks:

```powershell
.\check-iac.ps1
```

## GitHub Actions OIDC

Configure these repository variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- Optional `AZURE_LOCATION`
- Optional `FINOPS_ENVIRONMENT`
- Optional `FINOPS_OWNER`
- Optional `FINOPS_COST_CENTER`
- Optional `ENABLE_COSMOS_FREE_TIER`

The federated identity must trust the repository and intended environment/branch. Grant it only the Azure resource deployment and role-assignment permissions required in the target scope.

## Optional security integrations

Set `MEND_ENABLED=true` and repository secrets `MEND_USER_KEY` and `MEND_API_KEY` to run Mend.

Set `CHECKMARX_ENABLED=true`, `CHECKMARX_TENANT`, and repository secrets `CHECKMARX_CLIENT_ID` and `CHECKMARX_CLIENT_SECRET` to run Checkmarx.

See [Security and Governance](docs/SECURITY_GOVERNANCE.md).
