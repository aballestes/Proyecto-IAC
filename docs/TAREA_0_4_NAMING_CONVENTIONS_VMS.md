# Tarea 0.4 – Naming Conventions y Organización de VMs

**Fecha:** 2026-03-13  
**Fuente:** `inventario_datacenter_contingencia.csv` — 27 VMs datacenter contingencia  
**Responsable:** Alex Ballesteros

---

## 1. Naming Conventions Actuales (AS-IS)

### 1.1. Patrones de nombres observados

Análisis del inventario real del datacenter de contingencia:

| Patrón | Ejemplos | Significado inferido |
|--------|---------|---------------------|
| `NGINX*` | `NGINXPRXLIBPRD2PREP`, `NGINXATALLAPREP` | NGINX + función + ambiente |
| `NGIPRUP*` | `NGIPRUP01MRPREP`, `NGIPRUP02MRPREP` | NGI + Proxy + Rupay + secuencia |
| `POSTIBD*` | `POSTIBDREALPREP`, `POSTIBDOFFPREP`, `POSTIBDNIXPREP` | PostiLion + BD + tipo |
| `POSTIAPP*` | `POSTIAPPREP` | PostiLion + App |
| `SG_v*` | `SG_vDSM_0_21`, `SG_vSCM_0_1` | Hivecloud Security Group + tipo + secuencia |
| `*C` (sufijo C) | `ADC`, `ADCONNETC`, `VAULTC`, `PSMC`, `PVWAC`, `VCSAC` | Sufijo `C` = **ubicación física en datacenter de contingencia** — no indica ambiente (producción/desarrollo/pruebas) |
| `*PREP` (sufijo) | `NGINXATALLAPREP`, `VROPSPREP`, `POSTIBDREALPREP`, `NGIPRUP01MRPREP`... | `PREP` = servidor **en despliegue** — estado transitorio: el ambiente final (producción, desarrollo, pruebas o contingencia) **aún no fue definido** |
| `*MRP` | `NGIPRUP01MRPREP` | `MR` = posiblemente "Maestro Rupay" |

### 1.2. Problemas detectados

- **Sufijo `C` indica datacenter, no ambiente** — el sufijo `C` al final del nombre identifica la **ubicación física** (datacenter de contingencia), no el ambiente de la aplicación (producción, desarrollo, pruebas o contingencia).
- **Sufijo `PREP` indica despliegue sin ambiente definido** — el servidor está en proceso de despliegue y su ambiente final (producción, desarrollo, pruebas o contingencia) aún no fue asignado; no debe consolidarse como parte del nombre definitivo.
- **Abreviaciones no documentadas** — `MR`, `SVB`, `NEG`, `INFO` en portgroups no tienen diccionario oficial.
- **Sin separador estándar** — algunos nombres usan `_` (`SG_vDSM_0_21`), otros no usan separador (`POSTIBDREALPREP`).
- **Longitudes inconsistentes** — desde 3 caracteres (`ADC`, `LT`) hasta 20+ (`NGINXPRXLIBPRD2PREP`).
- **Secuencias no normalizadas** — `01`, `1`, `_0_21` mezclados.

---

## 2. Propuesta de Naming Convention (TO-BE)

> **Nota:** Las VMs existentes **no se renombran** — el renombrado rompe referencias en vCenter, AD y monitoreo. Esta convención aplica **solo a VMs nuevas** creadas con Terraform.

### 2.1. Formato estándar para VMs nuevas

```text
<AMB><APP><ROL><SEQ>
```

| Campo | Valores | Max chars |
|-------|---------|----------|
| `AMB` | `CONT` (contingencia), `PRD` (producción) | 4 |
| `APP` | Código de aplicación: `NGINX`, `POSTI`, `AD`, `VAULT`, `EX` | 4-6 |
| `ROL` | `APP`, `DB`, `PRX`, `WEB`, `MGR` | 3 |
| `SEQ` | `01`, `02`… | 2 |

