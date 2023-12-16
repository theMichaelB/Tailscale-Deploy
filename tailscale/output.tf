
output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "location" {
  value = data.azurerm_resource_group.this.location
}

output "resource_group_id" {
  value = data.azurerm_resource_group.this.id
}

output "subnet_id" {
  value = azurerm_subnet.this.id
}

output "subnet2_id" {
  value = azurerm_subnet.this2.id
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
