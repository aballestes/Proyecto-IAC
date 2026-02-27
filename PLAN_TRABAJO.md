# PLAN DE TRABAJO — INFRAESTRUCTURA COMO CÓDIGO (IaC)
## VMware vSphere + Terraform + Ansible
**Fecha de inicio:** Febrero 2026  
**Clasificación:** TÉCNICO — CONFIDENCIAL INTERNO

---

## 1. RESUMEN EJECUTIVO

Implementar una capa de **Infraestructura como Código (IaC)** sobre dos datacenters VMware vSphere 8 existentes, usando **Terraform** como herramienta de aprovisionamiento declarativo y **Ansible** como herramienta de configuración y automatización operacional. La implementación se realiza primero en contingencia y luego en producción.

**Duración total del proyecto:** 12 semanas  
**Enfoque:** Implementación incremental por fases con validación continua

---

## 2. PLAN DE TRABAJO POR FASES

### FASE 0 — PREPARACIÓN Y DESCUBRIMIENTO (Semanas 1-2)
**Duración estimada:** 10 días hábiles  
**Prioridad:** CRÍTICA

#### Tareas:
| # | Tarea | Responsable | Días | Dependencia |
|---|---|---|---|---|
| 0.1 | Acceso a ambos vCenter 8 (API / UI) con credenciales de solo lectura inicial | Admin vSphere | 1 | — |
| 0.2 | Ejecutar script de inventario automático de VMs (Python/PowerCLI) | IaC Engineer | 1 | 0.1 |
| 0.3 | Clasificar VMs: críticas / desarrollo / pruebas / contingencia | Arquitecto | 2 | 0.2 |
| 0.4 | Documentar naming conventions, tags, folders, resource pools existentes | IaC Engineer | 1.5 | 0.1 |
| 0.5 | Validar conectividad red hacia todas las VMs (ping, SSH/WinRM) | Ops | 1 | 0.1 | 0.6 | Verificar puertos: vCenter API 443, ESXi 902, SSH 22, WinRM 5985/5986 | Ops | 1 | 0.1 |
| 0.7 | Configurar MV de control IaC (bastión/jump host) con acceso a ambos DCs | Ops | 1.5 | 0.5 |
| 0.8 | Instalar toolchain en MV de control: Terraform, Ansible, Python, Git | IaC Engineer | 1 | 0.7 |
| 0.9 | Configurar repositorio Git con estructura de proyecto y branching strategy | IaC Engineer | 0.5 | — |
| 0.10 | Validar Hivecloud: confirmar que IaC no rompe enmascaramiento VLAN | Seguridad + Ops | 1.5 | 0.5 |

#### Entregables Fase 0:
- [ ] Inventario completo VMs (CSV/YAML) ambos datacenters
- [ ] Diagrama de red actualizado con VLANs y datastores
- [ ] MV control plane operativa con toolchain instalado
- [ ] Repositorio Git inicializado con estructura IaC

---

### FASE 1 — IMPLEMENTACIÓN IaC en CONTINGENCIA (Semanas 3-5)
**Duración estimada:** 15 días hábiles  
**Prioridad:** ALTA — Validar sin riesgo para producción

#### Tareas:
| # | Tarea | Responsable | Días | Riesgo |
|---|---|---|---|---|
| 1.1 | Configurar Terraform backend (state file remoto: S3/MinIO/NFS) | IaC Engineer | 1 | BAJO |
| 1.2 | Terraform: importar recursos existentes contingencia (terraform import) | IaC Engineer | 4 | MEDIO |
| 1.3 | Terraform: crear módulo `vsphere-vm` parametrizable (CPU/MEM/DISK) | IaC Engineer | 2.5 | BAJO |
| 1.4 | Terraform: crear módulo `vsphere-cluster-compute` | IaC Engineer | 1.5 | BAJO |
| 1.5 | Ansible: inventario dinámico vSphere (plugin `community.vmware`) | IaC Engineer | 1.5 | BAJO |
| 1.6 | Ansible: playbook `vm-health-check.yml` (ping, recursos, servicios) | IaC Engineer | 1 | BAJO |
| 1.7 | Ansible: role `vm-scale-resources` (CPU hot-add, RAM hot-add, disk) | IaC Engineer | 2.5 | MEDIO |
| 1.8 | Testing completo en contingencia: escalar 5-8 VMs piloto | IaC Engineer + Ops | 2 | BAJO |

#### Entregables Fase 1:
- [ ] Estado Terraform de contingencia capturado y versionado
- [ ] 30 VMs contingencia gestionadas por Terraform (importadas)
- [ ] Playbook de escalado de recursos funcional y validado
- [ ] Inventario dinámico Ansible operativo

---

### FASE 2 — IMPLEMENTACIÓN IaC en PRODUCCIÓN (Semanas 6-9)
**Duración estimada:** 20 días hábiles  
**Prioridad:** ALTA — Ejecutar con ventanas de mantenimiento

