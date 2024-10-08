provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90

  # Remove log_analytics_workspace_id as it is not a supported argument
  # Use a separate `azurerm_monitor_diagnostic_setting` to link to Log Analytics if needed
}

# Create Action Group
resource "azurerm_monitor_action_group" "action_group" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "SmartDetect"
  enabled             = true

  arm_role_receiver {
    role_id                  = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    name                     = "Monitoring Contributor"
    use_common_alert_schema  = true
  }

  arm_role_receiver {
    role_id                  = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    name                     = "Monitoring Reader"
    use_common_alert_schema  = true
  }
}

# Create Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Supported argument names for Azure Storage Account:
  allow_nested_items_to_be_public  = false # Use this to restrict nested items from being public (older versions)
  enable_https_traffic_only        = true  # Should work with supported AzureRM versions
  large_file_share_enabled         = true
  access_tier                      = "Hot"

  # Note: Remove allow_blob_public_access or update the AzureRM provider to version 2.56.0 or higher
  min_tls_version                  = "TLS1_2"
}

# Create App Service Plan
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "functionapp"

  sku {
    tier     = "Dynamic"
    size     = "Y1"
    capacity = 0
  }
}

# Create Function App
resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  https_only                 = true

  app_settings = merge(var.function_app_settings, {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string,
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.app_insights.instrumentation_key
  })

  identity {
    type = "SystemAssigned"
  }
}

# Create Proactive Detection Configurations
resource "azurerm_application_insights_smart_detection_rule" "smart_detection" {
  count                    = length(["degradationindependencyduration", "degradationinserverresponsetime", "digestMailConfiguration", "extension_billingdatavolumedailyspikeextension", "extension_canaryextension", "extension_exceptionchangeextension", "extension_memoryleakextension", "extension_securityextensionspackage", "extension_traceseveritydetector", "longdependencyduration", "migrationToAlertRulesCompleted", "slowpageloadtime", "slowserverresponsetime"])
  name                     = element(["degradationindependencyduration", "degradationinserverresponsetime", "digestMailConfiguration", "extension_billingdatavolumedailyspikeextension", "extension_canaryextension", "extension_exceptionchangeextension", "extension_memoryleakextension", "extension_securityextensionspackage", "extension_traceseveritydetector", "longdependencyduration", "migrationToAlertRulesCompleted", "slowpageloadtime", "slowserverresponsetime"], count.index)
  application_insights_id  = azurerm_application_insights.app_insights.id
  enabled                  = true

  # Corrected argument for email subscription owners
  send_emails_to_subscription_owners = true
}
