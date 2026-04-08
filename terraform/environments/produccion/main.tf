###############################################################################
# ENTORNO: PRODUCCIÓN
# vCenter: vcenter-prod.dominio.local
# Cluster App:  cluster-app (5 x ESXi 8 Update 3) — ~270 VMs
# Cluster DB:   cluster-db  (2 x ESXi 8 Update 3) — ~30 VMs críticas
# IBM FlashSystem 7300 → datastores presentados via iSCSI/FC
###############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.6.0"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

#------------------------------------------------------------------------------
# Data sources — Producción
#------------------------------------------------------------------------------
data "vsphere_datacenter" "prod" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster_app" {
  name          = var.cluster_app_name
  datacenter_id = data.vsphere_datacenter.prod.id
}

data "vsphere_compute_cluster" "cluster_db" {
  name          = var.cluster_db_name
  datacenter_id = data.vsphere_datacenter.prod.id
}

data "vsphere_datastore" "datastores" {
  for_each      = toset(var.datastore_names)
  name          = each.value
  datacenter_id = data.vsphere_datacenter.prod.id
}

data "vsphere_network" "portgroups" {
  for_each      = toset(var.portgroup_names)
  name          = each.value
  datacenter_id = data.vsphere_datacenter.prod.id
}

#------------------------------------------------------------------------------
# VMs — Cluster APP (~270 VMs)
# Subdivididas por categoría para facilitar gestión y aprobaciones de cambio
#------------------------------------------------------------------------------

# VMs de aplicación crítica
module "vms_app_criticos" {
  source   = "../../modules/vsphere-vm"
  for_each = var.vms_app_criticos

  datacenter_name    = var.datacenter_name
  resource_pool_path = "${var.cluster_app_name}/Resources/rp-criticos-prod"
  datastore_name     = lookup(each.value, "datastore", var.datastore_names[0])
  vm_name            = each.key
  folder             = lookup(each.value, "folder", "produccion/criticos")
  num_cpus           = lookup(each.value, "num_cpus", 4)
  num_cores_per_socket = lookup(each.value, "num_cores_per_socket", 1)
  memory_mb          = lookup(each.value, "memory_mb", 8192)
  guest_id           = lookup(each.value, "guest_id", "rhel9_64Guest")
  firmware           = lookup(each.value, "firmware", "efi")
  network_interfaces = lookup(each.value, "networks", [var.portgroup_names[0]])
  os_disk_size_gb    = lookup(each.value, "os_disk_gb", 80)
  thin_provisioned   = lookup(each.value, "thin", true)
  data_disks         = lookup(each.value, "data_disks", [])
  prevent_destroy    = true  # CRÍTICO: protección en producción
}

# VMs de aplicación no crítica
module "vms_app_standard" {
  source   = "../../modules/vsphere-vm"
  for_each = var.vms_app_standard

  datacenter_name    = var.datacenter_name
  resource_pool_path = "${var.cluster_app_name}/Resources/rp-standard-prod"
  datastore_name     = lookup(each.value, "datastore", var.datastore_names[0])
  vm_name            = each.key
  folder             = lookup(each.value, "folder", "produccion/aplicaciones")
  num_cpus           = lookup(each.value, "num_cpus", 2)
  num_cores_per_socket = lookup(each.value, "num_cores_per_socket", 1)
  memory_mb          = lookup(each.value, "memory_mb", 4096)
  guest_id           = lookup(each.value, "guest_id", "rhel9_64Guest")
  firmware           = lookup(each.value, "firmware", "efi")
  network_interfaces = lookup(each.value, "networks", [var.portgroup_names[0]])
  os_disk_size_gb    = lookup(each.value, "os_disk_gb", 60)
  thin_provisioned   = lookup(each.value, "thin", true)
  data_disks         = lookup(each.value, "data_disks", [])
  prevent_destroy    = true
}

# VMs de desarrollo y pruebas
module "vms_devtest" {
  source   = "../../modules/vsphere-vm"
  for_each = var.vms_devtest

  datacenter_name    = var.datacenter_name
  resource_pool_path = "${var.cluster_app_name}/Resources/rp-devtest-prod"
  datastore_name     = lookup(each.value, "datastore", var.datastore_names[1])
  vm_name            = each.key
  folder             = lookup(each.value, "folder", "produccion/devtest")
  num_cpus           = lookup(each.value, "num_cpus", 2)
  num_cores_per_socket = lookup(each.value, "num_cores_per_socket", 1)
  memory_mb          = lookup(each.value, "memory_mb", 2048)
  guest_id           = lookup(each.value, "guest_id", "rhel9_64Guest")
  firmware           = lookup(each.value, "firmware", "efi")
  network_interfaces = lookup(each.value, "networks", [var.portgroup_names[2]])
  os_disk_size_gb    = lookup(each.value, "os_disk_gb", 60)
  thin_provisioned   = lookup(each.value, "thin", true)
  data_disks         = lookup(each.value, "data_disks", [])
  prevent_destroy    = false  # Devtest puede destruirse controladamente
}

