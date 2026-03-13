###############################################################################
# VARIABLES — Módulo vsphere-vm
###############################################################################

#---- Ubicación en vSphere ----
variable "datacenter_name" {
  description = "Nombre del datacenter en vCenter"
  type        = string
}

variable "datastore_name" {
  description = "Nombre del datastore (IBM FlashSystem presentado a vSphere)"
  type        = string
}

variable "resource_pool_path" {
  description = "Path del resource pool. Ej: cluster-app/Resources"
  type        = string
}

variable "target_host" {
  description = "FQDN o IP del host ESXi destino específico. Dejar vacío para DRS automático"
  type        = string
  default     = ""
}

variable "vm_folder" {
  description = "Folder en vCenter para organizar la VM. Ej: /produccion/app"
  type        = string
  default     = ""
}

#---- Identidad ----
variable "vm_name" {
  description = "Nombre de la VM en vCenter (debe ser único en el datacenter)"
  type        = string
}

variable "hostname" {
  description = "Hostname del SO (para customize). Si vacío, usa vm_name"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Dominio DNS para la VM"
  type        = string
  default     = "dominio.local"
}

#---- Compute ----
variable "num_cpus" {
  description = "Número total de vCPUs"
  type        = number
  default     = 2
  validation {
    condition     = var.num_cpus >= 1 && var.num_cpus <= 128
    error_message = "num_cpus debe estar entre 1 y 128."
  }
}

variable "num_cores_per_socket" {
  description = "Cores por socket. Total CPUs = num_cpus. Sockets = num_cpus / num_cores_per_socket"
  type        = number
  default     = 1
}

variable "memory_mb" {
  description = "Memoria RAM en MB. Ej: 4096 = 4GB, 8192 = 8GB, 16384 = 16GB"
  type        = number
  default     = 4096
  validation {
    condition     = var.memory_mb >= 512 && var.memory_mb <= 786432
    error_message = "memory_mb debe estar entre 512MB y 768GB."
  }
}

#---- SO ----
variable "guest_id" {
  description = "ID de SO guest VMware. Ej: rhel9_64Guest, windows2022srv_64Guest, ubuntu64Guest"
  type        = string
  default     = "rhel9_64Guest"
}

variable "firmware" {
  description = "Firmware de la VM: efi o bios"
  type        = string
  default     = "efi"
  validation {
    condition     = contains(["efi", "bios"], var.firmware)
    error_message = "firmware debe ser 'efi' o 'bios'."
  }
}

variable "efi_secure_boot_enabled" {
  description = "Habilitar Secure Boot (solo con firmware=efi)"
  type        = bool
  default     = false
}

#---- Red ----
variable "network_interfaces" {
  description = "Lista de nombres de portgroups vDS a conectar a la VM"
  type        = list(string)
  default     = ["VM Network"]
}

variable "network_adapter_type" {
  description = "Tipo de adaptador de red: vmxnet3 (recomendado) o e1000e"
  type        = string
  default     = "vmxnet3"
}

variable "static_ip" {
  description = "IP estática para customize. Dejar vacío para DHCP"
  type        = string
  default     = ""
}

variable "static_netmask" {
  description = "Máscara de red en bits. Ej: 24"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway por defecto"
  type        = string
  default     = ""
}

variable "dns_servers" {
  description = "Lista de servidores DNS"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

#---- Almacenamiento ----
variable "os_disk_size_gb" {
  description = "Tamaño del disco de SO en GB"
  type        = number
  default     = 60
}

variable "thin_provisioned" {
  description = "Provisioning delgado. true=thin, false=thick lazy zeroed"
  type        = bool
  default     = true
}

variable "eagerly_scrub" {
  description = "Thick eager zeroed. Solo aplica si thin_provisioned=false"
  type        = bool
  default     = false
}

variable "data_disks" {
  description = <<-EOT
    Lista de discos de datos adicionales.
    Ejemplo:
    [
      { size_gb = 100, thin_provisioned = true },
      { size_gb = 500, thin_provisioned = false, eagerly_scrub = true }
    ]
  EOT
  type = list(object({
    size_gb          = number
    thin_provisioned = optional(bool, true)
    eagerly_scrub    = optional(bool, false)
    datastore_name   = optional(string, null)
  }))
  default = []
}

variable "scsi_controller_count" {
  description = "Número de controladores SCSI. Con 1 controlador máximo 13 discos de datos. Aumentar a 2 para VMs con 14+ discos de datos."
  type        = number
  default     = 1
  validation {
    condition     = var.scsi_controller_count >= 1 && var.scsi_controller_count <= 4
    error_message = "scsi_controller_count debe estar entre 1 y 4."
  }
}

variable "scsi_type" {
  description = "Tipo de controlador SCSI: lsilogic-sas, pvscsi, lsilogic, buslogic"
  type        = string
  default     = "lsilogic-sas"
}

#---- Templates / Clonación ----
variable "template_uuid" {
  description = "UUID del template para clonar. Dejar vacío para import de VM existente"
  type        = string
  default     = ""
}

variable "customize" {
  description = "Aplicar customization spec al clonar desde template"
  type        = bool
  default     = false
}

#---- Tags y metadatos ----
variable "vm_tags" {
  description = "Lista de IDs de tags vSphere a aplicar a la VM"
  type        = list(string)
  default     = []
}

#---- Opciones avanzadas ----
variable "sync_time_with_host" {
  description = "Sincronizar hora de VM con ESXi host"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "CRÍTICO: Prevenir destrucción de VM con terraform destroy. Poner true en producción"
  type        = bool
  default     = true
}
