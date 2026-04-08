#Requires -Version 5.1
<#
.SYNOPSIS
    Tarea 0.5 — Validar conectividad red hacia todas las VMs (ping, SSH/WinRM)
.DESCRIPTION
    Lee el inventario CSV de contingencia, prueba ICMP + puerto de gestión por OS
    y exporta un reporte CSV con el resultado de cada VM.
.PARAMETER CsvPath
    Ruta al CSV generado por el script de inventario. Por defecto busca en la misma carpeta.
.PARAMETER OutputPath
    Ruta del CSV con los resultados. Por defecto: connectivity-report-<fecha>.csv
.PARAMETER TimeoutMs
    Timeout por prueba de puerto TCP en milisegundos. Por defecto: 2000.
.EXAMPLE
    .\Test-VMConnectivity.ps1
    .\Test-VMConnectivity.ps1 -CsvPath "..\..\inventario_datacenter_contingencia.csv"
#>
[CmdletBinding()]
param(
    [string]$CsvPath    = "$PSScriptRoot\..\..\inventario_datacenter_contingencia.csv",
    [string]$OutputPath = "$PSScriptRoot\connectivity-report-$(Get-Date -Format 'yyyyMMdd-HHmm').csv",
    [int]$TimeoutMs     = 2000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Test-TcpPort {
    param([string]$IP, [int]$Port, [int]$Timeout)
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $ar  = $tcp.BeginConnect($IP, $Port, $null, $null)
        $ok  = $ar.AsyncWaitHandle.WaitOne($Timeout, $false)
        if ($ok -and $tcp.Connected) { $tcp.Close(); return $true }
        $tcp.Close()
    } catch {}
    return $false
}

function Get-OSCategory {
    param([string]$GuestId)
    if ($GuestId -match 'windows') { return 'Windows' }
    if ($GuestId -match 'linux|sles|ubuntu|oracle|centos|rhel|photon') { return 'Linux' }
    return 'Unknown'
}

# ---------------------------------------------------------------------------
# Cargar inventario
# ---------------------------------------------------------------------------
if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV no encontrado: $CsvPath"
    exit 1
}

$vms = Import-Csv -Path $CsvPath |
       Where-Object { $_.power_state -eq 'poweredOn' -and $_.ip_address -ne '' }

Write-Host "`n=== Test-VMConnectivity — Contingencia ===" -ForegroundColor Cyan
Write-Host "VMs a probar: $($vms.Count)  |  Timeout TCP: ${TimeoutMs}ms`n"

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($vm in $vms) {
    $ip     = $vm.ip_address.Trim()
    $os     = Get-OSCategory -GuestId $vm.guest_id
    $name   = $vm.name

    # ----- Ping -----
    $pingOk = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue

    # ----- Puerto de gestión según OS -----
    $ssh22   = $false
    $winrm80 = $false
    $winrm43 = $false

    switch ($os) {
        'Windows' {
            $winrm80 = Test-TcpPort -IP $ip -Port 5985 -Timeout $TimeoutMs
            $winrm43 = Test-TcpPort -IP $ip -Port 5986 -Timeout $TimeoutMs
        }
        'Linux' {
            $ssh22 = Test-TcpPort -IP $ip -Port 22 -Timeout $TimeoutMs
        }
        default {
            # Prueba ambos para desconocidos
            $ssh22   = Test-TcpPort -IP $ip -Port 22   -Timeout $TimeoutMs
            $winrm80 = Test-TcpPort -IP $ip -Port 5985 -Timeout $TimeoutMs
        }
    }

    # ----- Estado general -----
    $mgmtOk = switch ($os) {
        'Windows' { $winrm80 -or $winrm43 }
        'Linux'   { $ssh22 }
        default   { $ssh22 -or $winrm80 }
    }

    $status = if ($pingOk -and $mgmtOk) { 'OK' }
              elseif ($pingOk)           { 'PING_OK_PORT_FAIL' }
              else                       { 'NO_REACH' }

    $color = switch ($status) {
        'OK'                { 'Green'  }
        'PING_OK_PORT_FAIL' { 'Yellow' }
        'NO_REACH'          { 'Red'    }
    }

    Write-Host ("{0,-30} {1,-16} {2,-8} Ping:{3}  SSH22:{4}  WinRM5985:{5}  WinRM5986:{6}  => {7}" -f `
        $name, $ip, $os,
        ([string]$pingOk)[0], ([string]$ssh22)[0],
        ([string]$winrm80)[0], ([string]$winrm43)[0],
        $status) -ForegroundColor $color

    $results.Add([PSCustomObject]@{
        VM_Name       = $name
        IP            = $ip
        OS_Category   = $os
        Guest_ID      = $vm.guest_id
        Datastore     = $vm.datastore
        Ping          = $pingOk
        SSH_22        = $ssh22
        WinRM_5985    = $winrm80
        WinRM_5986    = $winrm43
        Mgmt_Port_OK  = $mgmtOk
        Status        = $status
        Tested_At     = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    })
}

# ---------------------------------------------------------------------------
# Resumen
# ---------------------------------------------------------------------------
$ok   = ($results | Where-Object Status -eq 'OK').Count
$warn = ($results | Where-Object Status -eq 'PING_OK_PORT_FAIL').Count
$fail = ($results | Where-Object Status -eq 'NO_REACH').Count

Write-Host "`n--- RESUMEN ---" -ForegroundColor Cyan
Write-Host "  OK              : $ok" -ForegroundColor Green
Write-Host "  Ping OK/Puerto KO: $warn" -ForegroundColor Yellow
Write-Host "  Sin alcance     : $fail" -ForegroundColor Red
Write-Host "  Total probadas  : $($results.Count)"

# ---------------------------------------------------------------------------
# Exportar
# ---------------------------------------------------------------------------
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "`nReporte exportado: $OutputPath`n" -ForegroundColor Cyan

# Mostrar las fallidas para acción inmediata
$failed = $results | Where-Object { $_.Status -ne 'OK' }
if ($failed) {
    Write-Host "VMs que requieren atención:" -ForegroundColor Yellow
    $failed | Format-Table VM_Name, IP, OS_Category, Ping, SSH_22, WinRM_5985, WinRM_5986, Status -AutoSize
}
