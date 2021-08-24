# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
#Reference https://github.com/hashicorp/terraform-provider-azurerm/
 terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "__terraformstorageaccount__"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
	access_key  ="__storagekey__"
  features{}
	}
	}
  provider "azurerm" {
    version = "=2.0.0"
features {}
}

# Create a resource group
resource "azurerm_resource_group" "dev" {
  name     = "dev-rg"
  location = "West US"
}

# Create a virtual network in the develoment/scratch-resources resource group
resource "azurerm_virtual_network" "test" {
  name                = "terraform-vnet"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  address_space       = ["10.0.0.0/16"]
}

# Preparing Multiple-Subnets creation
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = azurerm_resource_group.dev.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}


# Preparing endpointsubnet for private link enforce_private_link_endpoint_network_policies
resource "azurerm_subnet" "endpointsubnet" {
  name                 = "endpointsubnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

#if backend webapp need then we can use this, So i am commenting this part now.
#resource "azurerm_subnet" "backend" {
 # name                 = "backend"
  #virtual_network_name = azurerm_virtual_network.test.name
  #resource_group_name  = azurerm_resource_group.dev.name
  #address_prefixes     = ["10.0.2.0/24"]
#}

resource "azurerm_subnet" "database" {
  name                 = "database"
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = azurerm_resource_group.dev.name
  address_prefixes     = ["10.0.3.0/24"]
}


# create a Azure App service plan and prepare javawebapp and appinsights

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "appserviceplan"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  sku {
    tier = "Premiumv2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "frontwebapp" {
  name                = "frontwebapp20210819" #YYYYMMDD
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  #app_service_default_hostname = "https://${azurerm_app_service.frontwebapp.name}"

  app_settings = {
    "WEBSITE_DNS_SERVER": "168.63.129.16",
    "WEBSITE_VNET_ROUTE_ALL": "1"
  }
  site_config {
    java_version           = "1.8"
    java_container         = "JETTY"
    java_container_version = "9.3"
  }
}

resource azurerm_application_insights app_insights {
  name                = "__app_insigths__"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  application_type    = azurerm_app_service_plan
  sampling_percentage = "100"
  retention_in_days   = "90"

  lifecycle {
    ignore_changes = [
      tags,
      application_type
    ]
  }
}


#integrate our java webapp with subnet mask
resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegrationconnection" {
  app_service_id  = azurerm_app_service.frontwebapp.id
  subnet_id       = azurerm_subnet.frontend.id
}


# create private dnszone
resource "azurerm_private_dns_zone" "dnsprivatezone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.dev.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name = "dnszonelink"
  resource_group_name = azurerm_resource_group.dev.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsprivatezone.name
  virtual_network_id = azurerm_virtual_network.test.id
 
}

# ref https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/sql_virtual_network_rule
# Provision SQL server and integration with vnet Subnet
resource "azurerm_sql_server" "sqlserver" {
  name                         = "testazuresqlserver"
  resource_group_name          = azurerm_resource_group.dev.name
  location                     = azurerm_resource_group.dev.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_sql_virtual_network_rule" "sqlvnetrule" {
  name                = "sql-vnet-rule"
  resource_group_name = azurerm_resource_group.dev.name
  server_name         = azurerm_sql_server.sqlserver.name
  subnet_id           = azurerm_subnet.database.id
}



