terraform {
#   backend "azurerm" {
#     resource_group_name  = ""
#     storage_account_name = ""
#     container_name       = "terraform-backend"
#     key                  = ""
#     access_key           = ""
#   }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  # Default
  subscription_id = var.infra_sub_id
  features {}
}
provider "azurerm" {
  # Management / Shared Services
  alias           = "shared"
  subscription_id = var.shared_sub_id
  features {}
}

provider "azurerm" {
  # Infrastucture / Spoke
  alias           = "infra"
  subscription_id = var.infra_sub_id
  features {}
}
