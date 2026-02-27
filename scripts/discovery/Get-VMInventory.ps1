<#
.SYNOPSIS
    Inventario automático de VMs en VMware vCenter
    
.DESCRIPTION
    Este script recopila información detallada de todas las VMs en un vCenter
    y genera un archivo CSV con la configuración completa de cada VM.
    Útil para fase 0 de implementación de IaC (Infraestructura como Código).
    
.PARAMETER VCenter
    FQDN o IP del servidor vCenter
    
.PARAMETER Datacenter
    (Opcional) Nombre del datacenter. Si no se especifica, obtiene todas las VMs.
    
.PARAMETER OutputPath
    (Opcional) Ruta completa del archivo CSV de salida. 
    Por defecto: vm_inventory_YYYYMMDD_HHmmss.csv
    
.PARAMETER Credential
    (Opcional) Credenciales PSCredential. Si no se provee, solicita interactivamente.
    
.EXAMPLE
    .\Get-VMInventory.ps1 -VCenter vcenter-cont.dominio.local -Datacenter "DATACENTER CONTINGENCIA"
    
.EXAMPLE
    $cred = Get-Credential
    .\Get-VMInventory.ps1 -VCenter vcenter-prod.dominio.local -Credential $cred -OutputPath "C:\inventarios\produccion.csv"
    
.NOTES
    Autor: IaC Team
    Versión: 1.0
    Prerequisitos: VMware PowerCLI instalado
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="FQDN o IP del vCenter")]
    [string]$VCenter,
    
    [Parameter(Mandatory=$false, HelpMessage="Nombre del Datacenter (opcional)")]
    [string]$Datacenter = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "vm_inventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

