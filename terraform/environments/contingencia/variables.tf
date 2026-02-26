###############################################################################
# VARIABLES — Entorno Contingencia
###############################################################################

#---- Conexión vCenter ----
variable "vsphere_user" {
  description = "Usuario de servicio vCenter. Preferir variable de entorno: TF_VAR_vsphere_user"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "Password vCenter. Preferir variable de entorno: TF_VAR_vsphere_password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "FQDN o IP del vCenter de contingencia"
  type        = string
  default     = "vcenter-cont.dominio.local"
}

variable "allow_unverified_ssl" {
  description = "Permitir certificados SSL autofirmados en vCenter"
  type        = bool
  default     = true
}

#---- Datacenter y Cluster ----
variable "datacenter_name" {
  description = "Nombre del datacenter en vCenter contingencia"
  type        = string
  default     = "DC-Contingencia"
}

variable "cluster_name" {
  description = "Nombre del cluster de compute en contingencia"
  type        = string
  default     = "cluster-cont"
}

#---- Almacenamiento IBM FlashSystem 7300 ----
variable "datastore_names" {
  description = "Lista de datastores presentados por IBM FS7300. El primero es el default."
  type        = list(string)
  default     = [
    "FS7300-CONT-DS01",
    "FS7300-CONT-DS02"
  ]
}

#---- Red vDS ----
variable "portgroup_names" {
  description = "Portgroups del vDS disponibles. El primero es el default."
  type        = list(string)
  default     = [
    "PG-PRODUCCION-CONT-VLAN100",
    "PG-ADMINISTRACION-VLAN10",
    "PG-BACKUP-VLAN200"
  ]
}

#---- Folders ----
variable "default_folder" {
  description = "Folder default para VMs sin folder explícito"
  type        = string
  default     = "contingencia"
}

#---- Definición de VMs existentes (importar con terraform import) ----
# Esta variable define el estado DESEADO de cada VM.
# Al hacer terraform import, Terraform leerá el estado ACTUAL y lo comparará.
# Cualquier diferencia aparecerá en terraform plan.
variable "vms_contingencia" {
  description = <<-EOT
    Mapa de VMs del datacenter de contingencia.
    Key: nombre exacto de la VM en vCenter
    Value: configuración de recursos
    
    IMPORTANTE: Estos valores deben coincidir con el estado actual ANTES de importar.
    Después de importar, modificar estos valores generará cambios controlados.
  EOT
  type = map(object({
    num_cpus             = optional(number, 2)
    num_cores_per_socket = optional(number, 1)
    memory_mb            = optional(number, 4096)
    guest_id             = optional(string, "rhel9_64Guest")
    firmware             = optional(string, "efi")
    os_disk_gb           = optional(number, 60)
    thin                 = optional(bool, true)
    datastore            = optional(string, null)
    networks             = optional(list(string), null)
    folder               = optional(string, "contingencia")
    tags                 = optional(list(string), [])
    data_disks = optional(list(object({
      size_gb          = number
      thin_provisioned = optional(bool, true)
      eagerly_scrub    = optional(bool, false)
    })), [])
  }))

  # Ejemplo con valores por defecto — COMPLETAR con inventario real
  default = {}
}
