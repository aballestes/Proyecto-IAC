###############################################################################
# VARIABLES — Entorno Producción
###############################################################################

variable "vsphere_user"     { type = string; sensitive = true; description = "Usuario servicio vCenter prod" }
variable "vsphere_password" { type = string; sensitive = true; description = "Password vCenter prod" }

variable "vsphere_server" {
  type    = string
  default = "192.168.77.153"
}

variable "allow_unverified_ssl" {
  type    = bool
  default = true
}

variable "datacenter_name" {
  type    = string
  default = "DC-Produccion"
}

variable "cluster_app_name" {
  description = "Nombre del cluster de aplicaciones (5 ESXi)"
  type        = string
  default     = "cluster-app"
}

variable "cluster_db_name" {
  description = "Nombre del cluster de bases de datos (2 ESXi)"
  type        = string
  default     = "cluster-db"
}

variable "datastore_names" {
  description = "Datastores IBM FS7300. [0]=app, [1]=devtest, [2]=db"
  type        = list(string)
  default     = [
    "FS7300-PROD-DS01",
    "FS7300-PROD-DS02",
    "FS7300-PROD-DB01",
    "FS7300-PROD-DB02"
  ]
}

variable "portgroup_names" {
  description = "Portgroups vDS producción. [0]=app, [1]=db, [2]=devtest, [3]=admin"
  type        = list(string)
  default     = [
    "PG-APP-PROD-VLAN100",
    "PG-DB-PROD-VLAN110",
    "PG-DEVTEST-VLAN300",
    "PG-ADMIN-VLAN10",
    "PG-BACKUP-VLAN200"
  ]
}

#---- Mapas de VMs (completar con discovery script) ----
variable "vms_app_criticos" {
  description = "VMs críticas del cluster de aplicaciones"
  type        = map(any)
  default     = {}
}

variable "vms_app_standard" {
  description = "VMs estándar del cluster de aplicaciones"
  type        = map(any)
  default     = {}
}

variable "vms_devtest" {
  description = "VMs de desarrollo y pruebas"
  type        = map(any)
  default     = {}
}

variable "vms_db_criticos" {
  description = "VMs críticas del cluster de bases de datos"
  type        = map(any)
  default     = {}
}
