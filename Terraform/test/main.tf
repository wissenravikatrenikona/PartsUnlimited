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
    version = "=2.71.0"
features {}
}

# Create a resource group
resource "azurerm_resource_group" "dev" {
  name     = "dev-rg"
  location = "East US"
}

# Create a virtual network in the develoment/scratch-resources resource group
resource "azurerm_virtual_network" "test" {
  name                = "__terraform-vnet__"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  location            = "${azurerm_resource_group.dev.location}"
  address_space       = ["10.0.0.0/16"]
}

# Preparing Multiple-Subnets creation
resource "azurerm_subnet" "frontend" {
  name                 = "__frontend__"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  resource_group_name  = "${azurerm_resource_group.dev.name}"
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}
resource "azurerm_app_service_plan" "dev" {
  name                = "__appserviceplan__"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "dev" {
  name                = "__appservicename__"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  app_service_plan_id = "${azurerm_app_service_plan.dev.id}"

}




