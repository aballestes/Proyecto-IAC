###############################################################################
# OUTPUTS — Módulo vsphere-vm
###############################################################################

output "vm_id" {
  description = "ID único de la VM en vSphere (managed object ID)"
  value       = vsphere_virtual_machine.vm.id
}

output "vm_uuid" {
  description = "UUID de la VM"
  value       = vsphere_virtual_machine.vm.uuid
}

output "vm_name" {
  description = "Nombre de la VM en vCenter"
  value       = vsphere_virtual_machine.vm.name
}

output "default_ip_address" {
  description = "IP principal de la VM (requiere VMware Tools activo)"
  value       = vsphere_virtual_machine.vm.default_ip_address
}

output "num_cpus" {
  description = "Número de vCPUs configuradas actualmente"
  value       = vsphere_virtual_machine.vm.num_cpus
}

output "memory_mb" {
  description = "Memoria RAM configurada actualmente en MB"
  value       = vsphere_virtual_machine.vm.memory
}

output "power_state" {
  description = "Estado de energía de la VM"
  value       = vsphere_virtual_machine.vm.power_state
}

output "guest_id" {
  description = "ID del SO guest"
  value       = vsphere_virtual_machine.vm.guest_id
}

output "moid" {
  description = "Managed Object ID (formato: vm-XXXX)"
  value       = vsphere_virtual_machine.vm.moid
}
