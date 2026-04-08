###############################################################################
# OUTPUTS — Entorno Producción
###############################################################################

output "vms_app_criticos_ips" {
  description = "IPs de VMs críticas app"
  value       = { for k, v in module.vms_app_criticos : k => v.default_ip_address }
}

output "vms_app_standard_ips" {
  description = "IPs de VMs estándar app"
  value       = { for k, v in module.vms_app_standard : k => v.default_ip_address }
}

output "vms_db_ips" {
  description = "IPs de VMs bases de datos (SENSIBLE)"
  value       = { for k, v in module.vms_db_criticos : k => v.default_ip_address }
  sensitive   = true
}

output "vms_devtest_ips" {
  description = "IPs de VMs dev/test"
  value       = { for k, v in module.vms_devtest : k => v.default_ip_address }
}

output "resumen_recursos" {
  description = "Resumen de recursos por categoría"
  value = {
    app_criticos_count  = length(module.vms_app_criticos)
    app_standard_count  = length(module.vms_app_standard)
    db_criticos_count   = length(module.vms_db_criticos)
    devtest_count       = length(module.vms_devtest)
    total_gestionadas   = length(module.vms_app_criticos) + length(module.vms_app_standard) + length(module.vms_db_criticos) + length(module.vms_devtest)
  }
}
