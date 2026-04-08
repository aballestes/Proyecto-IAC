# Guía de Ejecución en WSL Ubuntu

Este proyecto está optimizado para ejecutarse desde **Windows Subsystem for Linux (WSL)** con Ubuntu.

## 📋 Tabla de Contenidos
- [Prerequisitos](#prerequisitos)
- [Configuración Inicial](#configuración-inicial)
- [Ejecución de Scripts](#ejecución-de-scripts)
- [Troubleshooting](#troubleshooting)
- [Ventajas de WSL vs Windows](#ventajas-de-wsl-vs-windows)

---

## Prerequisitos

### 1. Instalar WSL Ubuntu (si no está instalado)

Desde **PowerShell como Administrador**:

```powershell
# Instalar WSL con Ubuntu
wsl --install -d Ubuntu

# O actualizar a WSL 2 (recomendado)
wsl --set-default-version 2
wsl --set-version Ubuntu 2

# Verificar instalación
wsl --list --verbose
```

### 2. Acceder a WSL Ubuntu

```powershell
# Desde PowerShell o CMD
wsl

# O desde el menú de Windows, buscar "Ubuntu"
```

---

## Configuración Inicial

### 1. Navegar al Proyecto desde WSL

Desde Ubuntu/WSL:

```bash
# El filesystem de Windows está montado en /mnt/
cd "/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC"

# Verificar que estás en la carpeta correcta
pwd
ls -la
```

### 2. Ejecutar Setup Automático

```bash
# Hacer el script ejecutable
chmod +x setup-wsl.sh

# Ejecutar instalación completa (toma ~5-10 minutos)
./setup-wsl.sh
```

**Este script instala automáticamente:**
- ✅ Python 3.11+ con pip
- ✅ Terraform 1.7.5
- ✅ Ansible 2.15+ con colección community.vmware
- ✅ Git y herramientas de desarrollo
- ✅ Dependencias Python: pyVmomi, PyYAML, tabulate, requests, colorama, jinja2
- ✅ Permisos ejecutables en scripts
- ✅ Archivo `.env` con variables de entorno

### 3. Cargar Variables de Entorno

```bash
# Cargar variables (hacer esto cada vez que abres una nueva terminal)
source .env
```

**Contenido del archivo `.env`:**
- vCenter de Contingencia: host, usuario, datacenter
- vCenter de Producción: host, usuario, datacenter
- Configuraciones de Terraform y Ansible

**💡 TIP:** Agregar `source .env` al final de `~/.bashrc` para carga automática:

```bash
echo "cd '/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC' && source .env" >> ~/.bashrc
```

---

## Ejecución de Scripts

### Inventario de VMs (Task 0.2)

#### Opción 1: Script Wrapper (⚡ Recomendado)

```bash
cd scripts/discovery

# Hacer scripts ejecutables (solo primera vez)
chmod +x run-inventory.sh

# Ejecutar inventario de CONTINGENCIA
./run-inventory.sh cont

# Ejecutar inventario de PRODUCCIÓN
./run-inventory.sh prod

# Ejecutar AMBOS ambientes
./run-inventory.sh both

# Especificar formato de salida
./run-inventory.sh cont csv      # CSV (por defecto)
./run-inventory.sh prod json     # JSON
./run-inventory.sh cont yaml     # YAML
./run-inventory.sh prod hcl      # Terraform HCL
```

El script pedirá la contraseña interactivamente (más seguro).

#### Opción 2: Python Directo

```bash
cd scripts/discovery

# Contingencia
python3 vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format csv \
  --output inventario_contingencia.csv

# La contraseña se pedirá interactivamente, o:
python3 vm_inventory.py \
  --host vcenter-cont.dominio.local \
  --user svc-ansible@vsphere.local \
  --password "TuPassword" \
  --datacenter "DATACENTER CONTINGENCIA" \
  --format csv \
  --output inventario_contingencia.csv
```

### Ver Ayuda de Comandos

```bash
# Ayuda del script Python
python3 scripts/discovery/vm_inventory.py --help

# Ayuda del wrapper bash
scripts/discovery/run-inventory.sh
```

---

## Troubleshooting

### ❌ Error: "Permission denied"

```bash
# Solución: Hacer scripts ejecutables
chmod +x setup-wsl.sh
chmod +x scripts/discovery/run-inventory.sh
chmod +x scripts/discovery/vm_inventory.py
```

### ❌ Error: "python3: command not found"

```bash
# Ejecutar setup de nuevo
./setup-wsl.sh

# O instalar Python manualmente
sudo apt-get update
sudo apt-get install python3 python3-pip
```

### ❌ Error: "pyVmomi module not found"

```bash
# Instalar dependencias Python
pip3 install --user -r scripts/requirements.txt

# O instalar manualmente
pip3 install --user pyVmomi PyYAML tabulate requests colorama Jinja2
```

### ❌ Error: "terraform: command not found"

```bash
# Reinstalar Terraform
cd /tmp
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform

# Verificar
terraform --version
```

### ❌ Error: "Bad interpreter: ^M"

Este error ocurre cuando los scripts tienen line endings de Windows (CRLF) en lugar de Unix (LF).

```bash
# Instalar dos2unix
sudo apt-get install dos2unix

# Convertir scripts
dos2unix setup-wsl.sh
dos2unix scripts/discovery/run-inventory.sh
dos2unix scripts/discovery/vm_inventory.py

# O configurar Git para auto-conversión
git config --global core.autocrlf input
```

### ❌ Lentitud al acceder a archivos de Windows

WSL 2 puede ser lento accediendo al filesystem de Windows (`/mnt/c/`).

**Soluciones:**

1. **Copiar proyecto a filesystem de Linux (⚡ RÁPIDO):**
```bash
# Copiar a home de usuario en WSL
cp -r "/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC" ~/proyecto-iaac
cd ~/proyecto-iaac

# Luego trabajar desde aquí (mucho más rápido)
./setup-wsl.sh
```

2. **Usar VSCode con WSL extension:**
```bash
# Instalar "Remote - WSL" extension en VSCode
# Desde WSL, abrir VSCode:
code .
```

### ❌ Error: "Login failed" / "Invalid credentials"

```bash
# Verificar conectividad a vCenter
ping vcenter-cont.dominio.local

# Probar autenticación manual
python3
>>> from pyVim.connect import SmartConnect
>>> import ssl
>>> ctx = ssl._create_unverified_context()
>>> si = SmartConnect(host="vcenter-cont.dominio.local", 
                     user="svc-ansible@vsphere.local", 
                     pwd="PASSWORD", 
                     sslContext=ctx)
>>> print(si.content.about.version)
```

---

## Ventajas de WSL vs Windows

| Aspecto | WSL Ubuntu | Windows (PowerShell) |
|---------|------------|---------------------|
| **Performance** | ⚡ Rápido (especialmente con Python) | ⚪ Normal |
| **Compatibilidad** | ✅ Scripts Linux nativos | ⚠️ Requiere adaptación |
| **Terraform** | ✅ Nativo | ✅ Funciona bien |
| **Ansible** | ✅ Nativo | ⚠️ Limitaciones en Windows |
| **Python** | ✅ Sin problemas de paths | ⚠️ Paths con espacios problemáticos |
| **Git** | ✅ Line endings correctos | ⚠️ CRLF vs LF issues |
| **CI/CD** | ✅ Mismo entorno que GitLab | ❌ Diferente |
| **Package Manager** | ✅ apt (miles de paquetes) | ⚠️ Chocolatey limitado |

**Recomendación:** Usar WSL para desarrollo y ejecución de scripts IaC.

---

## Comandos Útiles WSL

```bash
# Ver versión de WSL
wsl --version

# Listar distribuciones instaladas
wsl --list --verbose

# Detener WSL
wsl --shutdown

# Actualizar WSL
wsl --update

# Abrir WSL en ubicación específica (desde Windows)
wsl --cd "C:\BACKUP SEPTIEMBRE\GIFHUB\PROYECTO IAAC"

# Ver uso de recursos
wsl --status

# Exportar/Backup de distribución
wsl --export Ubuntu C:\backup-ubuntu.tar

# Acceder a archivos de WSL desde Windows
# Ir a: \\wsl$\Ubuntu\home\usuario\
```

---

## Next Steps

Después de completar el setup:

1. ✅ **Ejecutar inventario de Contingencia**
   ```bash
   cd scripts/discovery
   ./run-inventory.sh cont
   ```

2. ✅ **Clasificar VMs por criticidad** (Task 0.3)
   - Abrir CSV en Excel o LibreOffice
   - Agregar columna "Criticidad" (CRÍTICA/ALTA/MEDIA/BAJA)

3. ✅ **Ejecutar inventario de Producción**
   ```bash
   ./run-inventory.sh prod
   ```

4. ✅ **Configurar VMware** (Task 0.6-0.7)
   - Ver: `docs/GUIA_CONFIGURACION_VMWARE.md`
   - Crear usuarios: svc-terraform, svc-ansible
   - Asignar permisos

5. ✅ **Iniciar Terraform en Contingencia** (Fase 1)
   ```bash
   cd terraform/environments/contingencia
   terraform init
   terraform plan
   ```

---

## Documentación Adicional

- 📄 **Plan de Trabajo Completo:** `PLAN_TRABAJO.md`
- 📄 **Guía Configuración VMware:** `docs/GUIA_CONFIGURACION_VMWARE.md`
- 📄 **Guía Inventario VMs:** `docs/GUIA_INVENTARIO_VMS.md`
- 📄 **README Principal:** `README.md`

---

**Versión:** 1.0  
**Última actualización:** Febrero 2026  
**Contacto:** Equipo IaC
