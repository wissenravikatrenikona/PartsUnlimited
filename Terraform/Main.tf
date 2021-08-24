# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
#Reference https://docs.microsoft.com/en-us/azure/app-service/scripts/terraform-secure-backend-frontend  
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

  subscription_id = "65911ece-b772-4e16-ab25-fc95982846dc"
   client_id       = "37f075a8-9437-4317-84e7-8106b3c2c6a3"
   client_secret   = "ui8lG0EanXUt.M3ZM-T8P8krICoaEk.RS6"
   tenant_id       = "8a38d5c9-ff2f-479e-8637-d73f6241a4f0"
}

resource "azurerm_resource_group" "rg" {
  name     = "appservice-rg"
  location = "east us"
}

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Premiumv2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "Simplewebapp" {
  name                = "Simplewebapp20200823"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  #app_service_default_hostname = "https://${azurerm_app_service.frontwebapp.name}"

  #app_settings = {
   # "WEBSITE_DNS_SERVER": "168.63.129.16",
    #"WEBSITE_VNET_ROUTE_ALL": "1"
  #}
  #site_config {
   # java_version           = "1.8"
    #java_container         = "JETTY"
    #java_container_version = "9.3"
  #}
}



