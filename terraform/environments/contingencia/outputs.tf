###############################################################################
# OUTPUTS — Entorno Contingencia
###############################################################################

output "vms_ip_map" {
  description = "Mapa de nombre de VM → IP (requiere VMware Tools activo)"
  value = {
    for k, v in module.vms_contingencia : k => v.default_ip_address
  }
}

output "vms_cpu_map" {
  description = "Mapa de nombre de VM → cantidad de vCPUs configuradas"
  value = {
    for k, v in module.vms_contingencia : k => v.num_cpus
  }
}

output "vms_memory_map" {
  description = "Mapa de nombre de VM → RAM en MB"
  value = {
    for k, v in module.vms_contingencia : k => v.memory_mb
  }
}

output "vms_uuid_map" {
  description = "Mapa de nombre de VM → UUID vSphere"
  value = {
    for k, v in module.vms_contingencia : k => v.vm_uuid
  }
}

output "resource_pool_criticos_id" {
  description = "ID del resource pool de servicios críticos"
  value       = vsphere_resource_pool.rp_criticos.id
}

output "resource_pool_devtest_id" {
  description = "ID del resource pool de desarrollo/pruebas"
  value       = vsphere_resource_pool.rp_devtest.id
}

output "tag_contingencia_id" {
  description = "ID del tag 'contingencia' para usar en otras configuraciones"
  value       = vsphere_tag.tag_contingencia.id
}
