# export-corp-certs.ps1
# Exporta los CAs corporativos del store de Windows a C:\Temp\certs-gnb\
# Ejecutar desde WSL: powershell.exe -ExecutionPolicy Bypass -File "/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/scripts/export-corp-certs.ps1"

$OutDir = "C:\Temp\certs-gnb"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$targets = @("GNB SUDAMERIS ROOT", "PROXYBLUECOAT", "FortiGate CA", "GNB SUDAMERIS SUBCA", "GNBFR")

$count = 0
Get-ChildItem Cert:\LocalMachine\Root | ForEach-Object {
    foreach ($t in $targets) {
        if ($_.Subject -like "*$t*") {
            $safe = $_.Subject -replace "CN=","" -replace "[^a-zA-Z0-9]","-" -replace "-+","-"
            $safe = $safe.Trim("-").Substring(0, [Math]::Min(40, $safe.Trim("-").Length))
            $path = "$OutDir\$safe.der"
            [System.IO.File]::WriteAllBytes($path, $_.RawData)
            Write-Host "Exportado: $path"
            $count++
            break
        }
    }
}

Write-Host ""
Write-Host "Total exportados: $count certificados en $OutDir"
Get-ChildItem $OutDir | Format-Table Name, Length
