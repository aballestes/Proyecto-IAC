#!/bin/bash
#
# setup-wsl.sh — Configuración del entorno IaC en WSL Ubuntu
# ===========================================================
# Este script instala todas las dependencias necesarias para trabajar
# con el proyecto de Infrastructure as Code (Terraform + Ansible) en WSL.
#
# Uso:
#   chmod +x setup-wsl.sh
#   ./setup-wsl.sh
#

set -euo pipefail

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones auxiliares
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Configuración del Entorno IaC - WSL Ubuntu              ║
║     Terraform + Ansible + Python para VMware vSphere         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

print_info "Este script instalará:"
echo "  • Python 3.11+"
echo "  • Terraform 1.7+"
echo "  • Ansible 2.15+"
echo "  • Dependencias Python (pyVmomi, PyYAML, etc.)"
echo "  • Git"
echo "  • Herramientas auxiliares"
echo ""
read -p "¿Continuar con la instalación? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    print_warning "Instalación cancelada"
    exit 0
fi

# ==============================================================================
# 1. ACTUALIZAR SISTEMA
# ==============================================================================
print_header "1. Actualizando sistema operativo"

print_info "Actualizando índice de paquetes..."
sudo apt-get update -qq

print_success "Sistema actualizado"

# ==============================================================================
# 2. INSTALAR DEPENDENCIAS BASE
# ==============================================================================
print_header "2. Instalando dependencias base"

print_info "Instalando herramientas de compilación y utilidades..."
sudo apt-get install -y \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    git \
    jq \
    unzip \
    vim \
    tree \
    > /dev/null 2>&1

print_success "Dependencias base instaladas"

# ==============================================================================
# 3. INSTALAR PYTHON 3.11+
# ==============================================================================
print_header "3. Instalando Python 3.11+"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    print_info "Python ya instalado: $PYTHON_VERSION"
else
    print_info "Instalando Python 3..."
    sudo apt-get install -y python3 python3-pip python3-venv > /dev/null 2>&1
    print_success "Python 3 instalado"
fi

# Verificar versión de Python
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')

if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 11 ]; then
    print_success "Python $PYTHON_MAJOR.$PYTHON_MINOR detectado (OK)"
else
    print_warning "Python 3.11+ recomendado (detectado: $PYTHON_MAJOR.$PYTHON_MINOR)"
fi

# Instalar pip si no existe
if ! command -v pip3 &> /dev/null; then
    print_info "Instalando pip..."
    sudo apt-get install -y python3-pip > /dev/null 2>&1
    print_success "pip instalado"
fi

# ==============================================================================
# 4. INSTALAR DEPENDENCIAS PYTHON
# ==============================================================================
print_header "4. Instalando dependencias Python"

# Crear/usar entorno virtual local para evitar restricciones de Python 3.12
if [ ! -d ".venv" ]; then
    print_info "Creando entorno virtual .venv para dependencias Python..."
    python3 -m venv .venv
    print_success "Entorno virtual .venv creado"
fi

# Activar entorno virtual
print_info "Activando entorno virtual .venv..."
source .venv/bin/activate

if [ -f "scripts/requirements.txt" ]; then
    print_info "Instalando desde scripts/requirements.txt dentro de .venv..."
    python3 -m pip install -r scripts/requirements.txt
    print_success "Dependencias Python instaladas en .venv"
else
    print_warning "Archivo scripts/requirements.txt no encontrado"
    print_info "Instalando dependencias manualmente en .venv..."
    python3 -m pip install pyVmomi>=8.0.3 PyYAML>=6.0 tabulate>=0.9.0 requests>=2.31.0 colorama>=0.4.6 Jinja2>=3.1.0
    print_success "Dependencias instaladas manualmente en .venv"
fi

# ==============================================================================
# 5. INSTALAR TERRAFORM
# ==============================================================================
print_header "5. Instalando Terraform"

if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_info "Terraform ya instalado: $TERRAFORM_VERSION"
    
    # Verificar si es >= 1.7
    TERRAFORM_MAJOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f1)
    TERRAFORM_MINOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f2)
    
    if [ "$TERRAFORM_MAJOR" -ge 1 ] && [ "$TERRAFORM_MINOR" -ge 7 ]; then
        print_success "Terraform $TERRAFORM_VERSION (OK)"
    else
        print_warning "Terraform 1.7+ recomendado, actualizando..."
        INSTALL_TERRAFORM=true
    fi
else
    INSTALL_TERRAFORM=true
fi

if [ "${INSTALL_TERRAFORM:-false}" = true ]; then
    print_info "Descargando e instalando Terraform..."
    
    # Detectar arquitectura
    ARCH=$(dpkg --print-architecture)
    TERRAFORM_VERSION="1.7.5"
    
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -O /tmp/terraform.zip
    
    unzip -q /tmp/terraform.zip -d /tmp
    sudo mv /tmp/terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm /tmp/terraform.zip
    
    print_success "Terraform $(terraform version -json | jq -r '.terraform_version') instalado"
fi

# Verificar instalación
terraform version > /dev/null 2>&1 && print_success "Terraform funcional"

# ==============================================================================
# 6. INSTALAR ANSIBLE
# ==============================================================================
print_header "6. Instalando Ansible"

if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1 | awk '{print $3}' | tr -d '[]')
    print_info "Ansible ya instalado: $ANSIBLE_VERSION"
