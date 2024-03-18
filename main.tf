#==============================================================================================================================
#========================================================OMNI-SCRIPT==========================================================
#============================================================================================================================

#Configure the Azure provider

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}



#===============================================================================================================================
#=============================================AUNTHENICATE USING SERVICE PRINCIPAL==============================================
#==============================================================================================================================

provider "azurerm" {

  skip_provider_registration = true
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features{}

}




#=============================================================================================================================
#===========================================USE EXISTING RESOURCE-GROUP========================================================
#==============================================================================================================================

data "azurerm_resource_group" "test" {
  name     = var.resource_group
}

#==============================================================================================================================
#=================================================CREATION OF VNET=============================================================
#===============================================================================================================================

#creating vnet

resource "azurerm_virtual_network" "vnet" {
  name = var.Vnet_name
  address_space       = var.vnet_address_space_range
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
}

#===============================================================================================================================
#===============================================CREATION OF SUBNETS(5)==========================================================
#===============================================================================================================================

#creating default subnet

resource "azurerm_subnet" "default_subnet" {
  name = "default"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]


}

#creating 1st subnet

resource "azurerm_subnet" "subnet1" {
  name = "vnet-sn-apim-uat"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet1_address_prefixes_range
}

#creating 2nd subnet

resource "azurerm_subnet" "subnet2" {
  name = "vnet-sn-cosmos-pe"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet2_address_prefixes_range
}

#creating 3rd subnet

resource "azurerm_subnet" "subnet3" {
  name = "vnet-sn-mssql-pe"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet3_address_prefixes_range
}

#creating 4th subnet

resource "azurerm_subnet" "subnet4" {
  name = "vnet-sn-redis-pe"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet4_address_prefixes_range
}

#creating 5th subnet

resource "azurerm_subnet" "subnet5" {
  name = "vnet-sn-webapp-uat"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet5_address_prefixes_range
}



#===============================================================================================================================
#============================================CREATION OF PUBLIC IP==============================================================
#===============================================================================================================================



#creating public IP for bastion

resource "azurerm_public_ip" "omnipip" {
  name = var.public_ip
  location = "${data.azurerm_resource_group.test.location}"
  resource_group_name= "${data.azurerm_resource_group.test.name}"
  allocation_method = "Static"
  sku               = "Standard"
}


#==============================================================================================================================
#===============================================CREATION OF KEYVAULT============================================================
#==============================================================================================================================

#Creating random password

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}



data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                        = var.keyvault_name
  location                    = "${data.azurerm_resource_group.test.location}"
  resource_group_name         = "${data.azurerm_resource_group.test.name}"
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
          "List",
    ]

    secret_permissions = [
      "get",
      "List",
      "set",
      "delete",
      "Recover",
      "Restore",
    ]

    storage_permissions = [
      "get",
          "List",

    ]
  }
}

resource "azurerm_key_vault_secret" "db-pwd" {
  name         = var.secret_name
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.keyvault.id
}


#===============================================================================================================================
#==============================================CREATION OF MSSSQL SERVER======================================================
#==============================================================================================================================





#Creating of Mssql server


resource "azurerm_mssql_server" "example" {
  name                         =  var.mssql_server_name
  resource_group_name          = "${data.azurerm_resource_group.test.name}"
  location                     = "${data.azurerm_resource_group.test.location}"
  version                      = "12.0"
  administrator_login          =  var.secret_name
  administrator_login_password =  random_password.password.result
  minimum_tls_version          = "1.2"


}

#==============================================================================================================================
#============================================CREATION OF REDIS CACHE===========================================================
#===============================================================================================================================


#Creating Redis-Cache

resource "azurerm_redis_cache" "example" {
  name = var.rediscache_name
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  public_network_access_enabled = false

  redis_configuration {
  }
}


#===============================================================================================================================
#===========================================CREATION OF COSMOS DB ACCOUNT=======================================================
#===============================================================================================================================


#creating cosmos db-account

resource "azurerm_cosmosdb_account" "example" {
  name                      = var.cosmosdb_account_name
  location                  = "${data.azurerm_resource_group.test.location}"
  resource_group_name       = "${data.azurerm_resource_group.test.name}"
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
  }
  geo_location{
    location = "${data.azurerm_resource_group.test.location}"
    failover_priority = 0
  }
}

#===============================================================================================================================
#=================================================CREATION OF MSSQL-DB==========================================================
#==============================================================================================================================


#Creating of mssql database

resource "azurerm_mssql_database" "db" {
  name           = var.mssql_server_db_name
  server_id      = azurerm_mssql_server.example.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}


#===============================================================================================================================
#=================================================CREATION OF PRIVATE ENDPOINTS(3)==============================================
#===============================================================================================================================


#Creation of private endpoint attached to mssql-server