# ==============================================================================
# FUNCIONES AUXILIARES
# ==============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $color = switch ($Type) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    
    $prefix = switch ($Type) {
        'Info'    { '[INFO]' }
        'Success' { '[✓]' }
        'Warning' { '[!]' }
        'Error'   { '[✗]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

# ==============================================================================
# VERIFICAR PREREQUISITOS
# ==============================================================================

Write-ColorOutput "Verificando prerequisitos..." -Type Info

# Verificar PowerCLI
$powerCLI = Get-Module -ListAvailable -Name VMware.PowerCLI
if (-not $powerCLI) {
    Write-ColorOutput "VMware PowerCLI no está instalado" -Type Error
    Write-Host "`nInstalar con: Install-Module -Name VMware.PowerCLI -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

# Importar módulos PowerCLI
try {
    Import-Module VMware.VimAutomation.Core -ErrorAction Stop | Out-Null
    Write-ColorOutput "PowerCLI cargado correctamente" -Type Success
} catch {
    Write-ColorOutput "Error cargando módulos PowerCLI: $_" -Type Error
    exit 1
}

# Configurar PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session | Out-Null
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope Session | Out-Null

# ==============================================================================
# CONECTAR A VCENTER
# ==============================================================================

Write-ColorOutput "`nConectando a vCenter: $VCenter" -Type Info

if (-not $Credential) {
    $Credential = Get-Credential -Message "Ingrese credenciales para $VCenter"
    if (-not $Credential) {
        Write-ColorOutput "Credenciales no proporcionadas" -Type Error
        exit 1
    }
}

try {
    $connection = Connect-VIServer -Server $VCenter -Credential $Credential -ErrorAction Stop
    Write-ColorOutput "Conectado exitosamente a $($connection.Name) (v$($connection.Version))" -Type Success
} catch {
    Write-ColorOutput "Error conectando a vCenter: $($_.Exception.Message)" -Type Error
    exit 1
}

# ==============================================================================
# DESCUBRIR VMS
# ==============================================================================

Write-ColorOutput "`nDescubriendo VMs..." -Type Info

try {
    $vmList = if ($Datacenter) {
        Write-Host "  Filtrando por datacenter: $Datacenter"
        Get-Datacenter -Name $Datacenter -ErrorAction Stop | Get-VM | Where-Object { $_.ExtensionData.Config.Template -eq $false }
    } else {
        Get-VM | Where-Object { $_.ExtensionData.Config.Template -eq $false }
    }
    
    $totalVMs = $vmList.Count
    
    if ($totalVMs -eq 0) {
        Write-ColorOutput "No se encontraron VMs" -Type Warning
        Disconnect-VIServer -Server $VCenter -Confirm:$false
        exit 0
    }
    
    Write-ColorOutput "VMs encontradas: $totalVMs" -Type Success
} catch {
    Write-ColorOutput "Error obteniendo lista de VMs: $($_.Exception.Message)" -Type Error
    Disconnect-VIServer -Server $VCenter -Confirm:$false
    exit 1
}

# ==============================================================================
# RECOPILAR INFORMACIÓN DETALLADA
# ==============================================================================

Write-ColorOutput "`nRecopilando información detallada de cada VM..." -Type Info
Write-Host "Esto puede tomar varios minutos dependiendo de la cantidad de VMs...`n" -ForegroundColor Yellow

$inventory = @()
$counter = 0
$startTime = Get-Date

foreach ($vm in $vmList) {
    $counter++
    $percentComplete = [math]::Round(($counter / $totalVMs) * 100, 1)
    Write-Progress -Activity "Procesando VMs" -Status "[$counter/$totalVMs] $($vm.Name)" -PercentComplete $percentComplete
    
    try {
        # Información de discos
        $diskInfo = $vm | Get-HardDisk -ErrorAction SilentlyContinue
        $totalDiskGB = if ($diskInfo) { 
            [math]::Round(($diskInfo | Measure-Object -Property CapacityGB -Sum).Sum, 2) 
        } else { 0 }
        $diskCount = if ($diskInfo) { $diskInfo.Count } else { 0 }
        
        # Información de red
        $networkAdapters = $vm | Get-NetworkAdapter -ErrorAction SilentlyContinue
        $networks = if ($networkAdapters) {
            ($networkAdapters | Select-Object -ExpandProperty NetworkName) -join "; "
        } else { "" }
        $nicCount = if ($networkAdapters) { $networkAdapters.Count } else { 0 }
        
        # Datastores
        $datastores = if ($vm.DatastoreIdList) {
            ($vm.DatastoreIdList | ForEach-Object { 
                try { (Get-Datastore -Id $_ -ErrorAction SilentlyContinue).Name } catch { "" }
            } | Where-Object { $_ }) -join "; "
        } else { "" }
        
        # Tags
        $tags = ""
        try {
            $vmTags = Get-TagAssignment -Entity $vm -ErrorAction SilentlyContinue
            if ($vmTags) {
                $tags = ($vmTags | Select-Object -ExpandProperty Tag | Select-Object -ExpandProperty Name) -join "; "
            }
        } catch {}
        
        # Snapshots
        $snapshots = $vm | Get-Snapshot -ErrorAction SilentlyContinue
        $snapshotCount = if ($snapshots) { $snapshots.Count } else { 0 }
        $snapshotSizeGB = if ($snapshots) { 
            [math]::Round(($snapshots | Measure-Object -Property SizeGB -Sum).Sum, 2) 
        } else { 0 }
        
        # Resource Pool
        $resourcePool = ""
        try {
            if ($vm.ResourcePool) {
                $resourcePool = $vm.ResourcePool.Name
            }
        } catch {}
        
        # Crear objeto con toda la información
        $vmData = [PSCustomObject]@{
            "VM_Name"                 = $vm.Name
            "Power_State"             = $vm.PowerState
            "vCPU"                    = $vm.NumCpu
            "Memory_GB"               = [math]::Round($vm.MemoryGB, 2)
            "Provisioned_Space_GB"    = [math]::Round($vm.ProvisionedSpaceGB, 2)
            "Used_Space_GB"           = [math]::Round($vm.UsedSpaceGB, 2)
            "Total_Disks_GB"          = $totalDiskGB
            "Disk_Count"              = $diskCount
            "NIC_Count"               = $nicCount
            "Guest_OS"                = if ($vm.Guest.OSFullName) { $vm.Guest.OSFullName } else { $vm.GuestId }
            "IP_Address"              = if ($vm.Guest.IPAddress) { $vm.Guest.IPAddress -join ", " } else { "N/A" }
            "Hostname"                = if ($vm.Guest.HostName) { $vm.Guest.HostName } else { "" }
            "VMware_Tools_Status"     = $vm.ExtensionData.Guest.ToolsStatus
            "VMware_Tools_Version"    = if ($vm.Guest.ToolsVersion) { $vm.Guest.ToolsVersion } else { "N/A" }
            "Cluster"                 = if ($vm.VMHost.Parent) { $vm.VMHost.Parent.Name } else { "" }
            "ESXi_Host"               = $vm.VMHost.Name
            "Datastore"               = $datastores
            "Networks"                = $networks
            "Folder"                  = $vm.Folder.Name
            "Resource_Pool"           = $resourcePool
            "Notes"                   = $vm.Notes
            "Tags"                    = $tags
            "CPU_Hot_Add_Enabled"     = $vm.ExtensionData.Config.CpuHotAddEnabled
            "Memory_Hot_Add_Enabled"  = $vm.ExtensionData.Config.MemoryHotAddEnabled
            "CPU_Reservation_MHz"     = $vm.ExtensionData.Config.CpuAllocation.Reservation
            "Memory_Reservation_GB"   = [math]::Round($vm.ExtensionData.Config.MemoryAllocation.Reservation / 1024, 2)
            "Snapshots_Count"         = $snapshotCount
            "Snapshots_Size_GB"       = $snapshotSizeGB
            "VM_Version"              = $vm.Version
            "Hardware_Version"        = $vm.HardwareVersion
            "Created_Date"            = if ($vm.CreateDate) { $vm.CreateDate.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
            "UUID"                    = $vm.ExtensionData.Config.Uuid
            "Instance_UUID"           = $vm.ExtensionData.Config.InstanceUuid
        }
        
        $inventory += $vmData
        
    } catch {
        Write-ColorOutput "Error procesando VM $($vm.Name): $($_.Exception.Message)" -Type Warning
    }
}

Write-Progress -Activity "Procesando VMs" -Completed

$endTime = Get-Date
$duration = New-TimeSpan -Start $startTime -End $endTime

Write-ColorOutput "`nProcesamiento completado en $($duration.Minutes)m $($duration.Seconds)s" -Type Success

# ==============================================================================
# EXPORTAR INVENTARIO
# ==============================================================================

Write-ColorOutput "`nExportando inventario a CSV..." -Type Info

try {
    $inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-ColorOutput "Inventario exportado exitosamente" -Type Success
    Write-Host "`n  Archivo: $OutputPath" -ForegroundColor Cyan
    Write-Host "  VMs procesadas: $($inventory.Count)" -ForegroundColor Cyan
    Write-Host "  Tamaño: $([math]::Round((Get-Item $OutputPath).Length / 1MB, 2)) MB" -ForegroundColor Cyan
} catch {
    Write-ColorOutput "Error exportando CSV: $($_.Exception.Message)" -Type Error
}

# ==============================================================================
# GENERAR ESTADÍSTICAS
# ==============================================================================

Write-ColorOutput "`n========================================" -Type Info
Write-ColorOutput "ESTADÍSTICAS DEL INVENTARIO" -Type Info
Write-ColorOutput "========================================`n" -Type Info

# Estados de VMs
$poweredOn = ($inventory | Where-Object Power_State -eq 'PoweredOn').Count
$poweredOff = ($inventory | Where-Object Power_State -eq 'PoweredOff').Count
$suspended = ($inventory | Where-Object Power_State -eq 'Suspended').Count

Write-Host "VMs por estado:" -ForegroundColor Yellow
Write-Host "  ► Encendidas:  $poweredOn" -ForegroundColor Green
Write-Host "  ► Apagadas:    $poweredOff"
Write-Host "  ► Suspendidas: $suspended"

# Recursos
$totalCPU = ($inventory | Measure-Object -Property vCPU -Sum).Sum
$totalMemoryGB = [math]::Round(($inventory | Measure-Object -Property Memory_GB -Sum).Sum, 2)
$totalProvisionedGB = [math]::Round(($inventory | Measure-Object -Property Provisioned_Space_GB -Sum).Sum, 2)
$totalUsedGB = [math]::Round(($inventory | Measure-Object -Property Used_Space_GB -Sum).Sum, 2)

Write-Host "`nRecursos totales:" -ForegroundColor Yellow
Write-Host "  ► Total vCPUs:         $totalCPU" -ForegroundColor Cyan
Write-Host "  ► Total Memory:        $totalMemoryGB GB" -ForegroundColor Cyan
Write-Host "  ► Storage Provisionado: $totalProvisionedGB GB" -ForegroundColor Cyan
Write-Host "  ► Storage Usado:       $totalUsedGB GB" -ForegroundColor Cyan

# Sistemas Operativos
Write-Host "`nTop 10 Sistemas Operativos:" -ForegroundColor Yellow
$inventory | Group-Object Guest_OS | 
    Sort-Object Count -Descending | 
    Select-Object -First 10 | 
    Format-Table @{L="Sistema Operativo"; E={$_.Name}}, @{L="Cantidad"; E={$_.Count}} -AutoSize

# VMware Tools
$toolsOutdated = ($inventory | Where-Object VMware_Tools_Status -ne 'toolsOk').Count
if ($toolsOutdated -gt 0) {
    Write-ColorOutput "`nVMware Tools desactualizadas o no instaladas: $toolsOutdated VMs" -Type Warning
    $inventory | Where-Object VMware_Tools_Status -ne 'toolsOk' | 
        Select-Object VM_Name, VMware_Tools_Status, Guest_OS | 
        Format-Table -AutoSize
}

# Hot-Add
$noHotAddCPU = ($inventory | Where-Object CPU_Hot_Add_Enabled -eq $false).Count
$noHotAddMemory = ($inventory | Where-Object Memory_Hot_Add_Enabled -eq $false).Count

Write-Host "`nConfiguración Hot-Add:" -ForegroundColor Yellow
Write-Host "  ► VMs sin CPU Hot-Add:    $noHotAddCPU"
Write-Host "  ► VMs sin Memory Hot-Add: $noHotAddMemory"

if ($noHotAddCPU -gt 0 -or $noHotAddMemory -gt 0) {
    Write-ColorOutput "`n  Estas VMs necesitarán reinicio para escalar CPU/RAM" -Type Warning
}

# Snapshots
$vmsWithSnapshots = ($inventory | Where-Object Snapshots_Count -gt 0).Count
$totalSnapshotGB = [math]::Round(($inventory | Measure-Object -Property Snapshots_Size_GB -Sum).Sum, 2)

if ($vmsWithSnapshots -gt 0) {
    Write-Host "`nSnapshots:" -ForegroundColor Yellow
    Write-Host "  ► VMs con snapshots: $vmsWithSnapshots"
    Write-Host "  ► Espacio total:     $totalSnapshotGB GB"
    
    Write-ColorOutput "`n  Revisar snapshots antiguos antes de importar a Terraform" -Type Warning
}

# Clusters
Write-Host "`nDistribución por Cluster:" -ForegroundColor Yellow
$inventory | Group-Object Cluster | 
    Sort-Object Count -Descending | 
    Format-Table @{L="Cluster"; E={$_.Name}}, @{L="VMs"; E={$_.Count}} -AutoSize

# ==============================================================================
# DESCONECTAR Y FINALIZAR
# ==============================================================================

Write-ColorOutput "`nDesconectando de vCenter..." -Type Info
Disconnect-VIServer -Server $VCenter -Confirm:$false
Write-ColorOutput "Desconectado exitosamente" -Type Success

Write-ColorOutput "`n========================================" -Type Success
Write-ColorOutput "INVENTARIO COMPLETADO" -Type Success
Write-ColorOutput "========================================`n" -Type Success

Write-Host "Siguiente paso: Revisar el archivo CSV y clasificar VMs por criticidad`n"
