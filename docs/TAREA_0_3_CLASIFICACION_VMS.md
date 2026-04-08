# Tarea 0.3 – Clasificación de VMs Datacenter Contingencia

**Fecha:** 2026-03-13  
**Fuente:** `inventario_datacenter_contingencia.csv` (27 VMs, excluyendo VMs de sistema vCLS/VCSAC/SG_v*)  
**Responsable:** Alex Ballesteros

---

## Resumen

| Categoría | Cantidad | Criterio |
|-----------|----------|---------|
| 🔴 Crítica | 11 | Servicios bancarios core, bases de datos transaccionales, seguridad |
| 🟡 Infraestructura | 10 | Plataforma vSphere, Hivecloud, servicios de gestión |
| 🟠 Aplicaciones | 6 | Proxies, servicios de contingencia, aplicaciones de negocio |
| ⚫ Excluidas (sistema) | 5+ | vCLS, VCSAC, SG_v*, VROPS — gestionadas por VMware/Hivecloud |

---

## 1. VMs Críticas — Servicios bancarios core

> Criterio: impacto directo en operaciones bancarias, transacciones o acceso privilegiado. Requieren `prevent_destroy = true` en Terraform.

| VM | OS | IP | Estado | Servicio inferido |
|----|----|-----|--------|-------------------|
| `ADC` | Windows | 192.168.144.135 | poweredOn | Active Directory Controller |
| `ADCONNETC` | Windows | 192.168.196.163 | poweredOn | AD Connector |
| `POSTIBDREALPREP` | Windows | 192.168.144.26 | poweredOn | PostiLion BD Real (transacciones) |
| `POSTIBDOFFPREP` | Windows | 192.168.144.27 | poweredOn | PostiLion BD Offline |
| `POSTIBDNIXPREP` | Windows | 192.168.144.28 | poweredOn | PostiLion BD Nix |
| `POSTIAPPREP` | Windows | 192.168.144.29 | poweredOn | PostiLion Application |
| `FRC` | Windows | 192.168.196.21 | poweredOn | Front/Reconciliación |
| `PSMC` | Windows | 192.168.196.17 | poweredOn | PSM – Gestión de sesiones privilegiadas |
| `PVWAC` | Windows | 192.168.196.18 | poweredOn | PAM / Acceso privilegiado (CyberArk) |
| `VAULTC` | Windows | 192.168.196.145 | poweredOn | Vault – Gestión de credenciales |
| `MGORACLEC` | Linux | 192.168.194.34 | poweredOn | Oracle DB Management |

---

## 2. VMs de Infraestructura — Plataforma vSphere / Hivecloud

> Criterio: componentes de la plataforma de virtualización o microsegmentación. **No gestionar con Terraform** — administradas por sus propias herramientas.

| VM | OS | IP | Estado | Servicio |
|----|----|-----|--------|---------|
| `VCSAC` | Linux | 192.168.77.152 | poweredOn | vCenter Server |
| `VROPSPREP` | Linux | 192.168.77.108 | poweredOn | vRealize Operations Manager |
| `vSOMC` | Linux | 192.168.77.190 | poweredOn | vSphere Operations Manager |
| `SG_vDSM_0_21` | Linux | 192.168.160.37 | poweredOn | Hivecloud – Distributed Security Manager |
| `SG_vSCM_0_1` | Linux | 192.168.160.33 | poweredOn | Hivecloud – Security Controller 1 |
| `SG_vSCM_0_2` | Linux | 192.168.160.34 | poweredOn | Hivecloud – Security Controller 2 |
| `SG_vSSM_0_17` | Linux | 192.168.160.35 | poweredOn | Hivecloud – Security Service Manager 1 |
| `SG_vSSM_0_19` | Linux | 192.168.160.36 | poweredOn | Hivecloud – Security Service Manager 2 |
| `EX3` | Windows | 192.168.193.23 | poweredOn | Exchange – Correo interno |
| `LT` | Linux | 192.168.238.1 | poweredOn | Load Tester / Herramientas |

---

## 3. VMs de Aplicaciones — Servicios de contingencia

> Criterio: proxies, balanceadores y aplicaciones de negocio secundarias.

| VM | OS | IP | Estado | Servicio |
|----|----|-----|--------|---------|
| `NGINXPRXLIBPRD2PREP` | Linux | 10.10.10.113 | poweredOn | NGINX Proxy – Librería |
| `NGINXATALLAPREP` | Linux | — | poweredOff | NGINX Atalla (HSM Proxy) – apagada |
| `NGIPRUP01MRPREP` | Linux | 192.168.144.41 | poweredOn | NGINX Proxy – Rupay 01 |
| `NGIPRUP02MRPREP` | Linux | 192.168.144.42 | poweredOn | NGINX Proxy – Rupay 02 |
| `AWPC` | Windows | 192.168.195.16 | poweredOn | AWP – Application |
| `SAAC` | Windows | 192.168.195.6 | poweredOn | SAA – Sistema |
| `SAGSNLC` | Windows | 192.168.195.9 | poweredOn | SAGS NL |

---

## 4. VMs excluidas de gestión IaC

> Estas VMs fueron identificadas en el inventario pero **excluidas del tfvars** ya que son componentes de sistema gestionados por VMware o Hivecloud directamente.

| VM | Motivo exclusión |
|----|-----------------|
| `vCLS-*` (múltiples) | vSphere Cluster Services — gestionado automáticamente por vCenter |
| `VCSAC` | vCenter mismo — no se gestiona con Terraform |
| `SG_v*` | Nodos Hivecloud — gestionados por consola Hivecloud |

---

## 5. Impacto en configuración Terraform

| Categoría | Configuración recomendada |
|-----------|--------------------------|
| Crítica | `prevent_destroy = true`, snapshot antes de cambios |
| Infraestructura | Excluidas del tfvars — solo lectura via data sources |
| Aplicaciones | Gestionables con Terraform, sin `prevent_destroy` |

---

## 6. Próximos pasos (Tarea 0.4)

- Definir tags en vCenter: `env:contingencia`, `criticidad:alta/media/baja`, `gestionado:terraform`
- Asignar Resource Pools según categoría
- Actualizar tfvars con los tags formalizados
