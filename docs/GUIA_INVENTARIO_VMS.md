# GUÍA: Ejecutar Inventario Automático de VMs
## Tarea 0.2 del Plan de Trabajo

Esta guía explica cómo ejecutar el inventario automático de VMs en VMware vSphere usando **Python** o **PowerCLI**.

---

## 📋 OPCIÓN 1: Script Python (Recomendado)

### 1. Instalar dependencias

En el Jump Host o máquina de control:

```bash
# Instalar Python 3.11+ si no está instalado
python --version

# Instalar dependencias del proyecto
cd "C:\BACKUP SEPTIEMBRE\GIFHUB\PROYECTO IAAC"
pip install -r scripts/requirements.txt

# O instalar manualmente:
pip install pyVmomi pyvmomi-requests tabulate pyyaml
```

### 2. Configurar credenciales

**Crear archivo `.env` o exportar variables de entorno:**

```powershell
# PowerShell
$env:VCENTER_HOST = "vcenter-cont.dominio.local"
$env:VCENTER_USER = "svc-ansible@vsphere.local"
$env:VCENTER_PASSWORD = "TU_PASSWORD_AQUI"
```

**O en Linux/Bash:**
```bash
export VCENTER_HOST="vcenter-cont.dominio.local"
export VCENTER_USER="svc-ansible@vsphere.local"
export VCENTER_PASSWORD="TU_PASSWORD_AQUI"
```

### 3. Ejecutar el script

#### A. Generar inventario en formato CSV (para revisión humana)

```bash
python scripts/discovery/vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --password TU_PASSWORD \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format csv \
  --output inventario_contingencia.csv
```

**Resultado:** Archivo CSV con columnas:
- VM Name
- Power State
- CPU Count
- Memory (MB)
- Disk Total (GB)
- IP Address
- Guest OS
- VMware Tools Status
- Cluster
- Datastore
- Folder Path

#### B. Generar inventario en formato JSON (para Terraform)

```bash
python scripts/discovery/vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --password TU_PASSWORD \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format json \
  --output terraform/environments/contingencia/discovered_vms.json
```

#### C. Generar inventario en formato YAML (para Ansible)

```bash
python scripts/discovery/vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --password TU_PASSWORD \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format yaml \
  --output ansible/inventory/contingencia/discovered_vms.yml
```

#### D. Generar para PRODUCCIÓN

```bash
python scripts/discovery/vm_inventory.py \
  --host vcenter-prod.dominio.local \
  --user svc-ansible@vsphere.local \
  --password TU_PASSWORD \
  --datacenter "DATACENTER PRODUCCION" \
  --format csv \
  --output inventario_produccion.csv
```

### 4. Revisar el inventario generado

```powershell
# Abrir CSV en Excel
Invoke-Item inventario_contingencia.csv

# O ver en consola (PowerShell)
Import-Csv inventario_contingencia.csv | Format-Table -AutoSize

# Ver estadísticas rápidas
Import-Csv inventario_contingencia.csv | Group-Object "Guest OS" | Sort-Object Count -Descending
```

---

## 📋 OPCIÓN 2: Script PowerCLI

### 1. Instalar PowerCLI

```powershell
# Verificar si PowerCLI está instalado
Get-Module -ListAvailable VMware.PowerCLI

# Instalar si es necesario
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Permitir certificados autofirmados
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false
```

### 2. Ejecutar script de inventario PowerCLI

**Script: `Get-VMInventory.ps1`**

```powershell
<#
.SYNOPSIS
    Inventario automático de VMs en vCenter
.EXAMPLE
    .\Get-VMInventory.ps1 -VCenter vcenter-cont.dominio.local -OutputPath .\inventario.csv
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$VCenter,
    
    [Parameter(Mandatory=$false)]
    [string]$Datacenter = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "vm_inventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

# Conectar a vCenter
Write-Host "Conectando a vCenter: $VCenter" -ForegroundColor Cyan

if (-not $Credential) {
    $Credential = Get-Credential -Message "Credenciales para $VCenter"
}

try {
    Connect-VIServer -Server $VCenter -Credential $Credential -ErrorAction Stop | Out-Null
    Write-Host "✓ Conectado exitosamente" -ForegroundColor Green
} catch {
    Write-Error "Error conectando a vCenter: $_"
    exit 1
}

# Obtener VMs
Write-Host "`nDescubriendo VMs..." -ForegroundColor Cyan

