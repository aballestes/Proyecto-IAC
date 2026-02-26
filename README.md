# Proyecto IaC — VMware vSphere con Terraform y Ansible

Infraestructura como Código para dos datacenters VMware vSphere 8 con IBM FlashSystem 7300, vSphere Foundation (TKG) y automatización de escalado de recursos.

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

### 1. Prerrequisitos (VM de control / Jump Host)
```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip && mv terraform /usr/local/bin/

# Ansible + colecciones VMware
pip3 install ansible pyVmomi
ansible-galaxy collection install -r ansible/requirements.yml

# Python para scripts de discovery
pip3 install -r scripts/requirements.txt
```

### 2. Fase 0 — Discovery de VMs existentes
```bash
# Descubrir VMs de contingencia y generar archivos Terraform
python3 scripts/discovery/vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --password "PASSWORD" \
  --datacenter DC-Contingencia \
  --env contingencia \
  --output scripts/discovery/inventario-cont

# Esto genera:
#   inventario-cont.csv         (para revisión humana)
#   inventario-cont.json        (datos completos)
#   inventario-cont.tfvars.hcl  (para terraform.tfvars)
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

## Licencias
- Terraform: Mozilla Public License 2.0
- Ansible: GNU General Public License v3.0
- pyVmomi: Apache License 2.0
- VMware vSphere Foundation: Licencia comercial activa en ambos datacenters
