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
  subscription_id = ${{ secrets.subscription_id }}
  client_id       = ${{ secrets.client_id }}
  client_secret   = ${{ secrets.client_secret}}
  tenant_id       = ${{ secrets.stenant_id }}
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
resource "time_sleep" "wait_3_seconds" {
  depends_on = [azurerm_virtual_network.vnet]
  create_duration = "3s"
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
#=================================================CREATION OF PRIVATE ENDPOINTS(3)==============================================
#===============================================================================================================================





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





#===========================================================================================================================
#===================================================END====================================================================
#=======================================================================================================================