resource "azurerm_private_endpoint" "private1" {
  name                 = "pe-mssql-uat"
  location             = "${data.azurerm_resource_group.test.location}"
  resource_group_name  = "${data.azurerm_resource_group.test.name}"
  subnet_id            = azurerm_subnet.subnet3.id

  private_service_connection {
    name                           = "psc1"
    private_connection_resource_id = azurerm_mssql_server.example.id
    subresource_names              = [ "sqlServer" ]
    is_manual_connection           = false

  }

}


# Creation of private endpoint attached to cosmos db account

resource "azurerm_private_endpoint" "private2" {
  name                = "pe-cosmos-db-uat"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  subnet_id           = azurerm_subnet.subnet2.id

  private_service_connection {
    name                           = "psc2"
    private_connection_resource_id = azurerm_cosmosdb_account.example.id
    subresource_names              = [ "Sql"]
    is_manual_connection           = false
  }

}

#Creation of private endpoint attached to redis cache


resource "azurerm_private_endpoint" "private3" {
  name                = "pe-redis-db-uat"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  subnet_id           = azurerm_subnet.subnet4.id

  private_service_connection {
    name                           = "psc3"
    private_connection_resource_id = azurerm_redis_cache.example.id
    subresource_names              = [ "redisCache" ]
    is_manual_connection           = false
 }

}


#=============================================================================================================================
#===========================================CREATION OF PRIVATE DNS ZONE(3)=====================================================
#=============================================================================================================================

# Resource-1: Create Azure Private DNS Zone

resource "azurerm_private_dns_zone" "private_dns_zone1" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
}

# Resource-1: Associate Private DNS Zone to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_associate" {
  name                  = "vnet1"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone1.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Resource-2: Create Azure Private DNS Zone

resource "azurerm_private_dns_zone" "private_dns_zone2" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
}

# Resource-2: Associate Private DNS Zone to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_associate1" {
  name                  = "vnet2"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone2.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Resource-3: Create Azure Private DNS Zone

resource "azurerm_private_dns_zone" "private_dns_zone3" {
  name                = "privatelink.database.windows.net"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
}

# Resource-3: Associate Private DNS Zone to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_associate2" {
  name                  = "vnet3"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone3.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

#===============================================================================================================================
#============================================CREATION OF ACR REGISTRY===========================================================
#===============================================================================================================================

#Creating container registry

resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = "${data.azurerm_resource_group.test.name}"
  location                 = "${data.azurerm_resource_group.test.location}"
  sku                      = "Basic"
  admin_enabled            = true
}

#==============================================================================================================================
#========================================CREATION OF API MANAGEMENT=============================================================
#===============================================================================================================================

#Creating API Managment

resource "azurerm_api_management" "example" {
  name                = "omni-uat-apim"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  publisher_name      = "My Company"
  publisher_email     = "company@terraform.io"

  sku_name = "Developer_1"
}

#===============================================================================================================================
#==================================================CREATION OF STORAGE ACCOUNT==================================================
#==============================================================================================================================

#Creating storage account
resource "azurerm_storage_account" "example" {
  name                     = var.storageaccount_name
  resource_group_name      = "${data.azurerm_resource_group.test.name}"
  location                 = "${data.azurerm_resource_group.test.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


#Creating blob containers

#resource "azurerm_storage_container" "{Blob}" {
#  name                  = "{Blob}"
#  storage_account_name  = azurerm_storage_account.example.name
#  container_access_type = "private"
#}

#===============================================================================================================================
#==================================================CREATION OF APP SERVICE PLAN================================================
#===============================================================================================================================

#Creating of app service plan
resource "azurerm_app_service_plan" "example" {
  name                = "testservice"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "P1v3"
  }
}

#===============================================================================================================================
#==================================================CREATION OF APP SERVICES================================================
#===============================================================================================================================


# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                  = "${var.app_service_object[count.index]}-azure-web"
  count                 = 12
  location              = "${data.azurerm_resource_group.test.location}"
  resource_group_name   = "${data.azurerm_resource_group.test.name}"
  service_plan_id       = azurerm_app_service_plan.example.id
  https_only            = true


site_config {
    always_on      = "true"

    application_stack {
      docker_image     = "${azurerm_container_registry.acr.login_server}/myimage"
      docker_image_tag = "latest"
      dotnet_version   = "6.0"
    }
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false

    # Settings for private Container Registires
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password

  }

}



#===============================================================================================================================
#=====================================CREATION OF FUNCTION APP=================================================================
#==============================================================================================================================

#Creating of function app

resource "azurerm_function_app" "example" {
  name                       = "function1omni"
  location                   = "${data.azurerm_resource_group.test.location}"
  resource_group_name        = "${data.azurerm_resource_group.test.name}"
  app_service_plan_id        = azurerm_app_service_plan.example.id
  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

site_config {
      always_on                 = true
      linux_fx_version          = "DOCKER|${azurerm_container_registry.acr.login_server}/pingtrigger:test"
    }




  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false

    # Settings for private Container Registires
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.acr.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password

  }

}

