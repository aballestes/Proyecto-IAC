#!/usr/bin/env bash
# =============================================================================
# check-vsphere-ports.sh
# Tarea 0.6 — Verificar puertos de infraestructura vSphere
# vCenter API 443, ESXi HTTPS 443, ESXi NFC 902, ESXi SSH 22
# =============================================================================
set -euo pipefail

VCENTER="192.168.77.152"
ESXI01="192.168.77.149"
ESXI02="192.168.77.150"
TIMEOUT=3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="$SCRIPT_DIR/vsphere-ports-report-$(date +%Y%m%d-%H%M).txt"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

test_port() {
  local ip=$1 port=$2
  if command -v nmap &>/dev/null; then
    nmap -sT -p "$port" --open -T4 "$ip" 2>/dev/null | grep -q "open" && echo "ABIERTO" || echo "CERRADO/FILTRADO"
  else
    timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "ABIERTO" || echo "CERRADO/FILTRADO"
  fi
}

print_row() {
  local host=$1 port=$2 svc=$3 result=$4
  if [[ "$result" == "ABIERTO" ]]; then
    printf "${GREEN}%-22s %-6s %-20s %s${NC}\n" "$host" "$port" "$svc" "$result"
  else
    printf "${RED}%-22s %-6s %-20s %s${NC}\n" "$host" "$port" "$svc" "$result"
  fi
}

{
echo "==================================================================="
echo "  Tarea 0.6 — Verificacion puertos infraestructura vSphere"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "==================================================================="
echo ""
printf "%-22s %-6s %-20s %s\n" "Host" "Puerto" "Servicio" "Estado"
echo "-------------------------------------------------------------------"
} | tee "$REPORT"

declare -a results=()

check_and_log() {
  local host=$1 port=$2 svc=$3
  local result
  result=$(test_port "$host" "$port")
  print_row "$host" "$port" "$svc" "$result"
  echo "$(printf '%-22s %-6s %-20s %s' "$host" "$port" "$svc" "$result")" >> "$REPORT"
  results+=("$host:$port:$svc:$result")
}

check_and_log "$VCENTER" "443" "vCenter-API-HTTPS"
check_and_log "$VCENTER" "80"  "vCenter-API-HTTP"
check_and_log "$ESXI01"  "443" "ESXi01-HTTPS-Mgmt"
check_and_log "$ESXI01"  "902" "ESXi01-NFC-vMotion"
check_and_log "$ESXI01"  "22"  "ESXi01-SSH"
check_and_log "$ESXI02"  "443" "ESXi02-HTTPS-Mgmt"
check_and_log "$ESXI02"  "902" "ESXi02-NFC-vMotion"
check_and_log "$ESXI02"  "22"  "ESXi02-SSH"

# Resumen
ok=0; fail=0
for r in "${results[@]}"; do
  status="${r##*:}"
  [[ "$status" == "ABIERTO" ]] && ((ok=ok+1)) || ((fail=fail+1))
done

{
echo ""
echo "-------------------------------------------------------------------"
echo "  RESUMEN"
printf "  Puertos abiertos       : %s\n" "$ok"
printf "  Cerrados/Filtrados     : %s\n" "$fail"
echo "-------------------------------------------------------------------"
echo ""

if [[ $fail -eq 0 ]]; then
  echo "  RESULTADO: TODOS LOS PUERTOS CRITICOS ACCESIBLES - OK"
else
  echo "  RESULTADO: HAY PUERTOS BLOQUEADOS - REVISAR FIREWALL"
  echo ""
  echo "  Impacto por puerto bloqueado:"
  for r in "${results[@]}"; do
    IFS=':' read -r h p s st <<< "$r"
    if [[ "$st" != "ABIERTO" ]]; then
      case "$p" in
        443) echo "    $h:$p ($s) → Terraform no puede conectar a vSphere API" ;;
        902) echo "    $h:$p ($s) → Terraform falla al copiar VMDKs (create/clone)" ;;
        22)  echo "    $h:$p ($s) → SSH deshabilitado en ESXi (normal por seguridad)" ;;
        *)   echo "    $h:$p ($s) → Puerto no accesible" ;;
      esac
    fi
  done
fi
echo ""
echo "Reporte guardado: $REPORT"
} | tee -a "$REPORT"
