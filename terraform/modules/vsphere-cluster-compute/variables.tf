###############################################################################
# MÓDULO: vsphere-cluster-compute — Variables
###############################################################################

variable "datacenter_name" {
  description = "Nombre del datacenter en vCenter"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster de cómputo en vCenter"
  type        = string
}

variable "vm_group_name" {
  description = "Nombre del grupo de VMs para reglas de afinidad (opcional)"
  type        = string
  default     = ""
}

variable "host_group_name" {
  description = "Nombre del grupo de hosts para reglas de afinidad (opcional)"
  type        = string
  default     = ""
}

variable "vm_group_members" {
  description = "Lista de IDs de VMs que forman parte del grupo"
  type        = list(string)
  default     = []
}

variable "host_group_members" {
  description = "Lista de nombres de hosts ESXi que forman parte del grupo"
  type        = list(string)
  default     = []
}

variable "create_vm_host_rule" {
  description = "Si true, crea una regla de afinidad VM-Host"
  type        = bool
  default     = false
}

variable "vm_host_rule_name" {
  description = "Nombre de la regla VM-Host (requerido si create_vm_host_rule = true)"
  type        = string
  default     = ""
}

variable "vm_host_rule_mandatory" {
  description = "Si la regla VM-Host es obligatoria (true) o recomendación (false)"
  type        = bool
  default     = false
}

variable "vm_host_rule_affinity" {
  description = "Tipo de regla: true = afinidad (VMs deben ir a esos hosts), false = anti-afinidad"
  type        = bool
  default     = true
}
