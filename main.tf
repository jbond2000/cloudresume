provider "azurerm" {
  features {}

  # Add the service principal authentication details here
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragejb"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
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
}

# Create Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public  = false
  large_file_share_enabled         = true
  access_tier                      = "Hot"
  min_tls_version                  = "TLS1_2"
}

resource "azurerm_storage_account" "tstorage_account" {
  name = var.tstorage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
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

# Create Proactive Detection Configurations for Application Insights
resource "azurerm_application_insights_smart_detection_rule" "smart_detection" {
  count                        = length(["Slow page load time", "Slow server response time", "Long dependency duration", "Degradation in server response time", "Degradation in dependency duration", "Degradation in trace severity ratio", "Abnormal rise in exception volume", "Potential memory leak detected", "Potential security issue detected", "Abnormal rise in daily data volume"])
  name                         = element(["Slow page load time", "Slow server response time", "Long dependency duration", "Degradation in server response time", "Degradation in dependency duration", "Degradation in trace severity ratio", "Abnormal rise in exception volume", "Potential memory leak detected", "Potential security issue detected", "Abnormal rise in daily data volume"], count.index)
  application_insights_id      = azurerm_application_insights.app_insights.id
  enabled                      = true

  # Corrected argument for email subscription owners
  send_emails_to_subscription_owners = true
}
