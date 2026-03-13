# Proyecto IaC — VMware vSphere con Terraform y Ansible

Infraestructura como Código para dos datacenters VMware vSphere 8 con IBM FlashSystem 7300, vSphere Foundation (TKG) y automatización de escalado de recursos.

---

## 🐧 Ejecutar en WSL Ubuntu (Recomendado)

Este proyecto está optimizado para ejecutarse en **WSL (Windows Subsystem for Linux)** con Ubuntu.

### Setup Automático (⚡ Inicio Rápido)

```bash
# 1. Desde Windows, abrir WSL Ubuntu
wsl

# 2. Navegar al proyecto (desde Windows filesystem)
cd "/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC"

# 3. Ejecutar script de setup automático
chmod +x setup-wsl.sh
./setup-wsl.sh

# 4. Cargar variables de entorno
source .env

# 5. Ejecutar inventario de VMs
cd scripts/discovery
chmod +x run-inventory.sh
./run-inventory.sh cont        # Contingencia
./run-inventory.sh prod        # Producción
./run-inventory.sh both        # Ambos ambientes
```

El script `setup-wsl.sh` instala automáticamente:
- ✅ Python 3.11+ y dependencias (pyVmomi, PyYAML, etc.)
- ✅ Terraform 1.7+
- ✅ Ansible 2.15+ con colecciones VMware
- ✅ Git y herramientas auxiliares
- ✅ Configuración de variables de entorno

### Ejecución Manual del Inventario

```bash
# Opción 1: Con script wrapper (más fácil)
cd scripts/discovery
./run-inventory.sh cont csv      # Contingencia en CSV
./run-inventory.sh prod json     # Producción en JSON

# Opción 2: Directamente con Python
python3 vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format csv \
  --output inventario_contingencia.csv
```

---

## Arquitectura

| DC | vCenter | Clusters | VMs | Storage |
|---|---|---|---|---|
| Producción | vcenter-prod.dominio.local | cluster-app (5 ESXi) + cluster-db (2 ESXi) | ~300 | IBM FS7300 |
| Contingencia | vcenter-cont.dominio.local | cluster-cont (2 ESXi) | ~30 | IBM FS7300 |

---

## Estructura del Proyecto

```
PROYECTO IAAC/
├── PLAN_TRABAJO.md               ← Plan completo por fases
├── .gitignore
├── .gitlab-ci.yml                ← Pipeline CI/CD
│
├── terraform/
│   ├── backend.tf                ← Configuración state remoto (MinIO/S3)
│   ├── modules/
│   │   └── vsphere-vm/           ← Módulo reutilizable VMs
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── contingencia/         ← Entorno contingencia (primero)
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── terraform.tfvars  ← NO commitear (en .gitignore)
│       └── produccion/           ← Entorno producción (después)
│           ├── main.tf
│           └── variables.tf
│
├── ansible/
│   ├── ansible.cfg
│   ├── requirements.yml          ← Colecciones: community.vmware, etc.
│   ├── inventory/
│   │   ├── contingencia/
│   │   │   ├── vmware.yml        ← Inventario dinámico vCenter
│   │   │   └── group_vars/all.yml
│   │   └── produccion/
│   │       └── vmware.yml
│   ├── playbooks/
│   │   ├── scale-resources.yml  ← PRINCIPAL: Escalado CPU/RAM/Disco
│   │   ├── vm-health-check.yml  ← Verificación de salud
│   │   └── vm-configure.yml     ← Baseline de configuración
│   ├── roles/
│   │   └── vm-scale-resources/  ← Role principal de escalado
│   │       ├── tasks/main.yml
│   │       ├── handlers/main.yml
│   │       └── defaults/main.yml
│   └── vars/
│       └── scale-batch-ejemplo.yml
│
└── scripts/
    ├── requirements.txt
    └── discovery/
        └── vm_inventory.py       ← Discovery automático → genera tfvars
```

---

## Inicio Rápido