$vmList = if ($Datacenter) {
    Get-Datacenter -Name $Datacenter | Get-VM
} else {
    Get-VM
}

$totalVMs = $vmList.Count
Write-Host "✓ VMs encontradas: $totalVMs" -ForegroundColor Green

# Recopilar información
Write-Host "`nRecopilando información detallada..." -ForegroundColor Cyan

$inventory = @()
$counter = 0

foreach ($vm in $vmList) {
    $counter++
    Write-Progress -Activity "Procesando VMs" -Status "VM: $($vm.Name)" -PercentComplete (($counter / $totalVMs) * 100)
    
    try {
        # Obtener información de discos
        $diskInfo = $vm | Get-HardDisk
        $totalDiskGB = ($diskInfo | Measure-Object -Property CapacityGB -Sum).Sum
        
        # Obtener información de red
        $networkAdapters = $vm | Get-NetworkAdapter
        $networks = ($networkAdapters | Select-Object -ExpandProperty NetworkName) -join "; "
        
        # Obtener datastore
        $datastores = ($vm.DatastoreIdList | ForEach-Object { 
            (Get-Datastore -Id $_).Name 
        }) -join "; "
        
        # Obtener tags (si existen)
        $tags = ""
        try {
            $vmTags = Get-TagAssignment -Entity $vm -ErrorAction SilentlyContinue
            $tags = ($vmTags | Select-Object -ExpandProperty Tag | Select-Object -ExpandProperty Name) -join "; "
        } catch {}
        
        $vmData = [PSCustomObject]@{
            "VM Name"              = $vm.Name
            "Power State"          = $vm.PowerState
            "vCPU"                 = $vm.NumCpu
            "Memory GB"            = [math]::Round($vm.MemoryGB, 2)
            "Provisioned GB"       = [math]::Round($vm.ProvisionedSpaceGB, 2)
            "Used GB"              = [math]::Round($vm.UsedSpaceGB, 2)
            "Total Disks GB"       = [math]::Round($totalDiskGB, 2)
            "Disk Count"           = $diskInfo.Count
            "Guest OS"             = $vm.Guest.OSFullName
            "IP Address"           = $vm.Guest.IPAddress -join ", "
            "VMware Tools Status"  = $vm.ExtensionData.Guest.ToolsStatus
            "VMware Tools Version" = $vm.Guest.ToolsVersion
            "Cluster"              = $vm.VMHost.Parent.Name
            "ESXi Host"            = $vm.VMHost.Name
            "Datastore"            = $datastores
            "Networks"             = $networks
            "Folder"               = $vm.Folder.Name
            "Notes"                = $vm.Notes
            "Tags"                 = $tags
            "CPU Hot Add"          = $vm.ExtensionData.Config.CpuHotAddEnabled
            "Memory Hot Add"       = $vm.ExtensionData.Config.MemoryHotAddEnabled
            "Created Date"         = $vm.CreateDate
        }
        
        $inventory += $vmData
        
    } catch {
        Write-Warning "Error procesando VM: $($vm.Name) - $_"
    }
}

Write-Progress -Activity "Procesando VMs" -Completed

# Exportar a CSV
$inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "`n✓ Inventario exportado a: $OutputPath" -ForegroundColor Green
Write-Host "  Total VMs: $($inventory.Count)" -ForegroundColor Cyan