**Ejemplos:**
```
CONTNGINXPRX01   ← Contingencia, NGINX, Proxy, 01
CONTPOSTIDB01    ← Contingencia, PostiLion, DB, 01
PRDNGINXPRX01    ← Producción, NGINX, Proxy, 01
```

### 2.2. Reglas

- Solo mayúsculas, sin separadores para mantener compatibilidad con nombres actuales
- Longitud máxima: **20 caracteres**
- VMs de infraestructura (vCenter, Hivecloud) conservan su nombre de sistema (`VCSAC`, `SG_v*`)
- **Omitir el sufijo `PREP`** en todos los nombres nuevos — indica estado de despliegue temporal y no debe formar parte del nombre definitivo de la VM

---

## 3. Carpetas (Folders) y Resource Pools

### 3.1. Estructura actual de carpetas — Contingencia

| Folder observado | VMs | Uso |
|-----------------|-----|-----|
| `POOL` | Mayoría de VMs | Pool general — sin clasificación |
| `POSTILIONDES` | `POSTIAP*`, `POSTIBD*` | Grupo PostiLion |
| `REPLIC` | `NGINXPRXLIBPRD2PREP` | Replicación |
| `EXC` | `EX3` | Exchange |
| `VCENTERC8` | `VCSAC`, `VROPSPREP` | Infraestructura vCenter |
| `esx7appc` | `SG_vSSM_0_19` | ESXi App cluster |

**Problema principal:** La mayoría de VMs están en `POOL` sin clasificación por criticidad o aplicación.

### 3.2. Propuesta de estructura de carpetas TO-BE

```
Datacenter-Contingencia/
├── CRITICA/          ← VMs core bancarias (PostiLion, AD, Vault)
├── APLICACIONES/     ← Proxies NGINX, AWP, SAGS
├── INFRAESTRUCTURA/  ← vCenter, vROPS, Hivecloud (no gestionar con Terraform)
└── SISTEMA/          ← vCLS, reserved
```

### 3.3. Resource Pools actuales

| Resource Pool | ID (tfstate) | VMs asignadas |
|--------------|-------------|--------------|
| `AppIBM` | resgroup-8542 | Todas las VMs del tfvars |

---

## 4. Tags y Anotaciones

### 4.1. Tags actuales en vCenter (AS-IS)

**Estado confirmado:** Las VMs existentes en el datacenter de contingencia **no tienen ningún tag de vCenter asignado**. La columna `annotation` del inventario está vacía en la mayoría de las VMs. No existían categorías de tags creadas en vCenter antes de la implementación IaC.

### 4.2. Notas / Annotations reales encontradas

Análisis completo del campo `annotation` del inventario `inventario_datacenter_contingencia.csv`:

| VM | Annotation encontrada | Tipo |
|----|----------------------|------|
| `VCSAC` | `VMware vCenter Server Appliance` | Descriptiva — sistema |
| `VROPSPREP` | `VMware Aria Operations — Versión 8.18.3 ejecutándose en Photon OS 5.0` | Descriptiva — sistema |
| `POSTIBDNIXPREP` | Metadata CloudHive: FW-vlanid-3702, UserNet: `App_Contingencia_SVB_21` | Técnica — microsegmentación |
| `POSTIAPPREP` | Metadata CloudHive: FW-vlanid-3700, UserNet: `App_Contingencia_SVB_21` | Técnica — microsegmentación |
| `SG_vDSM_0_21` | `This asset is created and managed by Hillstone Security Service. Please do not make any manual change.` | Gestión automática |
| `SG_vSSM_0_17` | `This asset is created and managed by Hillstone Security Service. Please do not make any manual change.` | Gestión automática |
| `SG_vSSM_0_19` | `This asset is created and managed by Hillstone Security Service. Please do not make any manual change.` | Gestión automática |
| `SG_vSCM_0_1` | `This asset is created and managed by Hillstone Security Service. Please do not make any manual change.` | Gestión automática |
| `SG_vSCM_0_2` | `This asset is created and managed by Hillstone Security Service. Please do not make any manual change.` | Gestión automática |
| 19 VMs restantes | *(vacío)* | Sin documentar |

