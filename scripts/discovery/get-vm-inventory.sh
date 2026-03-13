#!/bin/bash
#
# get-vm-inventory.sh — Inventario de VMs VMware (reemplaza Get-VMInventory.ps1)
# ===============================================================================
# Wrapper bash que llama vm_inventory.py y muestra estadísticas completas.
# Para ejecutar desde WSL Ubuntu o cualquier Linux.
#
# Uso:
#   ./get-vm-inventory.sh \
#       --host vcsac.gnb.loc \
#       --user administrator@vsphere.local \
#       --datacenter "CELTA" \
#       [--password "Eyxnx5s56l******" | omitir para prompt seguro] \
#       [--format csv|json|yaml|hcl|all] \
#       [--output inventario_contingencia]
#
# Ejemplos:
#   # Contingencia (pide password interactivamente):
#   ./get-vm-inventory.sh --host vcenter-cont.dominio.local \
#       --user svc-ansible@vsphere.local \
#       --datacenter "DATACENTER CONTINGENCIA"
#
#   # Producción con password en variable de entorno:
#   VCENTER_PASSWORD="mipass" ./get-vm-inventory.sh --host vcenter-prod.dominio.local \
#       --user svc-ansible@vsphere.local \
#       --datacenter "DATACENTER PRODUCCION"

set -euo pipefail

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${CYAN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
hdr()  { echo -e "\n${BLUE}${BOLD}══════════════════════════════════════════${NC}"; echo -e "${BLUE}${BOLD}  $*${NC}"; echo -e "${BLUE}${BOLD}══════════════════════════════════════════${NC}\n"; }

# ─── Ubicar script Python ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_PY="${SCRIPT_DIR}/vm_inventory.py"

if [[ ! -f "$INVENTORY_PY" ]]; then
    err "No se encontró vm_inventory.py en $SCRIPT_DIR"
    exit 1
fi

# ─── Verificar Python ────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    err "Python3 no instalado. Ejecuta: sudo apt-get install python3"
    exit 1
fi

if ! python3 -c "import pyVim" 2>/dev/null; then
    err "pyVmomi no instalado. Ejecuta: pip3 install --user pyVmomi"
    exit 1
fi

# ─── Parsear argumentos ──────────────────────────────────────────────────────
HOST=""
USER=""
PASSWORD="${VCENTER_PASSWORD:-}"
DATACENTER=""
FORMAT="all"
OUTPUT=""
ENV="contingencia"

usage() {
    echo "Uso: $0 --host <vcenter> --user <usuario> --datacenter <dc> [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --host        FQDN o IP del vCenter (requerido)"
    echo "  --user        Usuario vCenter (requerido)"
    echo "  --datacenter  Nombre del Datacenter (requerido)"
    echo "  --password    Password (opcional, prompt seguro si se omite)"
    echo "  --format      Formato: csv, json, hcl, all (default: all)"
    echo "  --output      Prefijo del archivo de salida (default: inventario_<dc>)"
    echo "  --env         Nombre del entorno: contingencia | produccion (default: contingencia)"
    echo ""
    echo "Variables de entorno:"
    echo "  VCENTER_PASSWORD  Password (alternativa a --password)"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)       HOST="$2";       shift 2 ;;
        --user)       USER="$2";       shift 2 ;;
        --password)   PASSWORD="$2";   shift 2 ;;
        --datacenter) DATACENTER="$2"; shift 2 ;;
        --format)     FORMAT="$2";     shift 2 ;;
        --output)     OUTPUT="$2";     shift 2 ;;
        --env)        ENV="$2";        shift 2 ;;
        --help|-h)    usage ;;
        *) err "Argumento desconocido: $1"; usage ;;
    esac
done

# Validar requeridos
if [[ -z "$HOST" || -z "$USER" || -z "$DATACENTER" ]]; then
    err "Faltan argumentos requeridos: --host, --user, --datacenter"
    usage
fi

