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
| `*C` (sufijo C) | `ADC`, `ADCONNETC`, `VAULTC`, `PSMC`, `PVWAC`, `VCSAC` | Sufijo `C` = Contingencia |
| `*PREP` (sufijo) | `NGINXATALLAPREP`, `VROPSPREP` | `PREP` = entorno de preparación/contingencia |
| `*MRP` | `NGIPRUP01MRPREP` | `MR` = posiblemente "Maestro Rupay" |

### 1.2. Problemas detectados

- **Sin prefijo de ambiente consistente** — el ambiente (contingencia/producción) se indica con sufijos (`C`, `PREP`) o no se indica.
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

### 4.1. Tags actuales

- ¿Se usan tags oficiales en vCenter? (`Owner`, `Criticidad`, `Aplicación`, etc.).
- Lista de categorías y ejemplos de tags:
  - Categoría `Aplicacion`: `CELTA`, `COREBANK`, `SWIFT`, etc.
  - Categoría `Criticidad`: `CRITICA`, `ALTA`, `MEDIA`, `BAJA`.

### 4.2. Notas / Annotations

Revisar la columna de `Notes` en el inventario (cuando exista):

- Información útil encontrada (dueño, contacto, ticket, etc.).
- Información “basura” o técnica que se podría mover a otro lado.

### 4.3. Propuesta de estándar de tags

Definir qué tags deberían ser obligatorios para cada VM nueva:

- `Aplicacion` (obligatorio)
- `Ambiente` (`PRD`, `PRE`, `DEV`, `QA`, `LAB`, `CONT`)
- `Criticidad` (`CRITICA`, `ALTA`, `MEDIA`, `BAJA`)
- `Owner` (equipo o área responsable)

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