#===============================================================================================================================
#=========================================CREATION NAT GATEWAY==================================================================
#===============================================================================================================================

#Creating Nat GATEWAY

resource "azurerm_nat_gateway" "example" {
  name                = var.natgateway_name
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  sku_name            = "Standard"
}

#Associating with public IP
resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.example.id
  public_ip_address_id = azurerm_public_ip.omnipip.id

}

#Associating with subnet

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.subnet5.id
  nat_gateway_id = azurerm_nat_gateway.example.id
}

#===============================================================================================================================
#=============================================CREATION OF APPLICATION INSIGHT===================================================
#===============================================================================================================================


#Creating application insight


resource "azurerm_log_analytics_workspace" "example" {
  name                = "workspace-test"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "example" {
  name                = "tf-test-appinsights"
  location            = "${data.azurerm_resource_group.test.location}"
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  workspace_id        = azurerm_log_analytics_workspace.example.id
  application_type    = "web"
}

output "instrumentation_key" {
  value = azurerm_application_insights.example.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.example.app_id
  sensitive = true
}

#===============================================================================================================================
#==========================================CREATION OF FRONTDOOR WAF POLICY=====================================================
#===============================================================================================================================

module "frontdoor" {
  source  = "kumarvna/frontdoor/azurerm"
  version = "1.0.0"






   # By default, this module will not create a resource group. Location will be same as existing RG.
  # proivde a name to use an existing resource group, specify the existing resource group name,
  # set the argument to `create_resource_group = true` to create new resrouce group.
#  create_resource_group = true
  resource_group_name = "${data.azurerm_resource_group.test.name}"
  location            = "${data.azurerm_resource_group.test.location}"



  frontdoor_name      = var.frontdoor_name

  routing_rules = [
    {
      name               = "exampleRoutingRule1"
      accepted_protocols = ["Http", "Https"]
      patterns_to_match  = ["/*"]
      frontend_endpoints = [var.frontdoor_name]
      forwarding_configuration = {
        forwarding_protocol = "MatchRequest"
        backend_pool_name   = "exampleBackendBing"
      }
    }
  ]

  backend_pool_load_balancing = [
    {
      name = "exampleLoadBalancingSettings1"
    }
  ]

  backend_pool_health_probes = [
    {
      name = "exampleHealthProbeSetting1"
    }
  ]

  backend_pools = [
    {
      name = "exampleBackendBing"
      backend = {
        host_header = "www.bing.com"
        address     = "www.bing.com"
        http_port   = 80
        https_port  = 443
      }
      load_balancing_name = "exampleLoadBalancingSettings1"
      health_probe_name   = "exampleHealthProbeSetting1"
    }
  ]

  # In order to enable the use of your own custom HTTPS certificate you must grant
  # Azure Front Door Service access to your key vault. For instuctions on how to
  # configure your Key Vault correctly. Please refer to the product documentation.
  # https://bit.ly/38FuAZv

  frontend_endpoints = [
    {
      name      = var.frontdoor_name
      host_name = "${var.frontdoor_name}.azurefd.net"


    }
  ]
#==============================================================================================================================
#==================AZURE FRONTDOOR WEB APPLICATION FIREWALL POLICY CONFIGURATION==============================================
#=============================================================================================================================

  web_application_firewall_policy = {
    wafpolicy1 = {
      name                              = var.waf_name
      mode                              = "Prevention"
      redirect_url                      = "https://www.contoso.com"
      custom_block_response_status_code = 403
      custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="

      custom_rule = {
        custom_rule1 = {
          name     = "Rule1"
          action   = "Block"
          enabled  = true
          priority = 1
          type     = "MatchRule"
          match_condition = {
            match_variable     = "RequestHeader"
            match_values       = ["windows"]
            operator           = "Contains"
            selector           = "UserAgent"
            negation_condition = false
            transforms         = ["Lowercase", "Trim"]
          }
          rate_limit_duration_in_minutes = 1
          rate_limit_threshold           = 10
        }
      }

      managed_rule = {
        managed_rule1 = {
          type    = "DefaultRuleSet"
          version = "1.0"
          exclusion = {
            exclusion1 = {
              match_variable = "QueryStringArgNames"
              operator       = "Equals"
              selector       = "not_suspicious"
            }
          }
          override = {
            override1 = {
              rule_group_name = "PHP"
              exclusion = {
                exclusion1 = {
                  match_variable = "QueryStringArgNames"
                  operator       = "Equals"
                  selector       = "not_suspicious"
                }
              }
              rule = {
                rule1 = {
                  rule_id = "933100"
                  action  = "Block"
                  enabled = false
                  exclusion = {
                    exclusion1 = {
                      match_variable = "QueryStringArgNames"
                      operator       = "Equals"
                      selector       = "not_suspicious"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}


#===========================================================================================================================
#===================================================END====================================================================
#=======================================================================================================================

