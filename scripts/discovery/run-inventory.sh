#!/bin/bash
#
# run-inventory.sh — Wrapper para ejecutar inventario de VMs
# ===========================================================
# Simplifica la ejecución del script de inventario Python
#
# Uso:
#   ./run-inventory.sh cont          # Inventario de Contingencia
#   ./run-inventory.sh prod          # Inventario de Producción
#   ./run-inventory.sh both          # Ambos ambientes
#   ./run-inventory.sh cont csv      # Formato específico
#

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║   Inventario Automático de VMs - VMware vSphere      ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Usar el script desde donde se ejecuta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_SCRIPT="${SCRIPT_DIR}/vm_inventory.py"

# Verificar que el script Python existe
if [ ! -f "$INVENTORY_SCRIPT" ]; then
    print_error "Script no encontrado: $INVENTORY_SCRIPT"
    exit 1
fi

# Verificar Python
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 no está instalado"
    echo "Ejecuta: sudo apt-get install python3 python3-pip"
    exit 1
fi

# Verificar dependencias
if ! python3 -c "import pyVim" 2>/dev/null; then
    print_error "pyVmomi no está instalado"
    echo "Ejecuta: pip3 install -r ../../scripts/requirements.txt"
    exit 1
fi

# Configuración por defecto (cargar desde .env si existe)
if [ -f "../../.env" ]; then
    source ../../.env
    print_success "Variables de entorno cargadas desde .env"
fi

# Configuración de ambientes
VCENTER_CONT="${VCENTER_CONT_HOST:-vcenter-cont.dominio.local}"
VCENTER_CONT_USER="${VCENTER_CONT_USER:-svc-ansible@vsphere.local}"
VCENTER_CONT_DC="${VCENTER_CONT_DATACENTER:-DATACENTER CONTINGENCIA}"

VCENTER_PROD="${VCENTER_PROD_HOST:-vcenter-prod.dominio.local}"
VCENTER_PROD_USER="${VCENTER_PROD_USER:-svc-ansible@vsphere.local}"
VCENTER_PROD_DC="${VCENTER_PROD_DATACENTER:-DATACENTER PRODUCCION}"

# Función para ejecutar inventario
run_inventory() {
    local ENV=$1
    local FORMAT=${2:-csv}
    local VCENTER=""
    local USER=""
    local DATACENTER=""
    local OUTPUT=""
    
    if [ "$ENV" == "cont" ] || [ "$ENV" == "contingencia" ]; then
        VCENTER="$VCENTER_CONT"
        USER="$VCENTER_CONT_USER"
        DATACENTER="$VCENTER_CONT_DC"
        OUTPUT="inventario_contingencia.${FORMAT}"
    elif [ "$ENV" == "prod" ] || [ "$ENV" == "produccion" ]; then
        VCENTER="$VCENTER_PROD"
        USER="$VCENTER_PROD_USER"
        DATACENTER="$VCENTER_PROD_DC"
        OUTPUT="inventario_produccion.${FORMAT}"
    else
        print_error "Ambiente no válido: $ENV"
        echo "Uso: $0 {cont|prod|both} [csv|json|yaml]"
        exit 1
    fi
    
    print_info "Ejecutando inventario para: $DATACENTER"
    echo "  vCenter:    $VCENTER"
    echo "  Usuario:    $USER"
    echo "  Datacenter: $DATACENTER"
    echo "  Formato:    $FORMAT"
    echo "  Output:     $OUTPUT"
    echo ""
    
    # Pedir contraseña si no está en variable de entorno
    if [ -z "${VCENTER_PASSWORD:-}" ]; then
        read -s -p "Password para $USER: " VCENTER_PASSWORD
        echo ""
    fi
    
    # Ejecutar script Python
    print_info "Conectando a vCenter y recopilando información..."
    
    python3 "$INVENTORY_SCRIPT" \
        --host "$VCENTER" \
        --user "$USER" \
        --password "$VCENTER_PASSWORD" \
        --datacenter "$DATACENTER" \
        --format "$FORMAT" \
        --output "$OUTPUT"
    
    if [ $? -eq 0 ]; then
        print_success "Inventario generado exitosamente: $OUTPUT"
        
        # Mostrar estadísticas básicas del archivo
        if [ -f "$OUTPUT" ]; then
            FILE_SIZE=$(du -h "$OUTPUT" | cut -f1)
            if [ "$FORMAT" == "csv" ]; then
                LINE_COUNT=$(($(wc -l < "$OUTPUT") - 1))  # Restar header
                echo ""
                print_info "Estadísticas:"
                echo "  • VMs procesadas: $LINE_COUNT"
                echo "  • Tamaño archivo: $FILE_SIZE"
                echo ""
                print_info "Ver contenido: cat $OUTPUT | column -t -s, | less -S"
            fi
        fi
    else
        print_error "Error ejecutando inventario"
        exit 1
    fi
}

# Main
banner

# Validar argumentos
if [ $# -lt 1 ]; then
    print_error "Faltan argumentos"
    echo ""
    echo "Uso: $0 {cont|prod|both} [csv|json|yaml|hcl]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 cont              # Inventario contingencia en CSV"
    echo "  $0 prod json         # Inventario producción en JSON"
    echo "  $0 both yaml         # Ambos ambientes en YAML"
    echo ""
    exit 1
fi

ENVIRONMENT=$1
FORMAT=${2:-csv}

# Validar formato
if [[ ! "$FORMAT" =~ ^(csv|json|yaml|hcl)$ ]]; then
    print_error "Formato no válido: $FORMAT"
    echo "Formatos disponibles: csv, json, yaml, hcl"
    exit 1
fi

# Ejecutar según ambiente
case "$ENVIRONMENT" in
    cont|contingencia)
        run_inventory "cont" "$FORMAT"
        ;;
    prod|produccion)
        run_inventory "prod" "$FORMAT"
        ;;
    both|all|ambos)
        run_inventory "cont" "$FORMAT"
        echo ""
        echo "═══════════════════════════════════════════════════"
        echo ""
        run_inventory "prod" "$FORMAT"
        ;;
    *)
        print_error "Ambiente no reconocido: $ENVIRONMENT"
        echo "Opciones: cont, prod, both"
        exit 1
        ;;
esac

echo ""
print_success "Proceso completado"
echo ""
print_info "Siguiente paso: Clasificar VMs por criticidad"
echo "  1. Abrir el archivo CSV"
echo "  2. Agregar columna 'Criticidad' (CRÍTICA/ALTA/MEDIA/BAJA)"
echo "  3. Guardar como: inventario_${ENVIRONMENT}_clasificado.csv"
echo ""
