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

# Storage Account
resource "azurerm_storage_account" "stg" {
  name = var.storage_account_name
  resource_group_name = var.resource_group_name
  location = var.location
  account_replication_type = "LRS"
  account_tier = "Standard"
}

# Blob Container 
resource "azurerm_storage_container" "terraformblob" {
  name = "tfblob"
  storage_account_name = var.storage_account_name
  container_access_type = "container"
}

resource "azurerm_service_plan" "tfserviceplan" {
  name = "counter1-sp"
  resource_group_name = var.resource_group_name
  location = var.location
  os_type = "Windows"
  sku_name = "Y1"
}