**Conclusiones:**
- Las VMs `SG_v*` son gestionadas exclusivamente por Hivecloud (Hillstone) — **no se deben modificar con Terraform ni alterar su annotation**.
- La metadata CloudHive en `POSTIBDNIXPREP` y `POSTIAPPREP` indica microsegmentación activa en VLAN `App_Contingencia_SVB_21`.
- No existe información de dueño (`Owner`) ni contacto en ninguna VM — **gap de documentación pendiente**.

### 4.3. Tags implementados con Terraform (TO-BE — vigentes desde Fase 1)

Los siguientes recursos fueron creados en vCenter mediante `terraform apply` en la tarea 1.2:

**Categoría `Ambiente`** (cardinalidad: SINGLE — un tag por VM)

| Tag | Descripción | Recurso Terraform |
|-----|-------------|-------------------|
| `contingencia` | VM pertenece al datacenter de contingencia | `vsphere_tag.tag_contingencia` |
| `critico` | Servicio crítico — requiere aprobación para cambios | `vsphere_tag.tag_critico` |
| `devtest` | VM de desarrollo o pruebas | `vsphere_tag.tag_devtest` |

### 4.4. Clasificación de VMs por criticidad (datacenter contingencia)

| VM | Servicio | Criticidad | Tag aplicado | Justificación |
|----|---------|------------|-------------|---------------|
| `ADC` | Active Directory DC | CRÍTICA | `critico` | Autenticación corporativa |
| `ADCONNETC` | AD Connector | CRÍTICA | `critico` | Dependencia de AD |
| `VAULTC` | Vault / CyberArk | CRÍTICA | `critico` | Gestión de credenciales |
| `POSTIBDREALPREP` | PostiLion BD Real-time | CRÍTICA | `critico` | Procesamiento transaccional bancario |
| `POSTIBDOFFPREP` | PostiLion BD Offline | CRÍTICA | `critico` | Procesamiento transaccional bancario |
| `POSTIBDNIXPREP` | PostiLion BD Nix | CRÍTICA | `critico` | Procesamiento transaccional bancario |
| `POSTIAPPREP` | PostiLion App | CRÍTICA | `critico` | Aplicación transaccional bancaria |
| `EX3` | Exchange Server 2012 | CRÍTICA | `critico` | Correo corporativo (12 CPU / 40 GB RAM) |
| `NGINXPRXLIBPRD2PREP` | NGINX Proxy Libreta | ALTA | `contingencia` | Proxy productivo activo (datastore REPLIC) |
| `NGIPRUP01MRPREP` | NGI Proxy Rupay 01 | ALTA | `contingencia` | Proxy transacciones Rupay |
| `NGIPRUP02MRPREP` | NGI Proxy Rupay 02 | ALTA | `contingencia` | Proxy transacciones Rupay |
| `AWPC` | AWP App | ALTA | `contingencia` | Aplicación web producción |
| `SAAC` | SAA App | ALTA | `contingencia` | Aplicación producción |
| `SAGSNLC` | SAGS NL | ALTA | `contingencia` | Aplicación corporativa |
| `PVWAC` | CyberArk PVWA | ALTA | `contingencia` | Acceso privilegiado |
| `PSMC` | CyberArk PSM | ALTA | `contingencia` | Sesión privilegiada |
| `FRC` | FR App | MEDIA | `contingencia` | Aplicación funcional |
| `LT` | LT (legacy 32-bit) | MEDIA | `contingencia` | SO legacy — VMware Tools desactualizadas |
| `MGORACLEC` | MG Oracle | MEDIA | `contingencia` | Base de datos Oracle |
| `vSOMC` | vSOM Monitoreo | MEDIA | `contingencia` | Monitoreo Ubuntu |
| `NGINXATALLAPREP` | NGINX Atalla | BAJA | `contingencia` | **Apagada** — stand-by intencional documentado |
| `VCSAC` | vCenter Appliance | INFRAESTRUCTURA | *(sin tag IaC)* | No gestionar con Terraform |
| `VROPSPREP` | VMware Aria Operations | INFRAESTRUCTURA | *(sin tag IaC)* | No gestionar con Terraform |
| `SG_vDSM_0_21` | Hivecloud DSM | INFRAESTRUCTURA | *(sin tag IaC)* | Gestionado por Hillstone |
| `SG_vSSM_0_17` | Hivecloud SSM | INFRAESTRUCTURA | *(sin tag IaC)* | Gestionado por Hillstone |
| `SG_vSSM_0_19` | Hivecloud SSM | INFRAESTRUCTURA | *(sin tag IaC)* | Gestionado por Hillstone |
| `SG_vSCM_0_1` | Hivecloud SCM | INFRAESTRUCTURA | *(sin tag IaC)* | Gestionado por Hillstone |
| `SG_vSCM_0_2` | Hivecloud SCM | INFRAESTRUCTURA | *(sin tag IaC)* | Gestionado por Hillstone |