### Opción 1: WSL Ubuntu (⭐ RECOMENDADO - Ver sección arriba)
```bash
./setup-wsl.sh              # Setup automático completo
source .env                 # Cargar variables de entorno
cd scripts/discovery
./run-inventory.sh cont     # Ejecutar inventario contingencia
```

### Opción 2: Linux/VM Jump Host (Instalación Manual)
```bash
# 1. Terraform
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# 2. Ansible + colecciones VMware
pip3 install ansible pyVmomi
ansible-galaxy collection install -r ansible/requirements.yml

# 3. Python para scripts de discovery
pip3 install -r scripts/requirements.txt

# 4. Ejecutar inventario
python3 scripts/discovery/vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format csv \
  --output inventario_contingencia.csv
```

### Opción 3: Windows (PowerShell)
```powershell
# Instalar PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Ejecutar inventario
cd scripts\discovery
.\Get-VMInventory.ps1 -VCenter vcenter-cont.dominio.local -Datacenter "DATACENTER CONTINGENCIA"
#   import-contingencia.sh      (script de terraform import)
```

### 3. Terraform — Importar VMs existentes de Contingencia
```bash
cd terraform/environments/contingencia

# Configurar credenciales via variables de entorno (NUNCA en código)
export TF_VAR_vsphere_user="svc-terraform@vsphere.local"
export TF_VAR_vsphere_password="PASSWORD_SEGURO"
export AWS_ACCESS_KEY_ID="MINIO_KEY"
export AWS_SECRET_ACCESS_KEY="MINIO_SECRET"

# Copiar sección vms_contingencia del archivo HCL generado a terraform.tfvars
# luego:
terraform init
terraform plan   # debe mostrar recursos a crear (tags, resource pools, folders)

# Importar VMs existentes (no las crea, las adopta en el state)
bash ../../../scripts/discovery/import-contingencia.sh

# Verificar estado post-import
terraform plan   # debe mostrar 0 cambios en VMs importadas
```

### 4. Ansible — Health Check inicial
```bash
cd ansible

# Variables de entorno para inventario dinámico
export VMWARE_HOST="vcenter-cont.dominio.local"
export VMWARE_USER="svc-ansible@vsphere.local"
export VMWARE_PASSWORD="PASSWORD"

# Verificar inventario dinámico
ansible-inventory -i inventory/contingencia/ --graph

# Health check completo
ansible-playbook playbooks/vm-health-check.yml -i inventory/contingencia/ -v
```

### 5. Escalar recursos de una VM
```bash
# Via Ansible (recomendado para operaciones)
ansible-playbook playbooks/scale-resources.yml \
  -e "scale_vm_name=vm-app-cont-01" \
  -e "scale_datacenter=DC-Contingencia" \
  -e "scale_cpu=8" \
  -e "scale_memory_mb=16384"

# Agregar disco de 200GB
ansible-playbook playbooks/scale-resources.yml \
  -e "scale_vm_name=vm-db-cont-01" \
  -e "scale_datacenter=DC-Contingencia" \
  -e '{"scale_add_disk": {"size_gb": 200, "thin": false}}'

# Via Terraform (para cambios permanentes en el estado deseado)
# Editar terraform.tfvars: cambiar memory_mb: 8192 → 16384
# terraform plan → verificar cambio
# terraform apply → aplicar
```

### 6. Escalar múltiples VMs en lote
```bash
# Editar ansible/vars/scale-batch-ejemplo.yml con las VMs a escalar
ansible-playbook playbooks/scale-resources.yml \
  -e "@vars/scale-batch-ejemplo.yml"
```

---

## Seguridad

- **Principio mínimo privilegio**: usuarios de servicio separados para Terraform y Ansible
- **`prevent_destroy = true`**: en todas las VMs de producción
- **Snapshot automático** antes de cada operación de escalado
- **Aprobación manual** requerida en pipeline CI/CD antes de `terraform apply` en producción
- **State remoto** con locking para evitar operaciones concurrentes
- **Credenciales via variables de entorno** — nunca en código fuente

