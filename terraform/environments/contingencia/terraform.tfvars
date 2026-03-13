###############################################################################
# TERRAFORM.TFVARS — Contingencia
# ADVERTENCIA: Este archivo contiene valores sensibles.
# NO commitear a Git. Agregar a .gitignore.
# Usar variables de entorno para credenciales:
#   export TF_VAR_vsphere_user="svc-terraform@vsphere.local"
#   export TF_VAR_vsphere_password="PASSWORD_SEGURO"
###############################################################################

vsphere_server       = "192.168.77.152"
vsphere_user         = "aballestes@gnb.loc"
vsphere_password     = "Eyxnx5s56l*******"
allow_unverified_ssl = true
datacenter_name      = "IBM"
cluster_name         = "AppIBM"

datastore_names = [
  "POOL",
  "REPLIC",
  "VCENTERC8",
  "POSTILIONDES",
  "EXC",
  "esx7appc"
]

portgroup_names = [
  "App_Contingencia_NEG_10",
  "App_Contingencia_NEG_194",
  "App_Contingencia_NEG_195",
  "App_Contingencia_INFO_22",
  "App_Contingencia_INFO_77",
  "App_Contingencia_INFO_160",
  "App_Contingencia_INFO_161",
  "App_Contingencia_INFO_193",
  "App_Contingencia_INFO_196",
  "App_Contingencia_SVB_21",
  "App_Contingencia_INFO_700",
  "FW-vlanid-3700-SG-Portgroup",
  "FW-vlanid-3702-SG-Portgroup",
  "SG-FW-trunk-pg"
]

