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

variable "storage_account_name" {
  description = "The name of the Azure Storage Account"
  type        = string
  default     = "jbondcv"
}

variable "app_insights_name" {
  description = "The name of the Application Insights resource"
  type        = string
  default     = "jbondcounter"
}

variable "function_app_name" {
  description = "The name of the Azure Function App"
  type        = string
  default     = "jbondcounter"
}

variable "app_service_plan_name" {
  description = "The name of the App Service Plan for the Function App"
  type        = string
  default     = "ASP-cloudresume-baaa"
}

variable "action_group_name" {
  description = "The name of the action group for Application Insights"
  type        = string
  default     = "Application Insights Smart Detection"
}

variable "workspace_resource_id" {
  description = "The Resource ID of the Log Analytics workspace"
  type        = string
  default     = "/subscriptions/a67fa08c-8a71-4843-a6e9-1fbd1d8198b6/resourceGroups/DefaultResourceGroup-SUK/providers/Microsoft.OperationalInsights/workspaces/DefaultWorkspace-a67fa08c-8a71-4843-a6e9-1fbd1d8198b6-SUK"
}

variable "function_app_settings" {
  description = "Configuration settings for the Azure Function App"
  type        = map(any)
  default = {
    "httpsOnly"            = true
    "dailyMemoryTimeQuota" = 0
    "ftpsState"            = "FtpsOnly"
    "alwaysOn"             = false
    "publicNetworkAccess"  = "Enabled"
    "scmType"              = "None"
    "minTlsVersion"        = "1.2"
    "scmMinTlsVersion"     = "1.2"
    "webSocketsEnabled"    = false
    "scmIpSecurityRestrictionsUseMain" = false
    "use32BitWorkerProcess" = true
    "functionAppScaleLimit" = 200
    "functionsRuntimeScaleMonitoringEnabled" = false
    "minimumElasticInstanceCount" = 0
  }
}
