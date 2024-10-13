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

  static_website {
    index_document = "cloudresumechallenge.html"

  }

  custom_domain {
    name = "www.jbond.cloud"
    use_subdomain = false
  }
}


# Blob Container 
resource "azurerm_storage_container" "terraformblob" {
  name = "tfblob"
  storage_account_name = var.storage_account_name
  container_access_type = "container"
}

#Table Storage
resource "azurerm_storage_table" "cvcounter" {
  name = "cvcounter"
  storage_account_name = var.storage_account_name
}

resource "azurerm_service_plan" "tfserviceplan" {
  name = "counter1-sp"
  resource_group_name = var.resource_group_name
  location = var.location
  os_type = "Windows"
  sku_name = "Y1"
}

resource "azurerm_windows_function_app" "counter1" {
  name =  "counter1"
  resource_group_name = var.resource_group_name
  location = var.location

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "https://jbtfstorage01.blob.core.windows.net/tfblob/counter1.zip"
    "WEBSITE_NODE_DEFAULT_VERSION": "~20"
    "FUNCTIONS_WORKER_RUNTIME" = "node"
    "azuretableaccountkey" = "YqJhZNwSgEZ0KSDNEUhlH5/WvaXdb03rvE2+m9oA/jppgRGYKH+P8jwM6epGk8hmlCaA0kDtKHHR+AStG0m0NA=="
    "azurewebjobstorageaccountname" = "jbtfstorage01"
  }


  storage_account_name = var.storage_account_name
  storage_account_access_key = "YqJhZNwSgEZ0KSDNEUhlH5/WvaXdb03rvE2+m9oA/jppgRGYKH+P8jwM6epGk8hmlCaA0kDtKHHR+AStG0m0NA=="
  service_plan_id = "/subscriptions/a67fa08c-8a71-4843-a6e9-1fbd1d8198b6/resourceGroups/terraform-rg/providers/Microsoft.Web/serverFarms/counter1-sp"

  site_config {
      cors {
    allowed_origins = ["https://portal.azure.com", "https://jbtfstorage01.blob.core.windows.net", "https://jbtfstorage01.z33.web.core.windows.net", "www.jbond.cloud", "https://www.jbond.cloud"]
    support_credentials = true
  }
  }

}