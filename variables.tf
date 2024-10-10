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
  default     = "cloudresume"
}

variable "location" {
  description = "The location for all resources"
  type        = string
  default     = "UK South"
}

variable "function_app_name" {
  description = "The name of the Azure Function App"
  type        = string
  default     = "counter1"
}

variable "storage_account_name" {
  description = "The name of the Azure Storage Account"
  type        = string
  default     = "jbondcv"
}

variable "app_service_plan_id" {
  description = "ID of the App Service Plan"
  type        = string
  default     = "/subscriptions/a67fa08c-8a71-4843-a6e9-1fbd1d8198b6/resourceGroups/cloudresume/providers/Microsoft.Web/serverfarms/ASP-cloudresume-9bed"
}

variable "app_insights_name" {
  description = "The name of the Application Insights resource"
  type        = string
  default     = "counter1"
}

variable "function_app_settings" {
  description = "Configuration settings for the Azure Function App"
  type        = map(string)
  default = {
    "FUNCTIONS_WORKER_RUNTIME"              = "node",
    "WEBSITE_NODE_DEFAULT_VERSION"          = "20",
    "WEBSITE_RUN_FROM_PACKAGE"              = "1",
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "1",
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "",
  }
}

variable "site_config_settings" {
  description = "Site configuration settings for the Function App"
  type        = map(string)
  default = {
    "minTlsVersion"                    = "1.2",
    "scmMinTlsVersion"                 = "1.2",
    "ftpsState"                        = "FtpsOnly",
    "publicNetworkAccess"              = "Enabled",
    "scmIpSecurityRestrictionsUseMain" = "false",
  }
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["https://portal.azure.com"]
}

variable "cors_support_credentials" {
  description = "CORS support credentials"
  type        = bool
  default     = false
}
