data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  suffix = coalesce(var.resource_name_suffix, random_string.suffix.result)
  prefix = "finops-${var.environment}"

  required_tags = {
    project             = "finops-explainer"
    environment         = var.environment
    owner               = var.owner
    cost_center         = var.cost_center
    managed_by          = "Terraform"
    data_classification = var.data_classification
  }

  tags = merge(local.required_tags, var.tags)
  cost_management_scope = coalesce(
    var.cost_management_scope,
    data.azurerm_subscription.current.id
  )
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}-${local.suffix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "main" {
  name                              = "stfinops${replace(local.suffix, "-", "")}"
  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  account_kind                      = "StorageV2"
  account_tier                      = var.storage_account_tier
  account_replication_type          = var.storage_replication_type
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  public_network_access_enabled     = true
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  tags                              = local.tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "anomalies" {
  name                  = "finops-anomalies"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${local.prefix}-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  free_tier_enabled             = var.enable_cosmos_free_tier
  public_network_access_enabled = true
  local_authentication_disabled = true
  automatic_failover_enabled    = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = local.tags
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "finops"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_sql_container" "anomalies" {
  name                  = "anomalies"
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths   = ["/tenantId"]
  partition_key_version = 2

  autoscale_settings {
    max_throughput = var.cosmos_max_throughput
  }
}

resource "azurerm_key_vault" "main" {
  name                          = "kv-finops-${local.suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_subscription.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-finops-app-${local.suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# Read-only at the subscription scope (or an explicitly configured narrower/wider scope).
resource "azurerm_role_assignment" "cost_management_reader" {
  scope                = local.cost_management_scope
  role_definition_name = "Cost Management Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_blob_data_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

# Azure Cosmos DB exposes its data-plane roles as role definitions.
resource "azurerm_cosmosdb_sql_role_assignment" "app_data_reader" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001"
  principal_id        = azurerm_user_assigned_identity.app.principal_id
  scope               = azurerm_cosmosdb_account.main.id
}

