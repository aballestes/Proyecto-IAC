###############################################################################
# ENTORNO: CONTINGENCIA
# vCenter: vcenter-cont.dominio.local
# Cluster: cluster-cont (2 x ESXi 8 Update 3)
# VMs: ~30 VMs activas
# IBM FlashSystem 7300 → datastores presentados via iSCSI/FC
###############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.11.0"
    }
  }
}

#------------------------------------------------------------------------------
# Provider vSphere — Datacenter Contingencia
#------------------------------------------------------------------------------
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl   # true si certificado autofirmado
}

#------------------------------------------------------------------------------
# Data sources globales del datacenter
#------------------------------------------------------------------------------
data "vsphere_datacenter" "cont" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster_cont" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.cont.id
}

# Datastores IBM FlashSystem 7300
data "vsphere_datastore" "ds_cont_01" {
  name          = var.datastore_names[0]
  datacenter_id = data.vsphere_datacenter.cont.id
}

data "vsphere_datastore" "ds_cont_02" {
  count         = length(var.datastore_names) > 1 ? 1 : 0
  name          = var.datastore_names[1]
  datacenter_id = data.vsphere_datacenter.cont.id
}

# vDS Portgroups
data "vsphere_network" "portgroups" {
  for_each      = toset(var.portgroup_names)
  name          = each.value
  datacenter_id = data.vsphere_datacenter.cont.id
}

#------------------------------------------------------------------------------
# Módulo de VMs — Contingencia
# PASO 1: Importar VMs existentes con: terraform import module.vms_contingencia[\"vm-name\"].vsphere_virtual_machine.vm /datacenter/vm/vm-name
# PASO 2: Declarar VMs aquí para que el state las gestione
#------------------------------------------------------------------------------
module "vms_contingencia" {
  source   = "../../modules/vsphere-vm"
  for_each = var.vms_contingencia

  # Ubicación
  datacenter_name    = var.datacenter_name
  resource_pool_path = "${var.cluster_name}/Resources"

  # Seleccionar datastore basado en la configuración de cada VM
  datastore_name = lookup(each.value, "datastore", var.datastore_names[0])

  # Identidad
  vm_name   = each.key
  vm_folder = lookup(each.value, "folder", var.default_folder)

  # Compute — ESCALABLE vía variables
  num_cpus             = lookup(each.value, "num_cpus", 2)
  num_cores_per_socket = lookup(each.value, "num_cores_per_socket", 1)
  memory_mb            = lookup(each.value, "memory_mb", 4096)

  # SO
  guest_id = lookup(each.value, "guest_id", "rhel9_64Guest")
  firmware = lookup(each.value, "firmware", "efi")

  # Red
  network_interfaces = lookup(each.value, "networks", [var.portgroup_names[0]])

  # Almacenamiento
  os_disk_size_gb       = lookup(each.value, "os_disk_gb", 60)
  thin_provisioned      = lookup(each.value, "thin", true)
  data_disks            = lookup(each.value, "data_disks", [])
  scsi_controller_count = lookup(each.value, "scsi_controller_count", 1)
  scsi_type             = lookup(each.value, "scsi_type", "lsilogic-sas")

  # Tags
  vm_tags = lookup(each.value, "tags", [])
}

#------------------------------------------------------------------------------
# Resource Pool separado para servicios críticos de contingencia
#------------------------------------------------------------------------------
resource "vsphere_resource_pool" "rp_criticos" {
  name                    = "rp-criticos-contingencia"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_cont.resource_pool_id

  cpu_share_level    = "high"
  memory_share_level = "high"

  cpu_reservation    = 0
  memory_reservation = 0

  cpu_expandable    = true
  memory_expandable = true
}

resource "vsphere_resource_pool" "rp_devtest" {
  name                    = "rp-devtest-contingencia"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_cont.resource_pool_id

  cpu_share_level    = "low"
  memory_share_level = "low"

  cpu_expandable    = true
  memory_expandable = true
}

#------------------------------------------------------------------------------
# Tags para clasificación de VMs
#------------------------------------------------------------------------------
resource "vsphere_tag_category" "env_category" {
  name        = "Ambiente"
  cardinality = "SINGLE"
  description = "Clasificación por ambiente: produccion, contingencia, desarrollo, pruebas"

  associable_types = [
    "VirtualMachine",
    "Datacenter",
    "ClusterComputeResource",
  ]
}

resource "vsphere_tag" "tag_contingencia" {
  name        = "contingencia"
  category_id = vsphere_tag_category.env_category.id
  description = "VM pertenece al datacenter de contingencia"
}

resource "vsphere_tag" "tag_critico" {
  name        = "critico"
  category_id = vsphere_tag_category.env_category.id
  description = "Servicio crítico — requiere aprobación para cambios"
}

resource "vsphere_tag" "tag_devtest" {
  name        = "devtest"
  category_id = vsphere_tag_category.env_category.id
  description = "VM de desarrollo o pruebas"
}

#------------------------------------------------------------------------------
# Folder organizacional
#------------------------------------------------------------------------------
resource "vsphere_folder" "folder_contingencia" {
  path          = "contingencia"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.cont.id
}

resource "vsphere_folder" "folder_criticos" {
  path          = "contingencia/criticos"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.cont.id
  depends_on    = [vsphere_folder.folder_contingencia]
}

resource "vsphere_folder" "folder_devtest" {
  path          = "contingencia/devtest"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.cont.id
  depends_on    = [vsphere_folder.folder_contingencia]
}
