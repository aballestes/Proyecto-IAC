#!/usr/bin/env bash
# =============================================================================
# test-vm-connectivity.sh
# Tarea 0.5 — Validar conectividad red hacia todas las VMs (ping, SSH/WinRM)
#
# Uso:
#   chmod +x test-vm-connectivity.sh
#   ./test-vm-connectivity.sh
#   ./test-vm-connectivity.sh /ruta/alternativa/inventario.csv
#
# Requisitos: bash 4+, ping, nmap (opcional pero recomendado)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${1:-$SCRIPT_DIR/inventario_datacenter_contingencia.csv}"
REPORT="$SCRIPT_DIR/connectivity-report-$(date +%Y%m%d-%H%M).csv"
TIMEOUT=2   # segundos por prueba TCP

# Colores
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

# ---------------------------------------------------------------------------
# Validaciones previas
# ---------------------------------------------------------------------------
if [[ ! -f "$CSV" ]]; then
  echo "ERROR: CSV no encontrado: $CSV" >&2
  exit 1
fi

USE_NMAP=false
if command -v nmap &>/dev/null; then
  USE_NMAP=true
fi

# ---------------------------------------------------------------------------
# Funciones
# ---------------------------------------------------------------------------
ping_host() {
  local ip=$1
  ping -c1 -W"$TIMEOUT" "$ip" &>/dev/null && echo "true" || echo "false"
}

test_tcp() {
  local ip=$1 port=$2
  if $USE_NMAP; then
    nmap -sT -p "$port" --open -T4 "$ip" 2>/dev/null | grep -q "open" && echo "true" || echo "false"
  else
    timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "true" || echo "false"
  fi
}

os_category() {
  local guest_id=$1
  if echo "$guest_id" | grep -qi "windows"; then echo "Windows"
  elif echo "$guest_id" | grep -qi "linux\|sles\|ubuntu\|oracle\|centos\|rhel\|photon\|other.*linux"; then echo "Linux"
  else echo "Unknown"
  fi
}

# ---------------------------------------------------------------------------
# Cabecera del reporte CSV
# ---------------------------------------------------------------------------
echo "VM_Name,IP,OS_Category,Guest_ID,Datastore,Ping,SSH_22,WinRM_5985,WinRM_5986,Mgmt_Port_OK,Status,Tested_At" > "$REPORT"

echo ""
echo "=== test-vm-connectivity.sh — Contingencia ==="
if $USE_NMAP; then
  echo "Modo: nmap (recomendado)"
else
  echo "Modo: bash /dev/tcp (instala nmap para mayor precisión)"
fi
echo ""
printf "%-30s %-16s %-8s %-6s %-10s %-12s %-12s  %s\n" \
  "VM" "IP" "OS" "Ping" "SSH:22" "WinRM:5985" "WinRM:5986" "Estado"
echo "$(printf '%.0s-' {1..100})"

ok_count=0; warn_count=0; fail_count=0

# ---------------------------------------------------------------------------
# Procesar CSV (saltar cabecera)
# ---------------------------------------------------------------------------
while IFS=';' read -r name guest_id guest_full cpus mem power ip rest; do
  # Limpiar comillas y espacios
  name=$(echo "$name"     | tr -d '"' | xargs)
  ip=$(echo "$ip"         | tr -d '"' | xargs)
  guest_id=$(echo "$guest_id" | tr -d '"' | xargs)
  power=$(echo "$power"   | tr -d '"' | xargs)
  datastore=$(echo "$rest" | cut -d';' -f3 | tr -d '"' | xargs)

  # Solo VMs encendidas con IP
  [[ "$power" != "poweredOn" || -z "$ip" ]] && continue

  os=$(os_category "$guest_id")

  # Ping
  ping_ok=$(ping_host "$ip")

  # Puertos según OS
  ssh22="false"; winrm5985="false"; winrm5986="false"
  case "$os" in
    Windows)
      winrm5985=$(test_tcp "$ip" 5985)
      winrm5986=$(test_tcp "$ip" 5986)
      ;;
    Linux)
      ssh22=$(test_tcp "$ip" 22)
      ;;
    Unknown)
      ssh22=$(test_tcp "$ip" 22)
      winrm5985=$(test_tcp "$ip" 5985)
      ;;
  esac

  # Estado gesitón
  mgmt_ok="false"
  case "$os" in
    Windows) [[ "$winrm5985" == "true" || "$winrm5986" == "true" ]] && mgmt_ok="true" ;;
    Linux)   [[ "$ssh22" == "true" ]] && mgmt_ok="true" ;;
    Unknown) [[ "$ssh22" == "true" || "$winrm5985" == "true" ]] && mgmt_ok="true" ;;
  esac

  # Estado final
  if [[ "$ping_ok" == "true" && "$mgmt_ok" == "true" ]]; then
    status="OK"; ok_count=$((ok_count + 1))
    color=$GREEN
  elif [[ "$ping_ok" == "true" ]]; then
    status="PING_OK_PORT_FAIL"; warn_count=$((warn_count + 1))
    color=$YELLOW
  else
    status="NO_REACH"; fail_count=$((fail_count + 1))
    color=$RED
  fi

  tested_at=$(date '+%Y-%m-%d %H:%M:%S')

  # Imprimir línea con color
  printf "${color}%-30s %-16s %-8s %-6s %-10s %-12s %-12s  %s${NC}\n" \
    "$name" "$ip" "$os" "$ping_ok" "$ssh22" "$winrm5985" "$winrm5986" "$status"

  # Guardar en CSV
  echo "\"$name\",\"$ip\",\"$os\",\"$guest_id\",\"$datastore\",\"$ping_ok\",\"$ssh22\",\"$winrm5985\",\"$winrm5986\",\"$mgmt_ok\",\"$status\",\"$tested_at\"" >> "$REPORT"

done < <(tail -n +2 "$CSV")

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
total=$((ok_count + warn_count + fail_count))
echo ""
echo "--- RESUMEN ---"
echo -e "${GREEN}  OK               : $ok_count${NC}"
echo -e "${YELLOW}  Ping OK/Puerto KO: $warn_count${NC}"
echo -e "${RED}  Sin alcance      : $fail_count${NC}"
echo "  Total probadas   : $total"
echo ""
echo "Reporte exportado: $REPORT"

# Mostrar fallidas
if (( warn_count + fail_count > 0 )); then
  echo ""
  echo -e "${YELLOW}VMs que requieren atención:${NC}"
  grep -E '"PING_OK_PORT_FAIL"|"NO_REACH"' "$REPORT" | \
    awk -F',' '{printf "  %-30s %-16s %s\n", $1, $2, $11}' | tr -d '"'
fi

echo ""
