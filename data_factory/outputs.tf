output "id" {
  description = "The id of the Data Factory."
  value       = azurerm_data_factory.this.id
}

output "principal_id" {
  value = azurerm_data_factory.this.identity[0].principal_id
}