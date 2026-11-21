output "resource_group_name" {
  description = "Name of the FinOps resource group."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region used for resources."
  value       = azurerm_resource_group.main.location
}

output "managed_identity_id" {
  description = "Resource ID of the application user-assigned managed identity."
  value       = azurerm_user_assigned_identity.app.id
}

output "managed_identity_client_id" {
  description = "Client ID of the application user-assigned managed identity."
  value       = azurerm_user_assigned_identity.app.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the application user-assigned managed identity."
  value       = azurerm_user_assigned_identity.app.principal_id
}

output "storage_account_name" {
  description = "Name of the private FinOps storage account."
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "Resource ID of the FinOps storage account."
  value       = azurerm_storage_account.main.id
}

output "cosmos_account_name" {
  description = "Name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmos_database_name" {
  description = "Cosmos DB SQL database name."
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "cosmos_container_name" {
  description = "Cosmos DB anomaly container name."
  value       = azurerm_cosmosdb_sql_container.anomalies.name
}

output "key_vault_name" {
  description = "Name of the RBAC-enabled Key Vault."
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.main.vault_uri
}