#------------------------------------------------------------------------------
# INVENTARIO DE VMs — CONTINGENCIA
# Completar con el inventario real obtenido por script de discovery (Fase 0)
# Formato: "nombre-exacto-en-vcenter" = { recursos }
#------------------------------------------------------------------------------
vms_contingencia = {

  # Power: poweredOn | IP: 10.10.10.113 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: SUSE Linux Enterprise 15 (64-bit)
  "NGINXPRXLIBPRDHA" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 4096
    guest_id             = "sles15_64Guest"
    firmware             = "efi"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "REPLIC"
    networks             = ["App_Contingencia_NEG_10"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.144.42 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: SUSE Linux Enterprise 15 (64-bit)
  "NGIPRUP02MRPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 4096
    guest_id             = "sles15_64Guest"
    firmware             = "efi"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_SVB_21"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false }
    ]
  }

  # Power: poweredOff | IP:  | Host: esx6appc.gnb.loc
  # Tools: toolsNotRunning | SO: SUSE Linux Enterprise 15 (64-bit)
  "NGINXATALLAPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 4096
    guest_id             = "sles15_64Guest"
    firmware             = "efi"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_SVB_21"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.195.9 | Host: esx6appc.gnb.loc
  # Tools: toolsOld | SO: Microsoft Windows Server 2016 (64-bit)
  "SAGSNLC" = {
    num_cpus             = 4
    num_cores_per_socket = 1
    memory_mb            = 16384
    guest_id             = "windows9Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 80
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_NEG_195"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 100, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.195.16 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2012 (64-bit)
  "AWPC" = {
    num_cpus             = 8
    num_cores_per_socket = 1
    memory_mb            = 16384
    guest_id             = "windows8Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 80
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_NEG_195"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 100, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.195.6 | Host: esx6appc.gnb.loc
  # Tools: toolsOld | SO: Microsoft Windows Server 2012 (64-bit)
  "SAAC" = {
    num_cpus             = 8
    num_cores_per_socket = 1
    memory_mb            = 16384
    guest_id             = "windows8Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 80
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_NEG_195"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 140, thin_provisioned = false },
      { size_gb = 80, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.144.26 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "POSTIBDREALPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 16384
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POSTILIONDES"
    networks             = ["App_Contingencia_SVB_21"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false },
      { size_gb = 100, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 20, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.144.27 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "POSTIBDOFFPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 16384
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POSTILIONDES"
    networks             = ["App_Contingencia_SVB_21"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 20, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.144.28 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "POSTIBDNIXPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 16384
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POSTILIONDES"
    networks             = ["FW-vlanid-3702-SG-Portgroup"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false },
      { size_gb = 100, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 20, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.144.41 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: SUSE Linux Enterprise 15 (64-bit)
  "NGIPRUP01MRPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 4096
    guest_id             = "sles15_64Guest"
    firmware             = "efi"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_SVB_21"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.238.1 | Host: esx6appc.gnb.loc
  # Tools: toolsOld | SO: Other (32-bit)
  "LT" = {
    num_cpus             = 8
    num_cores_per_socket = 1
    memory_mb            = 16384
    guest_id             = "otherGuest"
    firmware             = "bios"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_196"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 20, thin_provisioned = false },
      { size_gb = 250, thin_provisioned = false },
      { size_gb = 20, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.194.34 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Oracle Linux 7 (64-bit)
  "MGORACLEC" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 10240
    guest_id             = "oracleLinux7_64Guest"
    firmware             = "bios"
    os_disk_gb           = 40
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_NEG_194"]
    folder               = "Discovered virtual machine"
    data_disks           = []
  }

  # Power: poweredOn | IP: 192.168.144.29 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "POSTIAPPREP" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 8192
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POSTILIONDES"
    networks             = ["FW-vlanid-3700-SG-Portgroup"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 60, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.196.145 | Host: esx6appc.gnb.loc
  # Tools: toolsOld | SO: Microsoft Windows Server 2012 (64-bit)
  "VAULTC" = {
    num_cpus             = 4
    num_cores_per_socket = 1
    memory_mb            = 12288
    guest_id             = "windows8Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 200
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_196"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 700, thin_provisioned = false }
    ]
  }


  # Power: poweredOn | IP: 192.168.196.21 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "FRC" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 10240
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_196"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 100, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.193.23 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2012 (64-bit)
  "EX3" = {
    num_cpus             = 12
    num_cores_per_socket = 1
    memory_mb            = 40960
    guest_id             = "windows8Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 320
    thin                 = true
    datastore            = "EXC"
    networks             = ["App_Contingencia_INFO_196", "App_Contingencia_INFO_700", "App_Contingencia_INFO_193"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false },
      { size_gb = 500, thin_provisioned = false },
      { size_gb = 120, thin_provisioned = false },
      { size_gb = 170, thin_provisioned = false },
      { size_gb = 350, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.196.163 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "ADCONNETC" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 8192
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_196"]
    folder               = "Discovered virtual machine"
    data_disks           = []
  }

  # Power: poweredOn | IP: 192.168.144.135 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Microsoft Windows Server 2022 (64-bit)
  "ADC" = {
    num_cpus             = 3
    num_cores_per_socket = 1
    memory_mb            = 12288
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_22"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 100, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.196.17 | Host: esx7appc.gnb.loc
  # Tools: toolsOld | SO: Microsoft Windows Server 2022 (64-bit)
  "PSMC" = {
    num_cpus             = 8
    num_cores_per_socket = 2
    memory_mb            = 18432
    guest_id             = "windows2019srvNext_64Guest"
    firmware             = "efi"
    os_disk_gb           = 70
    thin                 = true
    datastore            = "POOL"
    networks             = ["App_Contingencia_INFO_196"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false }
    ]
  }

}

#------------------------------------------------------------------------------
# VMs EXCLUIDAS DE TERRAFORM — No gestionar con IaC
# Razón: infraestructura de plataforma o appliances gestionados externamente
#------------------------------------------------------------------------------
#
# VCSAC          — VMware vCenter Server Appliance (192.168.77.152)
#                  Gestionado por VMware, no por Terraform
#
# VROPSPREP      — VMware Aria Operations 8.18.3 / Photon OS (192.168.77.108)
#                  Infraestructura de monitoreo VMware, excluida de IaC
#
# vSOMC          — Ubuntu Linux (192.168.77.190)
#                  Excluida de gestión Terraform
#
# PVWAC          — Windows Server 2012 / PVware AC (192.168.196.18)
#                  Excluida de gestión Terraform
#
# SG_vDSM_0_21   — Hillstone Security Service (192.168.160.37)
#                  Gestionado exclusivamente por Hillstone, no modificar
# SG_vSSM_0_17   — Hillstone Security Service (192.168.160.35)
# SG_vSSM_0_19   — Hillstone Security Service (192.168.160.36)
# SG_vSCM_0_1    — Hillstone Security Service (192.168.160.33)
# SG_vSCM_0_2    — Hillstone Security Service (192.168.160.34)