# Mostrar estadísticas
Write-Host "`n=== ESTADÍSTICAS ===" -ForegroundColor Yellow
Write-Host "VMs encendidas:  $($inventory | Where-Object 'Power State' -eq 'PoweredOn' | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "VMs apagadas:    $($inventory | Where-Object 'Power State' -eq 'PoweredOff' | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "Total vCPUs:     $(($inventory | Measure-Object -Property vCPU -Sum).Sum)"
Write-Host "Total Memory GB: $([math]::Round(($inventory | Measure-Object -Property 'Memory GB' -Sum).Sum, 2))"
Write-Host "Total Storage GB: $([math]::Round(($inventory | Measure-Object -Property 'Provisioned GB' -Sum).Sum, 2))"

Write-Host "`nSistemas Operativos:" -ForegroundColor Yellow
$inventory | Group-Object "Guest OS" | Sort-Object Count -Descending | Select-Object -First 10 | Format-Table Name, Count -AutoSize

Write-Host "`nVMware Tools desactualizadas:" -ForegroundColor Yellow
$inventory | Where-Object "VMware Tools Status" -ne "toolsOk" | Select-Object "VM Name", "VMware Tools Status" | Format-Table -AutoSize

# Desconectar
Disconnect-VIServer -Server $VCenter -Confirm:$false
Write-Host "`n✓ Desconectado de vCenter" -ForegroundColor Green
```

### 3. Ejecutar el script PowerCLI

```powershell
# Guardar el script como Get-VMInventory.ps1
# Luego ejecutar:

# Para contingencia
.\Get-VMInventory.ps1 -VCenter "vcenter-cont.dominio.local" -Datacenter "DATACENTER CONTINGENCIA" -OutputPath ".\inventario_contingencia.csv"

# Para producción
.\Get-VMInventory.ps1 -VCenter "vcenter-prod.dominio.local" -Datacenter "DATACENTER PRODUCCION" -OutputPath ".\inventario_produccion.csv"

# Sin especificar datacenter (todas las VMs del vCenter)
.\Get-VMInventory.ps1 -VCenter "vcenter-prod.dominio.local" -OutputPath ".\inventario_completo.csv"
```

---

## 📊 ANÁLISIS DEL INVENTARIO

### 1. Clasificar VMs por criticidad

Una vez tengas el CSV, abrirlo en Excel y agregar una columna "Criticidad" basándote en:

- **CRÍTICA**: Bases de datos, servidores de aplicación core de negocio
- **ALTA**: Servidores de aplicación importantes
- **MEDIA**: Servidores de desarrollo, staging
- **BAJA**: Servidores de pruebas, sandbox

### 2. Identificar VMs con problemas

**VMware Tools desactualizadas:**
```powershell
Import-Csv inventario_contingencia.csv | 
    Where-Object "VMware Tools Status" -ne "toolsOk" | 
    Select-Object "VM Name", "VMware Tools Status", "Guest OS"
```

**VMs sin Hot-Add habilitado:**
```powershell
Import-Csv inventario_contingencia.csv | 
    Where-Object { $_."CPU Hot Add" -eq "False" -or $_."Memory Hot Add" -eq "False" } |
    Select-Object "VM Name", "CPU Hot Add", "Memory Hot Add"
```

### 3. Generar reporte para management

```powershell
$inventory = Import-Csv inventario_contingencia.csv

$report = @"
=== INVENTARIO DE INFRAESTRUCTURA ===
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm")
vCenter: vcenter-cont.dominio.local

Total VMs: $($inventory.Count)
VMs Encendidas: $($inventory | Where-Object "Power State" -eq "PoweredOn" | Measure-Object | Select-Object -ExpandProperty Count)
VMs Apagadas: $($inventory | Where-Object "Power State" -eq "PoweredOff" | Measure-Object | Select-Object -ExpandProperty Count)

Total vCPUs: $(($inventory | Measure-Object -Property vCPU -Sum).Sum)
Total Memory (GB): $([math]::Round(($inventory | Measure-Object -Property "Memory GB" -Sum).Sum, 2))
Total Storage Provisionado (GB): $([math]::Round(($inventory | Measure-Object -Property "Provisioned GB" -Sum).Sum, 2))

VMs con VMware Tools desactualizadas: $($inventory | Where-Object "VMware Tools Status" -ne "toolsOk" | Measure-Object | Select-Object -ExpandProperty Count)
VMs sin CPU Hot-Add: $($inventory | Where-Object "CPU Hot Add" -eq "False" | Measure-Object | Select-Object -ExpandProperty Count)
VMs sin Memory Hot-Add: $($inventory | Where-Object "Memory Hot Add" -eq "False" | Measure-Object | Select-Object -ExpandProperty Count)
"@

$report | Out-File "reporte_inventario_$(Get-Date -Format 'yyyyMMdd').txt"
```

---

## ✅ ENTREGABLES DE LA TAREA 0.2

Al finalizar esta tarea debes tener:

1. ✅ **inventario_contingencia.csv** - ~30 VMs
2. ✅ **inventario_produccion.csv** - ~300 VMs
3. ✅ **Archivo clasificado con columna "Criticidad"** agregada manualmente
4. ✅ **Lista de VMs con VMware Tools desactualizadas**
5. ✅ **Lista de VMs sin Hot-Add habilitado**
6. ✅ **Reporte ejecutivo** (estadísticas resumidas)

---

## 🔄 SIGUIENTE PASO

Una vez tengas el inventario completo:

→ **Tarea 0.3:** Clasificar VMs según criticidad (usar el CSV generado)
→ **Tarea 0.4:** Documentar naming conventions observadas en el inventario
