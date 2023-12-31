terraform {
  required_version = ">= 1.6"

  backend "azurerm" {
    resource_group_name  = "storage"
    storage_account_name = "azuredio"
    container_name       = "terraform"
    key                  = "devbox.tailscale.test.tfstate"
    use_msi              = true

  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}