#### Tareas:
| # | Tarea | Responsable | Días | Riesgo |
|---|---|---|---|---|
| 2.1 | Terraform: importar recursos producción cluster-app (270 VMs aprox) | IaC Engineer | 6 | ALTO — ventana |
| 2.2 | Terraform: importar recursos producción cluster-db (30 VMs críticas) | IaC Engineer | 4 | ALTO — ventana |
| 2.3 | Ansible: inventario dinámico producción separado por grupos (crítico/dev/test) | IaC Engineer | 2 | BAJO |
| 2.4 | Ansible: playbooks diferenciados por tipo de VM (Linux/Windows) | IaC Engineer | 2 | BAJO |
| 2.5 | Implementar pipeline CI/CD (GitLab/GitHub Actions) plan/apply con aprobación | DevOps | 3 | MEDIO |
| 2.6 | Runbooks de escalado para equipo de operaciones | IaC Engineer | 1 | BAJO |
| 2.7 | Capacitación del equipo de operaciones en uso de playbooks | IaC Lead | 2 | BAJO |

#### Entregables Fase 2:
- [ ] 300 VMs producción gestionadas por Terraform
- [ ] Pipeline CI/CD operativo con gates de aprobación
- [ ] Runbooks documentados para operaciones diarias
- [ ] Equipo capacitado en uso de herramientas IaC

---

### FASE 3 — AUTOMATIZACIÓN AVANZADA Y TKG (Semanas 10-12)
**Duración estimada:** 15 días hábiles  
**Prioridad:** MEDIA

#### Tareas:
| # | Tarea | Responsable | Días |
|---|---|---|---|
| 3.1 | Despliegue TKG Supervisor Cluster en producción (vSphere Foundation) | K8s Architect | 5 |
| 3.2 | Namespace Kubernetes para cargas de trabajo dev/test | K8s Architect | 2 |
| 3.3 | Ansible: playbooks de monitoreo y alertas (integración Zabbix/Prometheus) | IaC Engineer | 3 |
| 3.4 | Automatización de snapshots y backups pre-escala | IaC Engineer | 2 |
| 3.5 | Documentación final completa del proyecto | IaC Engineer | 2 |
| 3.6 | Capacitación avanzada y transferencia de conocimiento | IaC Lead | 1 |

---

## 3. CRONOGRAMA RESUMEN (GANTT)

```
          S1  S2  S3  S4  S5  S6  S7  S8  S9  S10 S11 S12
FASE 0:  [=======]
FASE 1:          [===============]
FASE 2:                          [====================]
FASE 3:                                              [===============]
```

**Hitos principales:**
- **Semana 2:** Infraestructura de control lista
- **Semana 5:** Contingencia bajo IaC
- **Semana 9:** Producción bajo IaC
- **Semana 12:** Proyecto completo + TKG operativo

---

## 4. ARQUITECTURA DE REFERENCIA

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATACENTER PRODUCCIÓN                        │
│  vCenter 8 (vcenter-prod.dominio.local)                         │
│                                                                  │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐  │
│  │    CLUSTER APP (5 ESXi) │  │  CLUSTER DB (2 ESXi)         │  │
│  │  ESXi 8 Update 3 x5     │  │  ESXi 8 Update 3 x2          │  │
│  │  ~270 VMs               │  │  ~30 VMs críticas DB          │  │
│  └─────────────────────────┘  └──────────────────────────────┘  │
│                                                                  │
│  IBM FlashSystem 7300 (iSCSI/FC Datastores)                     │
│  vDS (vSphere Distributed Switch)                               │
│  Hivecloud Microseg. (VLAN masking)                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  DATACENTER CONTINGENCIA                        │
│  vCenter 8 (vcenter-cont.dominio.local)                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              CLUSTER CONTINGENCIA (2 ESXi)               │   │
│  │              ESXi 8 Update 3 x2                          │   │
│  │              ~30 VMs activas                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  IBM FlashSystem 7300 (iSCSI/FC Datastores)                     │
│  vDS (vSphere Distributed Switch)                               │
│  Hivecloud Microseg. (VLAN masking)                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│               CAPA IaC — CONTROL PLANE                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │  Terraform   │  │   Ansible    │  │  Git Repository     │   │
│  │  vSphere     │  │  Dynamic     │  │  (CI/CD Pipeline)   │   │
│  │  Provider    │  │  Inventory   │  │                     │   │
│  └──────────────┘  └──────────────┘  └─────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. INVENTARIO INICIAL DE ACTIVOS

| Componente | Producción | Contingencia |
|---|---|---|
| vCenter | vcenter-prod.dominio.local | vcenter-cont.dominio.local |
| Cluster App | cluster-app (5 hosts) | N/A |
| Cluster DB | cluster-db (2 hosts) | N/A |
| Cluster Cont. | N/A | cluster-cont (2 hosts) |
| ESXi Total | 7 hosts | 2 hosts |
| VMs estimadas | ~300 | ~30 |
| Storage | IBM FS7300 | IBM FS7300 |
| Red | vDS configurado | vDS configurado |
| Microseg. | Hivecloud | Hivecloud |
| Licencia | vSphere Foundation (TKG) | vSphere Foundation (TKG) |

---

## 6. PRERREQUISITOS TÉCNICOS

