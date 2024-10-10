provider "azurerm" {
  features {}

  # Service principal authentication details
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

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  retention_in_days   = 90

  lifecycle {
    ignore_changes = [
      workspace_id
    ]
  }
}

# Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Service Plan for Windows
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "asp-windows-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Standard"
    size = "S1"
  }
  os_type = "Windows"
}

# Windows Function App
resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_app_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  os_type = "Windows"

  app_settings = merge(
    var.function_app_settings,
    {
      "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.storage_account.primary_connection_string,
      "WEBSITE_CONTENTSHARE"                     = var.function_app_name,
      "APPINSIGHTS_INSTRUMENTATIONKEY"           = azurerm_application_insights.app_insights.instrumentation_key
    }
  )

  site_config {
    min_tls_version              = "1.2"
    scm_min_tls_version          = "1.2"
    ftps_state                   = "FtpsOnly"
    always_on                    = true
    http2_enabled                = true
  }

  identity {
    type = "SystemAssigned"
  }
}

# Custom Hostname Binding
resource "azurerm_app_service_custom_hostname_binding" "hostname_binding" {
  app_service_name    = var.function_app_name
  resource_group_name = var.resource_group_name
  hostname            = "counter1.azurewebsites.net"
}

# Storage Account Network Rules - Remove restrictions
resource "azurerm_storage_account_network_rules" "network_rules" {
  storage_account_id = azurerm_storage_account.storage_account.id

  default_action = "Allow"
}