else
    print_info "Instalando Ansible..."
    sudo apt-get install -y ansible > /dev/null 2>&1
    print_success "Ansible instalado"
fi

# Instalar colecciones de Ansible para VMware
print_info "Instalando colección community.vmware..."
ansible-galaxy collection install community.vmware --force > /dev/null 2>&1
print_success "Colección community.vmware instalada"

# Verificar si existe requirements.yml
if [ -f "ansible/requirements.yml" ]; then
    print_info "Instalando colecciones desde ansible/requirements.yml..."
    ansible-galaxy collection install -r ansible/requirements.yml --force > /dev/null 2>&1
    print_success "Colecciones Ansible instaladas"
fi

# ==============================================================================
# 7. CONFIGURAR GIT
# ==============================================================================
print_header "7. Configurando Git"

if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "Git $GIT_VERSION instalado"
    
    # Verificar configuración de Git
    if ! git config --global user.name &> /dev/null; then
        print_warning "Git no configurado. Ejecuta:"
        echo "  git config --global user.name 'Tu Nombre'"
        echo "  git config --global user.email 'tu@email.com'"
    else
        GIT_USER=$(git config --global user.name)
        GIT_EMAIL=$(git config --global user.email)
        print_info "Usuario Git: $GIT_USER <$GIT_EMAIL>"
    fi
else
    print_error "Git no instalado"
fi

# ==============================================================================
# 8. HACER SCRIPTS EJECUTABLES
# ==============================================================================
print_header "8. Configurando permisos de scripts"

if [ -d "scripts/discovery" ]; then
    print_info "Haciendo scripts ejecutables..."
    chmod +x scripts/discovery/*.py 2>/dev/null || true
    chmod +x scripts/discovery/*.sh 2>/dev/null || true
    print_success "Permisos configurados"
fi

# ==============================================================================
# 9. CREAR ALIAS Y VARIABLES DE ENTORNO
# ==============================================================================
print_header "9. Configurando variables de entorno"

# Crear archivo de variables de entorno
cat > .env << 'EOF'
# Variables de entorno para proyecto IaC VMware
# Cargar con: source .env

# vCenter Contingencia
export VCENTER_CONT_HOST="vcenter-cont.dominio.local"
export VCENTER_CONT_USER="svc-ansible@vsphere.local"
export VCENTER_CONT_DATACENTER="DATACENTER CONTINGENCIA"

# vCenter Producción
export VCENTER_PROD_HOST="vcenter-prod.dominio.local"
export VCENTER_PROD_USER="svc-ansible@vsphere.local"
export VCENTER_PROD_DATACENTER="DATACENTER PRODUCCION"

# Colores en terminal
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Python
export PYTHONUNBUFFERED=1

# Terraform
export TF_LOG_PATH="./terraform.log"

# Ansible
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_STDOUT_CALLBACK=yaml
export ANSIBLE_CALLBACKS_ENABLED=profile_tasks

echo "✓ Variables de entorno IaC cargadas"
EOF

print_success "Archivo .env creado"
print_info "Cargar con: source .env"

# ==============================================================================
# 10. VERIFICACIÓN FINAL
# ==============================================================================
print_header "10. Verificación de instalación"

echo ""
echo "  ✓ Python:    $(python3 --version | awk '{print $2}')"
echo "  ✓ pip:       $(pip3 --version | awk '{print $2}')"
echo "  ✓ Terraform: $(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'ERROR')"
echo "  ✓ Ansible:   $(ansible --version | head -n 1 | awk '{print $3}' | tr -d '[]')"
echo "  ✓ Git:       $(git --version | awk '{print $3}')"

# Verificar módulos Python
echo ""
print_info "Verificando módulos Python..."
python3 -c "import pyVim; print('  ✓ pyVmomi')" 2>/dev/null || print_error "  ✗ pyVmomi (ERROR)"
python3 -c "import yaml; print('  ✓ PyYAML')" 2>/dev/null || print_error "  ✗ PyYAML (ERROR)"
python3 -c "import tabulate; print('  ✓ tabulate')" 2>/dev/null || print_error "  ✗ tabulate (ERROR)"
python3 -c "import requests; print('  ✓ requests')" 2>/dev/null || print_error "  ✗ requests (ERROR)"

# ==============================================================================
# FINALIZACIÓN
# ==============================================================================
print_header "¡INSTALACIÓN COMPLETADA!"

cat << EOF

${GREEN}✓ El entorno IaC está listo para usar${NC}

${YELLOW}Próximos pasos:${NC}

  1. Cargar variables de entorno:
     ${CYAN}source .env${NC}

  2. Ejecutar inventario de VMs (Contingencia):
     ${CYAN}cd scripts/discovery${NC}
     ${CYAN}./run-inventory.sh cont${NC}

  3. Ejecutar inventario de VMs (Producción):
     ${CYAN}./run-inventory.sh prod${NC}

  4. Ver documentación completa:
     ${CYAN}cat docs/GUIA_INVENTARIO_VMS.md${NC}

${YELLOW}Archivos creados:${NC}
  • .env → Variables de entorno
  • scripts/discovery/run-inventory.sh → Script wrapper para inventarios

${YELLOW}Comandos útiles:${NC}
  • ${CYAN}terraform --version${NC}
  • ${CYAN}ansible --version${NC}
  • ${CYAN}python3 scripts/discovery/vm_inventory.py --help${NC}

EOF

print_success "Setup completado exitosamente"
