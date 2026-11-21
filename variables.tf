variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region for regional resources."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod."
  }
}

variable "owner" {
  description = "Team or person accountable for the resources."
  type        = string
  default     = "FinOps Platform"
}

variable "cost_center" {
  description = "Cost center used for chargeback."
  type        = string
  default     = "Engineering"
}

variable "data_classification" {
  description = "Data classification for the deployed resources."
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "data_classification must be Public, Internal, Confidential, or Restricted."
  }
}

variable "resource_name_suffix" {
  description = "Optional explicit suffix for generated resource names."
  type        = string
  default     = null

  validation {
    condition = var.resource_name_suffix == null || (
      length(var.resource_name_suffix) >= 3 &&
      length(var.resource_name_suffix) <= 12 &&
      can(regex("^[a-z0-9-]+$", var.resource_name_suffix))
    )
    error_message = "resource_name_suffix must be null or contain 3-12 lowercase letters, digits, or hyphens."
  }
}

variable "enable_cosmos_free_tier" {
  description = "Enable Cosmos DB free tier. Only one free-tier account is allowed per subscription."
  type        = bool
  default     = false
}

variable "cosmos_max_throughput" {
  description = "Maximum autoscale throughput for the Cosmos SQL container."
  type        = number
  default     = 1000

  validation {
    condition     = var.cosmos_max_throughput >= 1000 && var.cosmos_max_throughput <= 1000000
    error_message = "cosmos_max_throughput must be between 1000 and 1000000 RU/s."
  }
}

variable "storage_account_tier" {
  description = "Storage account performance tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication strategy."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be LRS, ZRS, GRS, or GZRS."
  }
}

variable "cost_management_scope" {
  description = "Scope for Cost Management Reader. Defaults to the configured subscription."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged with the mandatory governance tags."
  type        = map(string)
  default     = {}
}