### 6.1 Software a instalar en MV Control (Jump Host)
```
- Terraform >= 1.7.x
- Terraform Provider: hashicorp/vsphere >= 2.6.x
- Ansible >= 2.15 (ansible-core)
- Python >= 3.11
- pyVmomi >= 8.0 (VMware Python SDK)
- community.vmware Ansible collection >= 4.x
- Git >= 2.40
- PowerCLI (opcional, para scripts de inventario)
- jq, yq (helpers CLI)
```

### 6.2 Credenciales y permisos requeridos
```
Terraform vSphere Provider:
  - Usuario de servicio: svc-terraform@vsphere.local
  - Rol mínimo: "IaC-Operator" (ver sección 6.3)
  
Ansible Dynamic Inventory:
  - Usuario de servicio: svc-ansible@vsphere.local  
  - Permiso: Read-Only + Guest Operations + VM Power

SSH/WinRM hacia VMs:
  - Usuario Linux: ansible-user (sudo sin password para comandos específicos)
  - Usuario Windows: ansible-svc (Admin local)
```

### 6.3 Rol vSphere personalizado para Terraform (principio de mínimo privilegio)
```
Permisos requeridos para rol "IaC-Operator":
  Datastore:
    - Allocate space
    - Browse datastore  
    - Low level file operations
  Network:
    - Assign network
  Resource:
    - Assign virtual machine to resource pool
  Virtual Machine - Configuration:
    - Add or remove device
    - Change CPU count
    - Change Memory
    - Change Settings
    - Extend virtual disk
  Virtual Machine - Interaction:
    - Power Off / Power On
  Virtual Machine - Provisioning:
    - Clone virtual machine
    - Customize virtual machine
```

### 6.4 Puertos de red requeridos (firewall rules)
```
Desde Jump Host → vCenter:
  TCP 443    (vSphere API / HTTPS)
  TCP 902    (VMware SDK)

Desde Jump Host → ESXi hosts:
  TCP 443
  TCP 902

Desde Jump Host → VMs Linux:
  TCP 22     (SSH - Ansible)

Desde Jump Host → VMs Windows:
  TCP 5985   (WinRM HTTP)
  TCP 5986   (WinRM HTTPS - recomendado)
  TCP 22     (si tienen OpenSSH)
```

---

## 7. RIESGOS Y MITIGACIONES

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|---|
| R1 | Terraform import falla en VMs con configuraciones especiales | MEDIA | MEDIO | Revisión manual previa + script de validación |
| R2 | Hot-add CPU/RAM no habilitado en VMware Tools de VMs legacy | ALTA | ALTO | Verificar VMware Tools versión; reinicio puede ser necesario |
| R3 | Hivecloud bloquea conectividad de Ansible hacia VMs | MEDIA | ALTO | Coordinar con equipo Hivecloud antes de Fase 1 |
| R4 | IBM FlashSystem 7300 datastores no reflejados correctamente | BAJA | MEDIO | Validar names datastores antes de import Terraform |
| R5 | Conflicto de state Terraform en operaciones paralelas | BAJA | ALTO | State locking obligatorio (backend remoto) |
| R6 | VMs críticas DB sin VMware Tools actualizado | MEDIA | ALTO | Ventana de mantenimiento + backup previo |
| R7 | Impacto en VMs contingencia activas durante import | MEDIA | MEDIO | terraform import no modifica VMs, solo lee estado |

---

## 8. EQUIPO RECOMENDADO

| Rol | Perfil | Dedicación |
|---|---|---|
| IaC Lead Engineer | Terraform + Ansible + VMware avanzado | 100% |
| vSphere Administrator | vCenter 8 + ESXi + Storage | 50% |
| Ops/Networking | Firewalls + VLANs + Hivecloud | 25% |
| Seguridad | Revisión de credenciales y accesos | 20% |
| Arquitecto Soluciones | Decisiones técnicas + TKG | 30% |

---

## 9. HERRAMIENTAS DE CONTROL DE CAMBIOS

```
Git Branching Strategy:
  main          → código aprobado y productivo
  develop       → integración continua
  feature/*     → desarrollo de nuevas automatizaciones
  hotfix/*      → correcciones urgentes
  
Pipeline Stages:
  1. terraform validate  → siempre en PR
  2. terraform plan      → requiere aprobación en PRs a main
  3. terraform apply     → requiere aprobación manual + ticket de cambio
  4. ansible-lint        → en cada commit
  5. ansible dry-run     → --check mode antes de apply real
```

---

## 10. CRITERIOS DE ÉXITO

- [ ] 100% de VMs de contingencia gestionadas por Terraform state
- [ ] 100% de VMs de producción gestionadas por Terraform state
- [ ] Escalado de CPU ejecutable en < 5 minutos por VM vía playbook
- [ ] Escalado de RAM ejecutable en < 5 minutos por VM vía playbook (hot-add)
- [ ] Adición de disco ejecutable en < 10 minutos por VM vía playbook
- [ ] Pipeline CI/CD con aprobación antes de apply en producción
- [ ] Inventario dinámico actualizado en tiempo real desde vCenter
- [ ] Cero cortes no planificados por operaciones IaC