---

## Variables de Entorno Requeridas

| Variable | Descripción | Entorno |
|---|---|---|
| `TF_VAR_vsphere_user` | Usuario servicio Terraform | Ambos |
| `TF_VAR_vsphere_password` | Password vCenter | Ambos |
| `VMWARE_HOST` | FQDN vCenter | Ansible |
| `VMWARE_USER` | Usuario Ansible | Ansible |
| `VMWARE_PASSWORD` | Password Ansible | Ansible |
| `AWS_ACCESS_KEY_ID` | MinIO access key (backend) | Terraform |
| `AWS_SECRET_ACCESS_KEY` | MinIO secret key (backend) | Terraform |

---

## Notas Técnicas Importantes

### Hot-Add CPU/RAM
- Requiere **VMware Tools** instalado y corriendo en la VM
- Requiere SO compatible: RHEL/CentOS 7+, Ubuntu 18.04+, Windows 2016+
- Para VMs **Windows**: requiere edición específica y puede necesitar reinicio
- Verificar con: `ansible-playbook playbooks/vm-health-check.yml`

### IBM FlashSystem 7300
- Los datastores se presentan via iSCSI o Fibre Channel a los hosts ESXi
- El nombre del datastore en vCenter debe coincidir exactamente con `datastore_names` en tfvars
- Para discos thick eager zeroed (mejor IOPS para DB): `thin_provisioned: false, eagerly_scrub: true`

### Hivecloud (Microsegmentación)
- Coordinar con equipo Hivecloud antes de activar Ansible hacia VMs
- El inventario dinámico usa la IP reportada por VMware Tools — verificar que sea la IP de gestión

### vSphere Foundation + TKG
- TKG Supervisor Cluster disponible para despliegue en Fase 3
- Requiere configuración de vDS y storage policy antes de activar Supervisor

---

## Repositorio Git — Branching Strategy

### Ramas

| Rama | Propósito | Merge hacia |
|------|-----------|-------------|
| `main` | Código aprobado y estable — equivale a producción | — |
| `develop` | Integración de trabajo en curso | `main` (vía PR) |
| `feature/tarea-X.X-descripcion` | Desarrollo de cada tarea del plan | `develop` |
| `hotfix/descripcion` | Correcciones urgentes sobre `main` | `main` + `develop` |

### Flujo de trabajo

```
feature/tarea-1.1-xxx  ──┐
feature/tarea-1.2-xxx  ──┤──► develop ──── PR ──► main
feature/tarea-1.3-xxx  ──┘
```

1. Crear rama `feature/tarea-X.X-descripcion` desde `develop`
2. Desarrollar y hacer commits en la feature branch
3. Abrir Pull Request hacia `develop`
4. Revisar y mergear a `develop`
5. Cuando el sprint/fase está completo → PR de `develop` a `main`

### Convención de commits

```
feat:     nueva funcionalidad o script
fix:      corrección de bug
docs:     cambios solo en documentación
refactor: reorganización de código sin cambio de comportamiento
chore:    cambios en .gitignore, dependencias, configuración
```

**Ejemplos:**
```
feat: tarea 0.5 test-vm-connectivity.sh (27 VMs probadas)
fix: corregir contador bash con set -e en test-vm-connectivity
docs: agregar naming conventions VMs contingencia
chore: agregar *.backup a .gitignore
```

### Archivos nunca commiteados (.gitignore)

- `terraform.tfvars` — credenciales vCenter
- `*.tfstate` / `*.backup` — estado de Terraform (contiene IPs y datos sensibles)
- `inventario_datacenter_*.csv/json` — inventario con IPs del datacenter
- `*.pem` / `*.key` — claves SSH

---

## Licencias
- Terraform: Mozilla Public License 2.0
- Ansible: GNU General Public License v3.0
- pyVmomi: Apache License 2.0
- VMware vSphere Foundation: Licencia comercial activa en ambos datacenters
