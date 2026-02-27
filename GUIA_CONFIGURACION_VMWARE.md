# GUÍA DE CONFIGURACIÓN VMWARE PARA IaC
## Paso 6: Prerrequisitos Técnicos en vCenter/vSphere

---

## 📋 ÍNDICE
1. [Usuarios de Servicio](#1-usuarios-de-servicio)
2. [Roles Personalizados](#2-roles-personalizados)
3. [Asignación de Permisos](#3-asignación-de-permisos)
4. [Configuración de Red/Firewall](#4-configuración-de-redfirewall)
5. [Validación VMware Tools](#5-validación-vmware-tools)
6. [Configuración Hot-Add](#6-configuración-hot-add)
7. [Validación Final](#7-validación-final)

---

## 1. USUARIOS DE SERVICIO

### 1.1 Crear Usuario para Terraform (vCenter SSO)

**🔹 En vCenter UI:**

```
1. Menú → Administration → Single Sign-On → Users and Groups
2. Domain: vsphere.local (o tu dominio SSO)
3. Click "Add User" (botón +)
   
   Username: svc-terraform
   Password: [Generar password seguro - mín 15 caracteres]
   Email: infraestructura@tudominio.com
   First Name: Terraform
   Last Name: Service Account
   Description: Service account for Infrastructure as Code - Terraform provisioning
   
4. Click "Add"
```

**📝 Guardar credenciales de forma segura:**
```bash
# En el Jump Host, crear archivo de variables de entorno
# NO versionar en Git
echo 'VSPHERE_USER=svc-terraform@vsphere.local' >> ~/.terraform_vsphere_creds
echo 'VSPHERE_PASSWORD=TU_PASSWORD_SEGURO' >> ~/.terraform_vsphere_creds
echo 'VSPHERE_SERVER=vcenter-cont.dominio.local' >> ~/.terraform_vsphere_creds
chmod 600 ~/.terraform_vsphere_creds
```

---

### 1.2 Crear Usuario para Ansible (vCenter SSO)

**🔹 En vCenter UI:**

```
1. Menú → Administration → Single Sign-On → Users and Groups
2. Domain: vsphere.local
3. Click "Add User"
   
   Username: svc-ansible
   Password: [Generar password seguro - mín 15 caracteres]
   Email: infraestructura@tudominio.com
   First Name: Ansible
   Last Name: Service Account
   Description: Service account for Ansible automation and configuration management
   
4. Click "Add"
```

---

## 2. ROLES PERSONALIZADOS

### 2.1 Crear Rol "IaC-Operator" para Terraform

**🔹 En vCenter UI:**

```
1. Menú → Administration → Access Control → Roles
2. Click botón "+" (Add Role)
3. Role name: IaC-Operator
4. Description: Minimum privilege role for Terraform infrastructure provisioning
```

**🔹 Seleccionar los siguientes privilegios (marcar checkbox):**

#### **A. Datastore**
```
✅ Datastore
   ✅ Allocate space
   ✅ Browse datastore
   ✅ Low level file operations
   ✅ Remove file
```

#### **B. Network**
```
✅ Network
   ✅ Assign network
```

#### **C. Resource**
```
✅ Resource
   ✅ Assign virtual machine to resource pool
   ✅ Migrate powered off virtual machine
   ✅ Migrate powered on virtual machine
```

#### **D. Virtual Machine → Configuration**
```
✅ Virtual machine
   ✅ Configuration
      ✅ Add existing disk
      ✅ Add new disk
      ✅ Add or remove device
      ✅ Advanced configuration
      ✅ Change CPU count
      ✅ Change Memory
      ✅ Change Settings
      ✅ Change resource
      ✅ Extend virtual disk
      ✅ Modify device settings
      ✅ Remove disk
      ✅ Rename
      ✅ Reset guest information
      ✅ Set annotation
      ✅ Settings
```

#### **E. Virtual Machine → Interaction**
```
✅ Virtual machine
   ✅ Interaction
      ✅ Configure CD media
      ✅ Power Off
      ✅ Power On
      ✅ Reset
      ✅ Suspend
```

#### **F. Virtual Machine → Inventory**
```
✅ Virtual machine
   ✅ Inventory
      ✅ Create from existing
      ✅ Create new
      ✅ Move
      ✅ Register
      ✅ Remove
      ✅ Unregister
```

#### **G. Virtual Machine → Provisioning**
```
✅ Virtual machine
   ✅ Provisioning
      ✅ Allow disk access
      ✅ Clone virtual machine
      ✅ Customize guest
      ✅ Deploy template
      ✅ Mark as template
      ✅ Modify customization specification
      ✅ Read customization specifications
```

#### **H. Virtual Machine → Snapshot Management**
```
✅ Virtual machine
   ✅ Snapshot management
      ✅ Create snapshot
      ✅ Remove snapshot
      ✅ Revert to snapshot
```

**5. Click "OK" para guardar el rol**

---

### 2.2 Crear Rol "IaC-ReadOnly-Plus" para Ansible

**🔹 En vCenter UI:**

```
1. Menú → Administration → Access Control → Roles
2. Click botón "+" (Add Role)
3. Role name: IaC-ReadOnly-Plus
4. Description: Read-Only with Guest Operations for Ansible automation
```

**🔹 Seleccionar los siguientes privilegios:**

```
✅ Virtual machine
   ✅ Guest Operations
      ✅ Guest operation modifications
      ✅ Guest operation queries
   ✅ Interaction
      ✅ Power Off
      ✅ Power On
      ✅ Reset
   ✅ Provisioning
      ✅ Read customization specifications

✅ Global
   ✅ Diagnostics (opcional para troubleshooting)
```

**5. Click "OK" para guardar el rol**

---

## 3. ASIGNACIÓN DE PERMISOS

### 3.1 Asignar permisos a svc-terraform

**🔹 Para el Datacenter de CONTINGENCIA:**

```
1. En vCenter UI, navegar a:
   Hosts and Clusters → DATACENTER CONTINGENCIA (raíz del datacenter)
   
2. Click derecho → Add Permission
   
3. En el diálogo:
   Domain: vsphere.local
   User/Group: Buscar y seleccionar "svc-terraform"
   
4. Assigned Role: IaC-Operator
   
5. ✅ IMPORTANTE: Marcar "Propagate to children"
   
6. Click "OK"
```

**🔹 Para el Datacenter de PRODUCCIÓN (después de validar en contingencia):**

```
Repetir los mismos pasos en:
   Hosts and Clusters → DATACENTER PRODUCCIÓN
```

---

### 3.2 Asignar permisos a svc-ansible

**🔹 Para ambos Datacenters:**

```
1. En vCenter UI, navegar a:
   Hosts and Clusters → [Datacenter]
   
2. Click derecho → Add Permission
   
3. En el diálogo:
   Domain: vsphere.local
   User/Group: Buscar y seleccionar "svc-ansible"
   
4. Assigned Role: IaC-ReadOnly-Plus
   
5. ✅ Marcar "Propagate to children"
   
6. Click "OK"
```

---

## 4. CONFIGURACIÓN DE RED/FIREWALL

### 4.1 Identificar IP del Jump Host (MV Control)

```
Ejemplo:
Jump Host IP: 192.168.10.50
vCenter Contingencia: 192.168.10.100
vCenter Producción: 192.168.20.100
```

---

### 4.2 Reglas de Firewall Requeridas

**🔹 Si tienen firewall centralizado (Fortigate, Palo Alto, etc.):**

Crear las siguientes reglas:

```
REGLA 1: Jump Host → vCenter Contingencia
  Source: 192.168.10.50
  Destination: 192.168.10.100
  Ports: TCP 443, TCP 902
  Service: HTTPS, VMware-SDK
  Action: PERMIT
  
REGLA 2: Jump Host → vCenter Producción
  Source: 192.168.10.50
  Destination: 192.168.20.100
  Ports: TCP 443, TCP 902
  Service: HTTPS, VMware-SDK
  Action: PERMIT

REGLA 3: Jump Host → Hosts ESXi (rangos)
  Source: 192.168.10.50
  Destination: [Rango IPs ESXi - ej: 192.168.10.0/24]
  Ports: TCP 443, TCP 902
  Service: HTTPS, VMware-SDK
  Action: PERMIT

REGLA 4: Jump Host → VMs Linux (Ansible SSH)
  Source: 192.168.10.50
  Destination: [Rango VMs o grupos específicos]
  Port: TCP 22
  Service: SSH
  Action: PERMIT

REGLA 5: Jump Host → VMs Windows (Ansible WinRM)
  Source: 192.168.10.50
  Destination: [Rango VMs Windows o grupos específicos]
  Ports: TCP 5985, TCP 5986
  Service: WinRM
  Action: PERMIT
```

---

### 4.3 Firewall en hosts ESXi (si aplica)

**🔹 Verificar que ESXi permite conexiones desde Jump Host:**

```bash
# Desde el Jump Host, validar conectividad:
curl -k https://esxi-host-ip:443
curl -k https://esxi-host-ip:902
```

**Si está bloqueado, modificar firewall ESXi:**

```bash
# Desde SSH en cada ESXi (o vía vCenter Host Profile):
esxcli network firewall ruleset set --ruleset-id httpClient --enabled true
esxcli network firewall ruleset set --ruleset-id vSphereClient --enabled true
esxcli network firewall refresh
```

---

## 5. VALIDACIÓN VMWARE TOOLS

VMware Tools debe estar actualizado para hot-add y operaciones de Ansible.

### 5.1 Verificar versión de VMware Tools en VMs

**🔹 En vCenter UI:**

```
1. VMs and Templates → Seleccionar una VM → Summary
2. Buscar "VMware Tools" en la sección VM Hardware
3. Estado ideal: "Running (Current)" o "Running (Out of date)" → actualizar
```

**🔹 Script PowerCLI para validar todas las VMs:**

```powershell
# Conectar a vCenter
Connect-VIServer -Server vcenter-cont.dominio.local

# Obtener VMs con VMware Tools desactualizadas
Get-VM | Select Name, @{N='Tools Status';E={$_.ExtensionData.Guest.ToolsStatus}},
               @{N='Tools Version';E={$_.ExtensionData.Guest.ToolsVersion}} | 
         Where-Object {$_.'Tools Status' -ne 'toolsOk'} | 
         Format-Table -AutoSize

# Guardar en CSV para análisis
Get-VM | Select Name, @{N='Tools Status';E={$_.ExtensionData.Guest.ToolsStatus}},
               @{N='Tools Version';E={$_.ExtensionData.Guest.ToolsVersion}} | 
         Export-Csv -Path "vm-tools-status.csv" -NoTypeInformation
```

---

### 5.2 Actualizar VMware Tools (si es necesario)

**🔹 Opción 1: Actualizar VMware Tools vía vCenter (recomendado):**

```
1. Click derecho en la VM → Guest OS → Install VMware Tools
2. O usar "Update VMware Tools" si ya está instalado
3. Seguir el asistente dentro del SO guest
```

**🔹 Opción 2: Actualizar masivamente con PowerCLI:**

```powershell
# Actualizar VMware Tools en todas las VMs de un cluster (requiere reinicio)
Get-Cluster "cluster-cont" | Get-VM | 
    Where-Object {$_.ExtensionData.Guest.ToolsStatus -ne 'toolsOk'} | 
    Update-Tools -NoReboot

# Nota: Para VMs críticas, coordinar reinicio en ventana de mantenimiento
```

---

## 6. CONFIGURACIÓN HOT-ADD

Para permitir escalado de CPU y RAM sin reiniciar la VM.

### 6.1 Habilitar CPU Hot-Add y Memory Hot-Add

**🔹 En vCenter UI (VM debe estar apagada para habilitar por primera vez):**

```
1. Click derecho en VM → Edit Settings
2. VM Options tab → Advanced → Configuration Parameters
3. Click "Edit Configuration..."
4. Agregar (si no existen):
   
   vcpu.hotadd = TRUE
   mem.hotadd = TRUE
   
5. Click "OK" → "OK"
6. Encender la VM
```

**🔹 Script PowerCLI para habilitar masivamente:**

```powershell
# Define VMs de contingencia (ajustar filtro según sea necesario)
$vms = Get-Cluster "cluster-cont" | Get-VM

foreach ($vm in $vms) {
    # Apagar VM si está encendida (COORDINAR CON EQUIPOS)
    if ($vm.PowerState -eq "PoweredOn") {
        Write-Host "⚠️  VM $($vm.Name) está encendida - SALTADA (requiere shutdown)" -ForegroundColor Yellow
        continue
    }
    
    # Configurar hot-add
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    
    $vmConfigSpec.CpuHotAddEnabled = $true
    $vmConfigSpec.MemoryHotAddEnabled = $true
    
    $vm.ExtensionData.ReconfigVM($vmConfigSpec)
    
    Write-Host "✅ Hot-Add habilitado en: $($vm.Name)" -ForegroundColor Green
}
```

**⚠️ IMPORTANTE:**
- VMs Linux modernas (kernel 3.x+) soportan hot-add sin problemas
- VMs Windows necesitan VMware Tools instalado y actualizado
- **VMs de bases de datos críticas:** Evaluar impacto con DBAs antes de hacer cambios

---

### 6.2 Validar Hot-Add configurado

**🔹 Script de validación:**

```powershell
Get-VM | Select Name,
    @{N='CPU Hot-Add';E={$_.ExtensionData.Config.CpuHotAddEnabled}},
    @{N='Memory Hot-Add';E={$_.ExtensionData.Config.MemoryHotAddEnabled}} | 
    Format-Table -AutoSize
```

---

## 7. VALIDACIÓN FINAL

### 7.1 Checklist de Configuración VMware

```
✅ Usuarios de servicio:
   ☐ svc-terraform@vsphere.local creado
   ☐ svc-ansible@vsphere.local creado

✅ Roles personalizados:
   ☐ IaC-Operator creado con permisos correctos
   ☐ IaC-ReadOnly-Plus creado con permisos correctos

✅ Permisos asignados:
   ☐ svc-terraform → IaC-Operator en Datacenter Contingencia (propagate)
   ☐ svc-ansible → IaC-ReadOnly-Plus en Datacenter Contingencia (propagate)

✅ Red y conectividad:
   ☐ Firewall permite Jump Host → vCenter (443, 902)
   ☐ Firewall permite Jump Host → ESXi (443, 902)
   ☐ Firewall permite Jump Host → VMs (22, 5985, 5986)

✅ VMware Tools:
   ☐ Inventario de VMs con estado de Tools completado
   ☐ VMs críticas con Tools actualizadas

✅ Hot-Add:
   ☐ CPU Hot-Add habilitado en VMs objetivo
   ☐ Memory Hot-Add habilitado en VMs objetivo

✅ Documentación:
   ☐ Credenciales guardadas en gestor seguro (Vault/1Password/Azure KeyVault)
   ☐ Diagrama de red actualizado con IPs Jump Host y vCenters
```

---

### 7.2 Prueba de Conectividad desde Jump Host

**🔹 Script de validación de acceso API:**

```bash
#!/bin/bash
# test-vcenter-connectivity.sh

VCENTER_CONT="vcenter-cont.dominio.local"
VCENTER_PROD="vcenter-prod.dominio.local"

echo "🔍 Validando conectividad a vCenter Contingencia..."
curl -k -I https://$VCENTER_CONT/ui/ 2>/dev/null | head -n 1

echo "🔍 Validando API vCenter..."
curl -k -X POST https://$VCENTER_CONT/rest/com/vmware/cis/session \
  -u "svc-terraform@vsphere.local:PASSWORD_AQUI" 2>/dev/null | jq .

echo "✅ Si ves un token, la conexión es exitosa"
```

**🔹 Validación con Python + pyVmomi:**

```python
#!/usr/bin/env python3
# test-vsphere-login.py

from pyVim.connect import SmartConnect
import ssl

vcenter = "vcenter-cont.dominio.local"
username = "svc-terraform@vsphere.local"
password = "TU_PASSWORD"

context = ssl._create_unverified_context()

try:
    si = SmartConnect(host=vcenter, user=username, pwd=password, sslContext=context)
    print(f"✅ Conectado exitosamente a {vcenter}")
    print(f"   vCenter Version: {si.content.about.version}")
    print(f"   API Type: {si.content.about.apiType}")
except Exception as e:
    print(f"❌ Error de conexión: {e}")
```

---

### 7.3 Validación con Terraform

**🔹 Crear archivo `test-connection.tf` en Jump Host:**

```hcl
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.6"
    }
  }
}

provider "vsphere" {
  user                 = "svc-terraform@vsphere.local"
  password             = "TU_PASSWORD"  # Mejor usar variable de entorno
  vsphere_server       = "vcenter-cont.dominio.local"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "DATACENTER CONTINGENCIA"
}

output "datacenter_id" {
  value = data.vsphere_datacenter.dc.id
}
```

**Ejecutar:**

```bash
terraform init
terraform plan

# Si funciona, verás:
# Plan: 0 to add, 0 to change, 0 to destroy.
# Changes to Outputs:
#   + datacenter_id = "datacenter-XXX"
```

---

### 7.4 Validación con Ansible

**🔹 Crear inventario de prueba `test-inventory.yml`:**

```yaml
plugin: community.vmware.vmware_vm_inventory
strict: False
hostname: vcenter-cont.dominio.local
username: svc-ansible@vsphere.local
password: TU_PASSWORD
validate_certs: False
with_tags: False
```

**Ejecutar:**

```bash
# Instalar collection
ansible-galaxy collection install community.vmware

# Probar inventario dinámico
ansible-inventory -i test-inventory.yml --graph

# Deberías ver:
# @all:
#   |--@ungrouped:
#   |--@<cluster-name>:
#   |  |--vm-name-1
#   |  |--vm-name-2
```

---

##  SIGUIENTE PASO

Una vez completada esta guía, proceder con:
- **Fase 0, Tarea 0.8:** Instalar toolchain en Jump Host (Terraform, Ansible, Python)
- **Fase 1, Tarea 1.1:** Configurar Terraform backend para state remoto

---

## 📚 REFERENCIAS

- [VMware vSphere Terraform Provider](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs)
- [Ansible VMware Collection](https://docs.ansible.com/ansible/latest/collections/community/vmware/index.html)
- [vSphere API Reference](https://developer.vmware.com/apis/vsphere-automation/latest/)
- [VMware Tools Documentation](https://docs.vmware.com/en/VMware-Tools/index.html)