### 4.5. Tags pendientes para Fase 2

| Tag propuesto | Categoría | Cardinalidad | Estado | Bloqueante |
|--------------|-----------|-------------|--------|-----------|
| `SistemaOperativo` | SistemaOperativo | SINGLE | ✅ Implementado en `main.tf` | Sin bloqueante — datos en inventario |
| `Aplicacion` | Aplicacion | SINGLE | ❌ Pendiente | Diccionario oficial pendiente de aprobación por Arquitectura |
| `Owner` | Owner | SINGLE | ❌ Pendiente | Definición organizacional — requiere workshop con líderes de área |

**Detalle tag `SistemaOperativo`** — valores tomados de columna `guest_full` del inventario:

| guest_id | Tag (guest_full) |
|----------|------------------|
| `sles15_64Guest` | `SUSE Linux Enterprise 15 (64-bit)` |
| `windows2019srvNext_64Guest` | `Microsoft Windows Server 2022 (64-bit)` |
| `windows9Server64Guest` | `Microsoft Windows Server 2016 (64-bit)` |
| `windows8Server64Guest` | `Microsoft Windows Server 2012 (64-bit)` |
| `oracleLinux7_64Guest` | `Oracle Linux 7 (64-bit)` |
| `ubuntu64Guest` | `Ubuntu Linux (64-bit)` |
| `other26xLinux64Guest` | `Other 2.6.x Linux (64-bit)` |
| `other3xLinux64Guest` | `Other 3.x or later Linux (64-bit)` |
| `otherGuest` | `Other (32-bit)` |

El tag se aplica **automáticamente** en el módulo `vms_contingencia` usando `compact(concat(...))` sobre el `guest_id` de cada VM — no requiere modificar el `.tfvars.hcl` por VM.

---

## 5. Gaps y Recomendaciones

| Gap | Riesgo | Acción recomendada |
|-----|--------|-------------------|
| Nombres no estandarizados en VMs existentes | Difícil identificar rol/ambiente en incidentes | Aplicar naming solo a VMs nuevas |
| Todas las VMs en folder `POOL` | Sin priorización en incidentes | Crear folders por criticidad en Fase 1 |
| Sin tags en ninguna VM | Reportes y filtros imposibles | Aplicar tags via Terraform en primer `apply` |
| `NGINXATALLAPREP` apagada sin documentar | Riesgo de eliminarla por error | Documentar stand-by intencional |

---

## 6. Aprobaciones / Decisiones

| Campo | Valor |
|-------|-------|
| Fecha elaboración | 2026-03-13 |
| Elaborado por | Alex Ballesteros |
| Pendiente aprobación | Infraestructura, Seguridad Informática |
| Aplica a | Datacenter Contingencia (fase inicial) |
| Próxima revisión | Antes de terraform apply en producción |
