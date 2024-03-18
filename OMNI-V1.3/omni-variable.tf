

variable "resource_group" {
description = "resource group for omni"
}


variable "Vnet_name" {
   description = "vnet for omni"
}

variable "public_ip" {
   description = "public ip for omni"
}

variable "mssql_server_name" {

   description = "mssql server for omni"
}

variable "rediscache_name" {

   description = "redis cache for omni"
}

variable "keyvault_name" {
  type        = string
  description = "Key Vault name in Azure"
}

variable "cosmosdb_account_name" {
  type        = string
  description = "cosmos db account for omni"
}


variable "mssql_server_db_name" {
  description = "mssql server db for omni"
}




variable "secret_name" {
  type        = string
  description = "Key Vault Secret name in Azure"
}


output "admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "The object ID of the user"
  sensitive   = true
}

variable "acr_name" {
  type        = string
  description = "ACR name"
}


variable "backend_address" {
  default = "test.azurewebsites.net"
  type = string
}

variable "storageaccount_name" {
  description = "storage account name for omni"
}

variable "app_service_plan_name" {
  description = "app serivice plan name for omni"
}

variable "function_app_name" {
  description = "function app name for omni"
}

variable "natgateway_name" {
  description = "natgateway name for omni"
}


variable "vnet_address_space_range" {
   description = "vnet address space for omni"
}

variable "subnet1_address_prefixes_range" {
   description = "subnet address space for omni"
}

variable "subnet2_address_prefixes_range" {
   description = "subnet address space for omni"
}

variable "subnet3_address_prefixes_range" {
   description = "subnet address space for omni"
}

variable "subnet4_address_prefixes_range" {
   description = "subnet address space for omni"
}

variable "subnet5_address_prefixes_range" {
   description = "subnet address space for omni"
}


variable "frontdoor_name" {
   description = "frontdoor name for omni"
}

variable "waf_name" {
   description = "WAF name for omni"
}


variable "app_service_object" {
 description = "app services for omni"
 default = [
    "as-action-panel-app-uat-1",
    "as-authorization-api-uat-2",
    "as-core-app-uat-3",
    "as-dashboard-app-uat-4",
    "as-location-api-uat-5",
    "as-notification-api-uat-6",
    "as-order-api-uat-7",
    "as-product-api-uat-8",
    "as-reports-api-uat-9",
    "as-reports-app-uat-10",
    "as-shipments-app-uat-11",
    "as-user-api-12",

  ]
}