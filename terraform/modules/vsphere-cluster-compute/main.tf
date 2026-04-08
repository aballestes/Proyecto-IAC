###############################################################################
# MÓDULO: vsphere-cluster-compute
# Descripción: Gestiona configuración del cluster vSphere (AppIBM)
#              - Lee configuración actual del cluster (data source)
#              - Gestiona grupos de VMs y hosts para afinidad/anti-afinidad
#              - Crea reglas VM-Host opcionales
#
# Cluster contingencia: AppIBM (2 x ESXi 8)
# ID real: domain-c8541 | Resource Pool: resgroup-8542
###############################################################################

terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.6.0"
    }
  }
}

#------------------------------------------------------------------------------
# Data sources — leer cluster y datacenter existentes
#------------------------------------------------------------------------------
data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

#------------------------------------------------------------------------------
# Grupo de VMs (para reglas de afinidad/anti-afinidad)
# Solo se crea si vm_group_name está definido y vm_group_members no está vacío
#------------------------------------------------------------------------------
resource "vsphere_compute_cluster_vm_group" "vm_group" {
  count               = var.vm_group_name != "" && length(var.vm_group_members) > 0 ? 1 : 0
  name                = var.vm_group_name
  compute_cluster_id  = data.vsphere_compute_cluster.cluster.id
  virtual_machine_ids = var.vm_group_members
}

#------------------------------------------------------------------------------
# Grupo de hosts ESXi (para reglas de afinidad VM-Host)
# Solo se crea si host_group_name está definido y host_group_members no está vacío
#------------------------------------------------------------------------------
data "vsphere_host" "hosts" {
  # Solo resolvemos hosts si realmente se va a crear un host group
  for_each      = var.host_group_name != "" ? toset(var.host_group_members) : toset([])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_compute_cluster_host_group" "host_group" {
  count              = var.host_group_name != "" && length(var.host_group_members) > 0 ? 1 : 0
  name               = var.host_group_name
  compute_cluster_id = data.vsphere_compute_cluster.cluster.id
  host_system_ids    = [for h in data.vsphere_host.hosts : h.id]
}

#------------------------------------------------------------------------------
# Regla VM-Host (afinidad o anti-afinidad)
# Solo se crea si create_vm_host_rule = true y existen ambos grupos
#------------------------------------------------------------------------------
resource "vsphere_compute_cluster_vm_host_rule" "vm_host_rule" {
  count                        = var.create_vm_host_rule && var.vm_group_name != "" && var.host_group_name != "" ? 1 : 0
  name                         = var.vm_host_rule_name
  compute_cluster_id           = data.vsphere_compute_cluster.cluster.id
  vm_group_name                = vsphere_compute_cluster_vm_group.vm_group[0].name
  affinity_host_group_name     = var.vm_host_rule_affinity ? vsphere_compute_cluster_host_group.host_group[0].name : null
  anti_affinity_host_group_name = !var.vm_host_rule_affinity ? vsphere_compute_cluster_host_group.host_group[0].name : null
  mandatory                    = var.vm_host_rule_mandatory
}
