###############################################################################
# TERRAFORM.TFVARS — Contingencia
# ADVERTENCIA: Este archivo contiene valores sensibles.
# NO commitear a Git. Agregar a .gitignore.
# Usar variables de entorno para credenciales:
#   export TF_VAR_vsphere_user="svc-terraform@vsphere.local"
#   export TF_VAR_vsphere_password="PASSWORD_SEGURO"
###############################################################################

vsphere_server       = "vcenter-cont.dominio.local"
allow_unverified_ssl = true
datacenter_name      = "DC-Contingencia"
cluster_name         = "cluster-cont"

datastore_names = [
  "FS7300-CONT-DS01",
  "FS7300-CONT-DS02"
]

portgroup_names = [
  "PG-APP-CONT-VLAN100",
  "PG-ADMIN-VLAN10",
  "PG-DB-CONT-VLAN110",
  "PG-BACKUP-VLAN200"
]

#------------------------------------------------------------------------------
# INVENTARIO DE VMs — CONTINGENCIA
# Completar con el inventario real obtenido por script de discovery (Fase 0)
# Formato: "nombre-exacto-en-vcenter" = { recursos }
#------------------------------------------------------------------------------
vms_contingencia = {
  # ---- Ejemplo: VM Linux crítica ----
  "vm-app-cont-01" = {
    num_cpus  = 4
    memory_mb = 8192
    guest_id  = "rhel9_64Guest"
    firmware  = "efi"
    os_disk_gb = 80
    networks  = ["PG-APP-CONT-VLAN100"]
    folder    = "contingencia/criticos"
    tags      = []  # completar con IDs de tags después de crearlos
    data_disks = [
      { size_gb = 200, thin_provisioned = true }
    ]
  }

  # ---- Ejemplo: VM Windows ----
  "vm-win-cont-01" = {
    num_cpus  = 2
    memory_mb = 4096
    guest_id  = "windows2022srv_64Guest"
    firmware  = "efi"
    os_disk_gb = 80
    networks  = ["PG-APP-CONT-VLAN100"]
    folder    = "contingencia"
  }

  # ---- Ejemplo: VM base de datos ----
  "vm-db-cont-01" = {
    num_cpus  = 8
    memory_mb = 32768
    guest_id  = "rhel9_64Guest"
    firmware  = "efi"
    os_disk_gb = 100
    networks  = ["PG-DB-CONT-VLAN110"]
    folder    = "contingencia/criticos"
    data_disks = [
      { size_gb = 500, thin_provisioned = false, eagerly_scrub = false },
      { size_gb = 200, thin_provisioned = false, eagerly_scrub = false }
    ]
  }

  # ---- Continuar con el resto de las 30 VMs de contingencia ----
  # INSTRUCCIÓN: Ejecutar script scripts/discovery/vm_inventory.py para generar
  # automáticamente este bloque desde el inventario real de vCenter
}
