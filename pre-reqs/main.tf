resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "uksouth"
}

data "azurerm_subscription" "primary" {
}

resource "azuread_application" "auth" {
  display_name = "spot-dev-auth"
}

resource "azuread_service_principal" "auth" {
  client_id = azuread_application.auth.client_id
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.auth.id
  end_date_relative    = "8760h" # 1 year
}

#write password to file 
resource "local_file" "adpassword" {
  content  = azuread_service_principal_password.this.value
  filename = "vars/ARM_CLIENT_SECRET.txt"
}

resource "local_file" "adclientid" {
  content  = azuread_service_principal.auth.application_id
  filename = "vars/ARM_CLIENT_ID.txt"
}

resource "local_file" "adtenantid" {
  content  = data.azurerm_subscription.primary.tenant_id
  filename = "vars/ARM_TENANT_ID.txt"
}

resource "local_file" "subscriptionid" {
  content  = data.azurerm_subscription.primary.subscription_id
  filename = "vars/ARM_SUBSCRIPTION_ID.txt"
}


#create map containing role assignments, including storage account contributor, network contributor and vm contributor

variable "role_assignments" {
  type = map
  default = {
    "storage_account_contributor" = {
      role_definition_name = "Storage Account Contributor"
    }
    "network_contributor" = {
      role_definition_name = "Network Contributor"
    }
    "vm_contributor" = {
      role_definition_name = "Virtual Machine Contributor"
    }
  }
}

# create role assignments

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_resource_group.rg.id
  role_definition_name = each.value.role_definition_name
  principal_id         = azuread_service_principal.auth.id
}
