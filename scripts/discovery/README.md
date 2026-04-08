# Scripts de Inventario de VMs

Esta carpeta contiene scripts para realizar el inventario automático de VMs en VMware vCenter (Tarea 0.2 del Plan de Trabajo).

## 📁 Archivos Disponibles

- **`vm_inventory.py`**: Script Python con pyVmomi (Linux/Windows/macOS)
- **`Get-VMInventory.ps1`**: Script PowerShell con PowerCLI (Windows/PowerShell 7)
- **`run-inventory.sh`**: Script wrapper bash para WSL/Linux (⭐ RECOMENDADO)
- **`README.md`**: Este archivo (guía rápida)

## 🐧 Uso en WSL Ubuntu (⭐ RECOMENDADO)

### Setup Inicial (Solo Primera Vez)

```bash
# 1. Desde Windows, abrir WSL
wsl

# 2. Navegar al proyecto
cd "/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC"

# 3. Ejecutar setup completo
chmod +x setup-wsl.sh
./setup-wsl.sh

# 4. Cargar variables de entorno
source .env
```

### Ejecutar Inventario

```bash
cd scripts/discovery

# Hacer script ejecutable (solo primera vez)
chmod +x run-inventory.sh

# CONTINGENCIA (30 VMs aprox)
./run-inventory.sh cont

# PRODUCCIÓN (300 VMs aprox)
./run-inventory.sh prod

# AMBOS ambientes
./run-inventory.sh both

# Especificar formato de salida
./run-inventory.sh cont csv      # CSV (por defecto)
./run-inventory.sh prod json     # JSON
./run-inventory.sh cont yaml     # YAML
./run-inventory.sh prod hcl      # Terraform HCL
```

El script pedirá la contraseña interactivamente (más seguro que ponerla en línea de comandos).

---

## 🚀 Uso Directo (Python)

### Linux/WSL/macOS

```bash
# Contingencia
python3 vm_inventory.py \
    --host vcenter-cont.dominio.local \
    --user svc-ansible@vsphere.local \
    --datacenter "DATACENTER CONTINGENCIA" \
    --format csv \
    --output inventario_contingencia.csv

# Producción
python3 vm_inventory.py \
    --host vcenter-prod.dominio.local \
    --user svc-ansible@vsphere.local \
    --datacenter "DATACENTER PRODUCCION" \
    --format csv \
    --output inventario_produccion.csv
```

### Windows (PowerShell)

```powershell
# Instalar PowerCLI (solo primera vez)
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Ejecutar para CONTINGENCIA
.\Get-VMInventory.ps1 `
    -VCenter vcenter-cont.dominio.local `
    -Datacenter "DATACENTER CONTINGENCIA" `
    -OutputPath "inventario_contingencia.csv"

# Ejecutar para PRODUCCIÓN
.\Get-VMInventory.ps1 `
    -VCenter vcenter-prod.dominio.local `
    -Datacenter "DATACENTER PRODUCCION" `
    -OutputPath "inventario_produccion.csv"
```

## 📊 Información Recopilada

Ambos scripts generan un CSV con las siguientes columnas:

| Campo | Descripción |
|-------|-------------|
| **VM_Name** | Nombre de la máquina virtual |
| **Power_State** | Estado (PoweredOn/PoweredOff/Suspended) |
| **vCPU** | Número de CPUs virtuales |
| **Memory_GB** | Memoria RAM en GB |
| **Total_Disks_GB** | Espacio total en discos |
| **Disk_Count** | Número de discos |
| **NIC_Count** | Número de interfaces de red |
| **Guest_OS** | Sistema operativo |
| **IP_Address** | Dirección(es) IP |
| **VMware_Tools_Status** | Estado de VMware Tools |
| **Cluster** | Cluster donde está ubicada |
| **ESXi_Host** | Host ESXi donde corre |
| **Datastore** | Datastore(s) usado(s) |
| **Networks** | Redes conectadas |
| **CPU_Hot_Add_Enabled** | Hot-add de CPU habilitado |
| **Memory_Hot_Add_Enabled** | Hot-add de memoria habilitado |
| **Snapshots_Count** | Número de snapshots |
| **Hardware_Version** | Versión de hardware virtual |
| **UUID** | Identificador único |

... y más campos adicionales.

## 📋 Diferencias entre Scripts

| Característica | Python (pyVmomi) | PowerShell (PowerCLI) |
|----------------|------------------|----------------------|
| **Plataforma** | Windows, Linux, macOS | Windows, Linux, macOS |
| **Prerequisitos** | Python 3.11+ + pyVmomi | PowerShell 7+ + PowerCLI |
| **Performance** | ⚡ Muy rápido | ⚡ Rápido |
| **Formatos salida** | CSV, JSON, YAML, HCL | CSV solamente |
| **Estadísticas** | ❌ No incluidas | ✅ Automáticas en consola |
| **Colores/UI** | ❌ Básico | ✅ Salida coloreada |
| **Barra progreso** | ❌ No | ✅ Sí |
| **Uso típico** | CI/CD, automatización | Administración interactiva |

## 🔍 Siguiente Paso: Clasificar VMs

Después de generar los inventarios, debes clasificar las VMs por criticidad:

1. Abrir el CSV en Excel o LibreOffice Calc
2. Agregar columna **"Criticidad"**
3. Clasificar cada VM:
   - **CRÍTICA**: Bases de datos productivas, aplicaciones core
   - **ALTA**: Aplicaciones de negocio importantes
   - **MEDIA**: Servicios auxiliares, desarrollo
   - **BAJA**: Pruebas, QA, laboratorios

4. Guardar como `inventario_contingencia_clasificado.xlsx` y `inventario_produccion_clasificado.xlsx`

## ⚠️ Problemas Comunes

### Error: "VMware Tools not installed"
- Algunas VMs pueden no tener VMware Tools
- El inventario se genera igual, pero falta info de IP/hostname
- **Acción**: Documentar en lista de problemas para Task 0.4

### Error: "Certificate verification failed"
- Ambos scripts ignoran certificados SSL autofirmados
- Es normal en entornos vCenter con certificados internos

### Error: "Login failed" / "Invalid credentials"
- Verificar usuario/contraseña
- Usuario debe tener al menos rol "Read-only" en vCenter
- Formato usuario: `svc-ansible@vsphere.local` o `DOMINIO\usuario`

### Script muy lento (>30 min para 300 VMs)
- **Python**: El script usa Container View, debería ser rápido
- **PowerShell**: PowerCLI puede ser más lento con muchas VMs
- Si es muy lento, ejecutar en un Jump Host más cercano al vCenter

## 📖 Documentación Completa

Para instrucciones detalladas, ver:
- **`../../docs/GUIA_INVENTARIO_VMS.md`**: Guía completa paso a paso
- **`../../PLAN_TRABAJO.md`**: Fase 0 completa del proyecto

##  Deliverables de Task 0.2

- [ ] `inventario_contingencia.csv` (30 VMs)
- [ ] `inventario_produccion.csv` (300 VMs)
- [ ] `inventario_contingencia_clasificado.xlsx` (con columna Criticidad)
- [ ] `inventario_produccion_clasificado.xlsx` (con columna Criticidad)
- [ ] Lista de VMs con problemas (sin VMware Tools, con snapshots, etc.)

---

**Contacto**: Equipo IaC  
**Versión**: 1.0  
**Última actualización**: 2024
