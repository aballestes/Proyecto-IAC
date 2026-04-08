# Generado automáticamente por vm_inventory.py
# Fecha: 2026-03-03T14:54:43.928142
# Total VMs: 28

vms_contingencia = {

  # Power: poweredOn | IP: 10.10.10.113 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: SUSE Linux Enterprise 15 (64-bit)
  "NGINXPRXLIBPRD2PREP" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 4096
    guest_id             = "sles15_64Guest"
    firmware             = "efi"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "REPLIC"
    networks             = ["dvportgroup-9552"]
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
    networks             = ["dvportgroup-29589"]
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
    networks             = ["dvportgroup-29589"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 50, thin_provisioned = false },
      { size_gb = 50, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.77.108 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Other 3.x or later Linux (64-bit)
  "VROPSPREP" = {
    num_cpus             = 4
    num_cores_per_socket = 1
    memory_mb            = 16384
    guest_id             = "other3xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 20
    thin                 = true
    datastore            = "VCENTERC8"
    networks             = ["dvportgroup-8556"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 250, thin_provisioned = false },
      { size_gb = 4, thin_provisioned = false }
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
    networks             = ["dvportgroup-9547"]
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
    networks             = ["dvportgroup-9547"]
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
    networks             = ["dvportgroup-9547"]
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
    networks             = ["dvportgroup-29589"]
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
    networks             = ["dvportgroup-29589"]
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
    networks             = ["dvportgroup-29593"]
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
    networks             = ["dvportgroup-29589"]
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
    networks             = ["dvportgroup-9548"]
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
    networks             = ["dvportgroup-9546"]
    folder               = "Discovered virtual machine"
    data_disks           = []
  }

  # Power: poweredOn | IP: 192.168.160.37 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Other 2.6.x Linux (64-bit)
  "SG_vDSM_0_21" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 6144
    guest_id             = "other26xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 1
    thin                 = true
    datastore            = "POOL"
    networks             = ["Disconnected", "Disconnected", "dvportgroup-9577", "dvportgroup-9576"]
    folder               = "SG"
    data_disks           = [
      { size_gb = 4, thin_provisioned = true }
    ]
  }

  # Power: poweredOn | IP: 192.168.160.35 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Other 2.6.x Linux (64-bit)
  "SG_vSSM_0_17" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 6144
    guest_id             = "other26xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 1
    thin                 = true
    datastore            = "POOL"
    networks             = ["dvportgroup-15557", "Disconnected", "Disconnected", "dvportgroup-9577", "dvportgroup-29590", "Disconnected", "Disconnected", "dvportgroup-9576", "Disconnected", "Disconnected"]
    folder               = "SG"
    data_disks           = [
      { size_gb = 4, thin_provisioned = true }
    ]
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
    networks             = ["dvportgroup-29591"]
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
    networks             = ["dvportgroup-9548"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 700, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.160.34 | Host: esx6appc.gnb.loc
  # Tools: toolsOk | SO: Other 2.6.x Linux (64-bit)
  "SG_vSCM_0_2" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 8192
    guest_id             = "other26xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 1
    thin                 = true
    datastore            = "POOL"
    networks             = ["dvportgroup-9577", "dvportgroup-9576"]
    folder               = "SG"
    data_disks           = [
      { size_gb = 16, thin_provisioned = true }
    ]
  }

  # Power: poweredOn | IP: 192.168.77.152 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Other 3.x or later Linux (64-bit)
  "VCSAC" = {
    num_cpus             = 16
    num_cores_per_socket = 1
    memory_mb            = 39936
    guest_id             = "other3xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 48
    thin                 = true
    datastore            = "VCENTERC8"
    networks             = ["dvportgroup-8556"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 7, thin_provisioned = true },
      { size_gb = 50, thin_provisioned = true },
      { size_gb = 100, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 200, thin_provisioned = true },
      { size_gb = 10, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 100, thin_provisioned = true },
      { size_gb = 100, thin_provisioned = true },
      { size_gb = 200, thin_provisioned = true },
      { size_gb = 25, thin_provisioned = true },
      { size_gb = 100, thin_provisioned = true },
      { size_gb = 300, thin_provisioned = true }
    ]
  }

  # Power: poweredOn | IP: 192.168.196.18 | Host: esx7appc.gnb.loc
  # Tools: toolsOld | SO: Microsoft Windows Server 2012 (64-bit)
  "PVWAC" = {
    num_cpus             = 16
    num_cores_per_socket = 1
    memory_mb            = 24576
    guest_id             = "windows8Server64Guest"
    firmware             = "bios"
    os_disk_gb           = 80
    thin                 = true
    datastore            = "POOL"
    networks             = ["dvportgroup-9548"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.160.33 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Other 2.6.x Linux (64-bit)
  "SG_vSCM_0_1" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 8192
    guest_id             = "other26xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 1
    thin                 = true
    datastore            = "POOL"
    networks             = ["dvportgroup-9577", "dvportgroup-9576"]
    folder               = "SG"
    data_disks           = [
      { size_gb = 16, thin_provisioned = true }
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
    networks             = ["dvportgroup-9548"]
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
    networks             = ["dvportgroup-9548", "dvportgroup-9553", "dvportgroup-9545"]
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
    networks             = ["dvportgroup-9548"]
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
    networks             = ["dvportgroup-9544"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 30, thin_provisioned = false },
      { size_gb = 100, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.77.190 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Ubuntu Linux (64-bit)
  "vSOMC" = {
    num_cpus             = 2
    num_cores_per_socket = 2
    memory_mb            = 6144
    guest_id             = "ubuntu64Guest"
    firmware             = "bios"
    os_disk_gb           = 60
    thin                 = true
    datastore            = "POOL"
    networks             = ["dvportgroup-8556", "dvportgroup-9576"]
    folder               = "Discovered virtual machine"
    data_disks           = []
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
    networks             = ["dvportgroup-9548"]
    folder               = "Discovered virtual machine"
    data_disks           = [
      { size_gb = 80, thin_provisioned = false }
    ]
  }

  # Power: poweredOn | IP: 192.168.160.36 | Host: esx7appc.gnb.loc
  # Tools: toolsOk | SO: Other 2.6.x Linux (64-bit)
  "SG_vSSM_0_19" = {
    num_cpus             = 2
    num_cores_per_socket = 1
    memory_mb            = 6144
    guest_id             = "other26xLinux64Guest"
    firmware             = "bios"
    os_disk_gb           = 1
    thin                 = true
    datastore            = "esx7appc"
    networks             = ["dvportgroup-15557", "Disconnected", "Disconnected", "dvportgroup-9577", "Disconnected", "Disconnected", "Disconnected", "dvportgroup-9576", "Disconnected", "Disconnected"]
    folder               = "SG"
    data_disks           = [
      { size_gb = 4, thin_provisioned = true }
    ]
  }
}