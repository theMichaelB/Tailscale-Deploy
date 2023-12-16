
output "internal_ip_address" {
  value = azurerm_network_interface.this.private_ip_address
}