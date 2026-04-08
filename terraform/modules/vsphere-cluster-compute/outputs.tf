###############################################################################
# MÓDULO: vsphere-cluster-compute — Outputs
###############################################################################

output "cluster_id" {
  description = "ID del cluster de cómputo en vCenter"
  value       = data.vsphere_compute_cluster.cluster.id
}

output "cluster_name" {
  description = "Nombre del cluster"
  value       = data.vsphere_compute_cluster.cluster.name
}

output "resource_pool_id" {
  description = "ID del resource pool raíz del cluster (para asignar VMs)"
  value       = data.vsphere_compute_cluster.cluster.resource_pool_id
}

output "datacenter_id" {
  description = "ID del datacenter"
  value       = data.vsphere_datacenter.dc.id
}

output "vm_group_name" {
  description = "Nombre del grupo de VMs creado (si aplica)"
  value       = length(vsphere_compute_cluster_vm_group.vm_group) > 0 ? vsphere_compute_cluster_vm_group.vm_group[0].name : ""
}

output "host_group_name" {
  description = "Nombre del grupo de hosts creado (si aplica)"
  value       = length(vsphere_compute_cluster_host_group.host_group) > 0 ? vsphere_compute_cluster_host_group.host_group[0].name : ""
}