# Output por defecto
if [[ -z "$OUTPUT" ]]; then
    # Convertir datacenter a nombre de archivo (sin espacios, minúsculas)
    SAFE_NAME=$(echo "$DATACENTER" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    OUTPUT="inventario_${SAFE_NAME}"
fi

# ─── Banner ──────────────────────────────────────────────────────────────────
clear
cat << 'EOF'
  ╔══════════════════════════════════════════════════════════════╗
  ║       Inventario Automático de VMs — VMware vSphere          ║
  ╚══════════════════════════════════════════════════════════════╝
EOF
echo ""
info "vCenter:    $HOST"
info "Usuario:    $USER"
info "Datacenter: $DATACENTER"
info "Formato:    $FORMAT"
info "Output:     $OUTPUT.*"
echo ""

# ─── Password ────────────────────────────────────────────────────────────────
if [[ -z "$PASSWORD" ]]; then
    read -s -p "Password para $USER@$HOST: " PASSWORD
    echo ""
fi

# ─── Ejecutar inventario Python ──────────────────────────────────────────────
hdr "Conectando a vCenter y recopilando datos..."

START_TIME=$(date +%s)

python3 "$INVENTORY_PY" \
    --host       "$HOST" \
    --user       "$USER" \
    --password   "$PASSWORD" \
    --datacenter "$DATACENTER" \
    --format     "$FORMAT" \
    --output     "$OUTPUT" \
    --env        "$ENV"

EXIT_CODE=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [[ $EXIT_CODE -ne 0 ]]; then
    err "El inventario falló con código de error $EXIT_CODE"
    exit $EXIT_CODE
fi

ok "Inventario completado en ${ELAPSED}s"

# ─── Mostrar estadísticas del CSV ────────────────────────────────────────────
CSV_FILE="${OUTPUT}.csv"

if [[ -f "$CSV_FILE" ]]; then
    hdr "ESTADÍSTICAS DEL INVENTARIO"

    TOTAL=$(($(wc -l < "$CSV_FILE") - 1))   # Restar header
    ok "Total VMs procesadas: $TOTAL"
    echo ""

    # Requiere python3 para parsear CSV y mostrar stats
    python3 - << PYEOF
import csv, collections, sys

csv_file = "${CSV_FILE}"

try:
    with open(csv_file, newline='', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))
except Exception as e:
    print(f"No se pudo parsear CSV para estadísticas: {e}")
    sys.exit(0)

if not rows:
    print("CSV vacío")
    sys.exit(0)

# Estado de energía
states = collections.Counter(r.get('power_state','') for r in rows)
print("Estado de VMs:")
print(f"  ► Encendidas:   {states.get('poweredOn', 0)}")
print(f"  ► Apagadas:     {states.get('poweredOff', 0)}")
print(f"  ► Suspendidas:  {states.get('suspended', 0)}")

# Recursos
cpus    = sum(int(r.get('num_cpus', 0) or 0) for r in rows)
mem_gb  = sum(int(r.get('memory_mb', 0) or 0) for r in rows) / 1024
print(f"\nRecursos totales:")
print(f"  ► Total vCPUs:  {cpus}")
print(f"  ► Total RAM:    {mem_gb:.1f} GB")

# VMware Tools
tools_status = collections.Counter(r.get('tools_status','') for r in rows)
print(f"\nVMware Tools:")
for status, count in tools_status.most_common():
    icon = "✓" if status == "guestToolsRunning" else "!"
    print(f"  [{icon}] {status or 'desconocido'}: {count} VMs")

# Top SOs
guest_os = collections.Counter(r.get('guest_full','') for r in rows)
print(f"\nTop 5 Sistemas Operativos:")
for os_name, count in guest_os.most_common(5):
    print(f"  ► {os_name or 'Desconocido'}: {count}")

# Clusters
clusters = collections.Counter(r.get('cluster','') for r in rows)
if len(clusters) > 0:
    print(f"\nDistribución por Cluster:")
    for cluster, count in clusters.most_common():
        print(f"  ► {cluster or 'Sin cluster'}: {count} VMs")
PYEOF

    echo ""
fi

# ─── Archivos generados ──────────────────────────────────────────────────────
hdr "ARCHIVOS GENERADOS"

for f in "${OUTPUT}.csv" "${OUTPUT}.json" "${OUTPUT}.tfvars.hcl" "import-${ENV}.sh"; do
    if [[ -f "$f" ]]; then
        SIZE=$(du -h "$f" | cut -f1)
        ok "$f  ($SIZE)"
    fi
done

echo ""
echo -e "${YELLOW}Siguiente paso:${NC}"
echo "  1. Revisar ${OUTPUT}.csv y clasificar VMs por criticidad"
echo "  2. Para Terraform: copiar contenido de ${OUTPUT}.tfvars.hcl en terraform/environments/${ENV}/terraform.tfvars"
echo "  3. Para importar: bash import-${ENV}.sh  (desde terraform/environments/${ENV}/)"
echo ""
