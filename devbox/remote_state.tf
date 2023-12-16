data "terraform_remote_state" "devbox" {
  backend = "azurerm"

  config = {
    resource_group_name  = "storage"
    storage_account_name = "azuredio"
    container_name       = "terraform"
    key                  = "tailscale.test.tfstate"
  }
}