# Variables for Service Principal Authentication
variable "client_id" {
  description = "The Client ID of the Service Principal"
  type        = string
  default     = "d0abc8bf-92b5-4b7a-ae04-6a0625e55d36"
}

variable "client_secret" {
  description = "The Client Secret of the Service Principal"
  type        = string
  sensitive   = true
  default     = "eez8Q~wHBDUCc0LvFPo2lpFvfZQFPQcwuuTfyaR_"
}

variable "tenant_id" {
  description = "The Tenant ID for the Service Principal"
  type        = string
  default     = "ca249364-2247-4916-be5f-6878448ff851"
}

variable "subscription_id" {
  description = "The Subscription ID where resources will be created"
  type        = string
  default     = "a67fa08c-8a71-4843-a6e9-1fbd1d8198b6"
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group"
  type        = string
  default     = "terraform-rg"
}

variable "location" {
  description = "The location for all resources"
  type        = string
  default     = "UK South"
}

variable "storage_account_name" {
  type = string
  default = "jbtfstorage01"
}