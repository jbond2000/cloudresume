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
}

# Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Function App
resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  https_only                 = true

  site_config {
    linux_fx_version = var.site_config_settings["linuxFxVersion"]
    always_on        = false
    http20_enabled   = false

    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = var.cors_support_credentials
    }

    ip_restrictions = [
      {
        name        = "Allow all"
        ip_address  = "Any"
        action      = "Allow"
        priority    = 2147483647
        description = "Allow all access"
      }
    ]

    ftps_state        = var.site_config_settings["ftpsState"]
    min_tls_version   = var.site_config_settings["minTlsVersion"]
    scm_min_tls_version = var.site_config_settings["scmMinTlsVersion"]
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(var.function_app_settings, {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string,
  })

  tags = {
    "hidden-link: /app-insights-resource-id" = azurerm_application_insights.app_insights.id
  }
}

# Hostname Bindings
resource "azurerm_app_service_custom_hostname_binding" "hostname_binding" {
  hostname            = "${var.function_app_name}.azurewebsites.net"
  app_service_name    = azurerm_function_app.function_app.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Disable FTP and SCM Access
resource "azurerm_app_service_basic_auth" "basic_auth_ftp" {
  name                = "${var.function_app_name}/ftp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  properties = {
    "allow" = false
  }

  depends_on = [
    azurerm_function_app.function_app
  ]
}

resource "azurerm_app_service_basic_auth" "basic_auth_scm" {
  name                = "${var.function_app_name}/scm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  properties = {
    "allow" = false
  }

  depends_on = [
    azurerm_function_app.function_app
  ]
}
