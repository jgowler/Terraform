output "Domain_service" {
  value       = azurerm_active_directory_domain_service.aadds-domain.id
  description = "Id generated once Domain Service is deployed."
}
output "azuread_user" {
  value = azuread_user.dc_admin.user_principal_name
}
output "azuread_group_aad_dc_administrators" {
  value = azuread_group.aad_dc_administrators.object_id
}
output "aaddc_admin_object_id" {
  value = azuread_user.dc_admin.object_id
}
output "aaddcadmin_password" {
  value = random_password.dc_admin.result
}
output "aaddcadmin_group_object_id" {
  value = azuread_group.aad_dc_administrators.object_id
}
output "domain_join_name" {
  value = azurerm_active_directory_domain_service.aadds-domain.name
}