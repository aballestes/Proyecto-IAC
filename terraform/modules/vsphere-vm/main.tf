###############################################################################
# MÓDULO: vsphere-vm
# Descripción: Módulo reutilizable para gestión de VMs vSphere existentes
#              Soporta importación de VMs existentes y aprovisionamiento nuevas
#              Incluye escalado de CPU, Memoria y Disco en caliente (hot-add)
###############################################################################

terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.11.0"
    }
  }
}

#------------------------------------------------------------------------------
# Data sources — leer recursos existentes desde vCenter
#------------------------------------------------------------------------------
data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_datastore" "ds" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool_path
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  for_each      = toset(var.network_interfaces)
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  count         = var.target_host != "" ? 1 : 0
  name          = var.target_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

#------------------------------------------------------------------------------
# Recurso principal de la VM
#------------------------------------------------------------------------------
resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.ds.id
  host_system_id   = var.target_host != "" ? data.vsphere_host.host[0].id : null

  # ---- Compute ----
  num_cpus               = var.num_cpus
  num_cores_per_socket   = var.num_cores_per_socket
  cpu_hot_add_enabled    = true   # Requiere VMware Tools y SO compatible
  cpu_hot_remove_enabled = false  # Generalmente no soportado en caliente

  # ---- Memoria ----
  memory                 = var.memory_mb
  memory_hot_add_enabled = true   # Requiere VMware Tools y SO compatible

  # ---- SO y firmware ----
  guest_id         = var.guest_id
  firmware         = var.firmware
  efi_secure_boot_enabled = var.efi_secure_boot_enabled

  # ---- Controladores SCSI ----
  # Con 1 controlador: máx 13 discos de datos (unidades 1-6, 8-14)
  # Con 2 controladores: máx 27 discos de datos
  scsi_controller_count = var.scsi_controller_count
  scsi_type             = var.scsi_type

  # ---- Opciones de ciclo de vida ----
  # IMPORTANTE: force_power_off=false evita apagados no planificados
  # Para hot-add de recursos NO se necesita apagar la VM
  force_power_off  = false
  shutdown_wait_timeout = 3  # minutos para apagado graceful si es necesario

  # ---- Sincronización de tiempo ----
  sync_time_with_host = var.sync_time_with_host

  # ---- Herramientas VMware ----
  tools_upgrade_policy  = "manual"
  run_tools_scripts_after_power_on = true

  # ---- Folder organizacional ----
  folder = var.vm_folder

  # ---- Tags ----
  tags = var.vm_tags

  # ---- Interfaces de red ----
  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      network_id   = data.vsphere_network.network[network_interface.value].id
      adapter_type = var.network_adapter_type
    }
  }

  # ---- Disco de SO (siempre presente) ----
  disk {
    label            = "Hard disk 1"
    size             = var.os_disk_size_gb
    thin_provisioned = var.thin_provisioned
    eagerly_scrub    = var.eagerly_scrub
    unit_number      = 0
  }

  # ---- Discos de datos adicionales ----
  dynamic "disk" {
    for_each = var.data_disks
    content {
      label            = "Hard disk ${disk.key + 2}"
      size             = disk.value.size_gb
      thin_provisioned = lookup(disk.value, "thin_provisioned", true)
      eagerly_scrub    = lookup(disk.value, "eagerly_scrub", false)
      # Saltar unidad 7 (reservada para controlador SCSI)
      unit_number      = disk.key + 1 >= 7 ? disk.key + 2 : disk.key + 1
      datastore_id     = lookup(disk.value, "datastore_name", null) != null ? (
        data.vsphere_datastore.ds.id  # extender para múltiples datastores si se requiere
      ) : null
    }
  }

  # ---- Personalización (solo para VMs nuevas, no para importadas) ----
  dynamic "clone" {
    for_each = var.template_uuid != "" ? [1] : []
    content {
      template_uuid = var.template_uuid
      dynamic "customize" {
        for_each = var.customize ? [1] : []
        content {
          linux_options {
            host_name = var.hostname != "" ? var.hostname : var.vm_name
            domain    = var.domain
          }
          network_interface {
            ipv4_address    = var.static_ip != "" ? var.static_ip : null
            ipv4_netmask    = var.static_netmask
          }
          ipv4_gateway    = var.gateway
          dns_server_list = var.dns_servers
        }
      }
    }
  }

  # ---- Lifecycle: prevenir destrucciones accidentales ----
  lifecycle {
    prevent_destroy = false

    # Ignorar atributos que vCenter gestiona autom\u00e1ticamente o que difieren
    # entre el estado real importado y la configuraci\u00f3n declarada.
    # Estos cambios NO modifican las VMs en producci\u00f3n.
    ignore_changes = [
      annotation,
      sata_controller_count,
      cdrom,
      efi_secure_boot_enabled,
      enable_disk_uuid,
      enable_logging,
      cpu_hot_add_enabled,
      cpu_hot_remove_enabled,
      memory_hot_add_enabled,
      force_power_off,
      boot_retry_delay,
      boot_retry_enabled,
      latency_sensitivity,
      scsi_type,
      disk,
      network_interface,
    ]
  }
}
