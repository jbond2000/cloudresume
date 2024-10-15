provider "azurerm" {
  version = ">= 4.0.0"
  features {}

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
  name                     = var.storage_account_name
  resource_group_name       = var.resource_group_name
  location                 = var.location
  account_replication_type  = "LRS"
  account_tier             = "Standard"

  static_website {
    index_document = "cloudresumechallenge.html"
  }

  custom_domain {
    name          = "www.jbond.cloud"
    use_subdomain = false
  }
}

# Blob Container
resource "azurerm_storage_container" "terraformblob" {
  name                  = "tfblob"
  storage_account_name   = var.storage_account_name
  container_access_type  = "container"
}

# Table Storage
resource "azurerm_storage_table" "cvcounter" {
  name                  = "cvcounter"
  storage_account_name   = var.storage_account_name
}

# Service Plan
resource "azurerm_service_plan" "tfserviceplan" {
  name                = "counter1-sp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

# Function App
resource "azurerm_windows_function_app" "counter1" {
  name                =  "counter1"
  resource_group_name = var.resource_group_name
  location            = var.location

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"      = "https://jbtfstorage01.blob.core.windows.net/tfblob/counter1.zip"
    "FUNCTIONS_WORKER_RUNTIME"      = "node"
    "azuretableaccountkey"          = "YqJhZNwSgEZ0KSDNEUhlH5/WvaXdb03rvE2+m9oA/jppgRGYKH+P8jwM6epGk8hmlCaA0kDtKHHR+AStG0m0NA=="
    "azurewebjobstorageaccountname" = "jbtfstorage01"
  }

  storage_account_name       = var.storage_account_name
  storage_account_access_key = "YqJhZNwSgEZ0KSDNEUhlH5/WvaXdb03rvE2+m9oA/jppgRGYKH+P8jwM6epGk8hmlCaA0kDtKHHR+AStG0m0NA=="
  service_plan_id            = "/subscriptions/a67fa08c-8a71-4843-a6e9-1fbd1d8198b6/resourceGroups/terraform-rg/providers/Microsoft.Web/serverFarms/counter1-sp"

  site_config {
    cors {
      allowed_origins      = ["https://portal.azure.com", "https://jbtfstorage01.blob.core.windows.net", "https://jbtfstorage01.z33.web.core.windows.net", "www.jbond.cloud", "https://www.jbond.cloud", "https://jbond.cloud"]
      support_credentials  = true
    }
  }
}

# CDN Profile
resource "azurerm_cdn_profile" "cdnjbondresume" {
  name                = "jbondresume"
  resource_group_name = var.resource_group_name
  location            = "global"
  sku                 = "Standard_Microsoft"
}

# CDN Endpoint with custom domain and redirection rules
resource "azurerm_cdn_endpoint" "cdnendpoint" {
  name                = "jbondresume"
  profile_name        = azurerm_cdn_profile.cdnjbondresume.name
  location            = "global"
  resource_group_name = azurerm_resource_group.rg.name

  origin {
    name      = "cv"
    host_name = "jbtfstorage01.z33.web.core.windows.net"
  }

  content_types_to_compress = [
    "application/eot", "application/font", "application/javascript", "application/json",
    "application/opentype", "application/otf", "application/x-font-opentype",
    "font/eot", "font/ttf", "font/otf", "font/opentype", "image/svg+xml", 
    "text/css", "text/html", "text/plain", "text/xml"
  ]

  is_compression_enabled = true
  is_http_allowed        = true
  is_https_allowed       = true

  delivery_rule {
    name  = "HTTPRedirect"
    order = 1

    request_scheme_condition {
      match_values = ["HTTP"]
    }

    url_redirect_action {
      protocol      = "Https"
      redirect_type = "Found"
    }
  }

  delivery_rule {
    name  = "wwwRedirect"
    order = 2

    request_uri_condition {
      match_values = ["www.jbond.cloud"]
      operator     = "Equal"
    }

    url_redirect_action {
      protocol      = "Https"
      redirect_type = "PermanentRedirect"
    }
  }

  lifecycle {
    ignore_changes = all  # This tells Terraform to completely ignore any changes
  }
}

# DNS Zone for managing the jbond.cloud domain
resource "azurerm_dns_zone" "jbond_cloud" {
  name                = "jbond.cloud"
  resource_group_name = var.resource_group_name
}

# DNS CNAME Record for www.jbond.cloud
resource "azurerm_dns_cname_record" "www_jbond_cloud" {
  name                = "www"
  zone_name           = azurerm_dns_zone.jbond_cloud.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = "jbondresume.azureedge.net"
}

# DNS CNAME Record for jbond.cloud
resource "azurerm_dns_cname_record" "jbond_cloud_cname" {
  name                = "jbond"
  zone_name           = azurerm_dns_zone.jbond_cloud.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = "jbondresume.azureedge.net"
}

# CDN Custom Domain www.jbond.cloud
resource "azurerm_cdn_endpoint_custom_domain" "www_jbond_cloud_custom_domain" {
  name            = "www-jbond-cloud"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdnendpoint.id
  host_name       = "www.jbond.cloud"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}

# CDN Custom Domain jbond.cloud
resource "azurerm_cdn_endpoint_custom_domain" "jbond_cloud_custom_domain" {
  name            = "jbond-cloud"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdnendpoint.id
  host_name       = "jbond.cloud"

  user_managed_https {
    key_vault_secret_id = "https://jbondtfcert.vault.azure.net/secrets/jbondroot"
  }
}
resource "azurerm_key_vault_certificate" "jbondcloud_cert" {
  name         = "jbondroot"
  key_vault_id = azurerm_key_vault.jbondtfcert.id

  certificate_policy {
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    issuer_parameters {
      name = "Self"  # Or specify another issuer, such as "Unknown" or an external CA
    }

    x509_certificate_properties {
      subject            = "CN=jbond.cloud"
      validity_in_months = 24

      key_usage = [
        "digitalSignature",
        "keyEncipherment"
      ]

      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1"  # This OID corresponds to "serverAuth" for HTTPS/TLS certificates
      ]
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }
  }
}



# Key Vault
resource "azurerm_key_vault" "jbondtfcert" {
  name                = "jbondtfcert"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = "2a0170c1-2a25-449f-b42c-3c61646295d9"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers",
      "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    storage_permissions = ["Get"]
  }

  access_policy {
    tenant_id = "ca249364-2247-4916-be5f-6878448ff851"
    object_id = "85293833-55de-4b5a-917b-c7fb20a6bfa7"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers",
      "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  access_policy {
    tenant_id    = "ca249364-2247-4916-be5f-6878448ff851"
    object_id    = "f027dfc1-6806-46fd-a2e9-517cb784a594"

    certificate_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers",
      "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
    ]

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", 
      "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}
