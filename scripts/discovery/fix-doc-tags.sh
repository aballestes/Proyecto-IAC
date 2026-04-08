#!/usr/bin/env bash
FILE='/mnt/c/BACKUP SEPTIEMBRE/GIFHUB/PROYECTO IAAC/docs/TAREA_0_4_NAMING_CONVENTIONS_VMS.md'

head -n 99 "$FILE" > /tmp/parte1.md

printf '\n## 4. Tags en vCenter\n\n' >> /tmp/parte1.md
printf '### 4.1. Tags actuales\n\n' >> /tmp/parte1.md
printf 'Segun el inventario, **ninguna VM tiene tags asignados** (tags = [] en el tfstate).\n\n' >> /tmp/parte1.md
printf '### 4.2. Tags propuestos para implementar en Fase 1\n\n' >> /tmp/parte1.md
printf '| Categoria       | Tag                     | VMs objetivo                             |\n' >> /tmp/parte1.md
printf '|-----------------|-------------------------|------------------------------------------|\n' >> /tmp/parte1.md
printf '| gestionado_por  | terraform               | Todas las VMs del tfvars                 |\n' >> /tmp/parte1.md
printf '| ambiente        | contingencia/produccion | Segun DC                                 |\n' >> /tmp/parte1.md
printf '| criticidad      | critica/media/baja      | Segun clasificacion tarea 0.3            |\n' >> /tmp/parte1.md
printf '| excluir_iac     | true                    | VMs infraestructura (Hivecloud, vCenter) |\n' >> /tmp/parte1.md

tail -n +128 "$FILE" >> /tmp/parte1.md
cp /tmp/parte1.md "$FILE"
echo "OK - $(wc -l < "$FILE") lineas"