#------------------------------------------------------------------------------
# VMs — Cluster DB (~30 VMs críticas de base de datos)
#------------------------------------------------------------------------------
module "vms_db_criticos" {
  source   = "../../modules/vsphere-vm"
  for_each = var.vms_db_criticos

  datacenter_name    = var.datacenter_name
  resource_pool_path = "${var.cluster_db_name}/Resources/rp-db-prod"
  datastore_name     = lookup(each.value, "datastore", var.datastore_names[2])
  vm_name            = each.key
  folder             = lookup(each.value, "folder", "produccion/bases-datos")
  num_cpus           = lookup(each.value, "num_cpus", 8)
  num_cores_per_socket = lookup(each.value, "num_cores_per_socket", 2)
  memory_mb          = lookup(each.value, "memory_mb", 32768)
  guest_id           = lookup(each.value, "guest_id", "rhel9_64Guest")
  firmware           = lookup(each.value, "firmware", "efi")
  network_interfaces = lookup(each.value, "networks", [var.portgroup_names[1]])
  os_disk_size_gb    = lookup(each.value, "os_disk_gb", 100)
  thin_provisioned   = lookup(each.value, "thin", false)  # Thick para DB (mejor IOPS)
  eagerly_scrub      = lookup(each.value, "eagerly_scrub", false)
  data_disks         = lookup(each.value, "data_disks", [])
  prevent_destroy    = true  # DB CRÍTICO: protección máxima
}

#------------------------------------------------------------------------------
# Resource Pools — Producción
#------------------------------------------------------------------------------
resource "vsphere_resource_pool" "rp_criticos_prod" {
  name                    = "rp-criticos-prod"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_app.resource_pool_id
  cpu_share_level         = "high"
  memory_share_level      = "high"
  cpu_expandable          = true
  memory_expandable       = true
}

resource "vsphere_resource_pool" "rp_standard_prod" {
  name                    = "rp-standard-prod"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_app.resource_pool_id
  cpu_share_level         = "normal"
  memory_share_level      = "normal"
  cpu_expandable          = true
  memory_expandable       = true
}

resource "vsphere_resource_pool" "rp_devtest_prod" {
  name                    = "rp-devtest-prod"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_app.resource_pool_id
  cpu_share_level         = "low"
  memory_share_level      = "low"
  cpu_expandable          = true
  memory_expandable       = true
}

resource "vsphere_resource_pool" "rp_db_prod" {
  name                    = "rp-db-prod"
  parent_resource_pool_id = data.vsphere_compute_cluster.cluster_db.resource_pool_id
  cpu_share_level         = "high"
  memory_share_level      = "high"
  cpu_reservation         = 0
  memory_reservation      = 0
  cpu_expandable          = true
  memory_expandable       = true
}

#------------------------------------------------------------------------------
# Tags — Producción
#------------------------------------------------------------------------------
resource "vsphere_tag_category" "env_prod" {
  name        = "Ambiente-Prod"
  cardinality = "SINGLE"
  description = "Clasificación producción: critico, standard, devtest, db"
  associable_types = ["VirtualMachine", "Datacenter", "ClusterComputeResource"]
}

resource "vsphere_tag" "tag_prod_critico"  { name = "prod-critico",  category_id = vsphere_tag_category.env_prod.id }
resource "vsphere_tag" "tag_prod_standard" { name = "prod-standard", category_id = vsphere_tag_category.env_prod.id }
resource "vsphere_tag" "tag_prod_devtest"  { name = "prod-devtest",  category_id = vsphere_tag_category.env_prod.id }
resource "vsphere_tag" "tag_prod_db"       { name = "prod-db",       category_id = vsphere_tag_category.env_prod.id }

#------------------------------------------------------------------------------
# Folders organizacionales — Producción
#------------------------------------------------------------------------------
resource "vsphere_folder" "folder_prod"       { path = "produccion",               type = "vm", datacenter_id = data.vsphere_datacenter.prod.id }
resource "vsphere_folder" "folder_criticos"   { path = "produccion/criticos",       type = "vm", datacenter_id = data.vsphere_datacenter.prod.id, depends_on = [vsphere_folder.folder_prod] }
resource "vsphere_folder" "folder_aplicaciones" { path = "produccion/aplicaciones", type = "vm", datacenter_id = data.vsphere_datacenter.prod.id, depends_on = [vsphere_folder.folder_prod] }
resource "vsphere_folder" "folder_db"         { path = "produccion/bases-datos",    type = "vm", datacenter_id = data.vsphere_datacenter.prod.id, depends_on = [vsphere_folder.folder_prod] }
resource "vsphere_folder" "folder_devtest"    { path = "produccion/devtest",        type = "vm", datacenter_id = data.vsphere_datacenter.prod.id, depends_on = [vsphere_folder.folder_prod] }
