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

#------------------------------------------------------------------------------
# Outputs del módulo vsphere-cluster-compute
#------------------------------------------------------------------------------
output "cluster_id" {
  description = "ID del cluster AppIBM en vCenter (domain-c8541)"
  value       = module.cluster_contingencia.cluster_id
}

output "cluster_resource_pool_id" {
  description = "ID del resource pool raíz del cluster AppIBM"
  value       = module.cluster_contingencia.resource_pool_id
}

output "cluster_datacenter_id" {
  description = "ID del datacenter IBM"
  value       = module.cluster_contingencia.datacenter_id
}

output "cluster_host_group_name" {
  description = "Nombre del host group creado (vacío si enable_host_group = false)"
  value       = module.cluster_contingencia.host_group_name
}
