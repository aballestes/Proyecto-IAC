# Tarea 0.4 – Naming Conventions y Organización de VMs

Este documento sirve como **plantilla** para documentar la situación actual de las VMs en vSphere (estado AS-IS) y la propuesta de estandarización (TO-BE).

Fuente principal de datos: archivos CSV generados por el inventario automático (por ejemplo `inventario_datacenter_contingencia.csv` y `inventario_produccion.csv`).

---

## 1. Naming Conventions Actuales (AS-IS)

### 1.1. Patrones de nombres observados

- Ejemplos de nombres típicos de VMs:
  - `...`
  - `...`
- Prefijos identificados (por ambiente, rol, etc.):
  - `PRD-`, `PROD-`, `DEV-`, `QA-`, `TST-`, etc.
- Sufijos o códigos usados (cliente, aplicación, región, etc.):
  - `-DB`, `-APP`, `-WEB`, `-PREP`, `-MRP`, etc.

> **Cómo llenarlo:** filtrar en la columna `VM Name` y listar aquí los patrones repetidos que encuentres.

### 1.2. Problemas detectados

- VMs de producción sin prefijo claro de ambiente.
- Mezcla de idiomas / abreviaturas incoherentes.
- Nombres muy largos o poco descriptivos.
- Otras observaciones:
  - `...`

---

## 2. Propuesta de Naming Convention (TO-BE)

Definir cómo deberían llamarse las VMs nuevas y, a futuro, cómo renombrar las existentes cuando sea posible.

### 2.1. Formato recomendado de nombre

Ejemplo de estructura general:

```text
<Ambiente>-<Aplicacion>-<Rol>-<Secuencia>
```

Donde:

- `Ambiente`: `PRD`, `PRE`, `DEV`, `QA`, `LAB`, `CONT`.
- `Aplicacion`: código corto de la aplicación/sistema (máx. 8–10 caracteres).
- `Rol`: `APP`, `WEB`, `DB`, `RPT`, `JOB`, etc.
- `Secuencia`: `01`, `02`, `03`…

> Ajustar este formato a la realidad del banco (puedes proponer otro si ya existe un estándar interno).

### 2.2. Ejemplos

- Contingencia
  - `CONT-CELTA-DB-01`
  - `CONT-CELTA-APP-02`
- Producción
  - `PRD-CELTA-WEB-01`
  - `PRD-CELTA-BATCH-01`

### 2.3. Reglas específicas

- Longitud máxima recomendada: `N` caracteres.
- Caracteres permitidos: letras mayúsculas, números y guiones (`A-Z`, `0-9`, `-`).
- No usar espacios ni caracteres especiales (`_`, `/`, `.` etc.).
- Reservar prefijos especiales (por ejemplo, `MGMT-` para infraestructura interna).

---

## 3. Carpetas (Folders) y Resource Pools

### 3.1. Estructura actual de carpetas

Usar la columna `Folder` del inventario para describir cómo están organizadas hoy las VMs.

- Ejemplos de rutas de folder:
  - `CELTA/PRODUCCION/APP`
  - `CELTA/CONTINGENCIA/DB`
  - `...`
- Observaciones:
  - Carpetas mezclan ambientes (desarrollo + producción).
  - VMs críticas en carpetas genéricas (`Misc`, `SinClasificar`, etc.).

### 3.2. Propuesta de estructura estándar

Definir una estructura objetivo más clara, por ejemplo:

```text
<Capa>/<Ambiente>/<Aplicacion>/<Rol>
```

Ejemplo:

- `CELTA/PRODUCCION/CELTA/APP`
- `CELTA/PRODUCCION/CELTA/DB`
- `CELTA/CONTINGENCIA/CELTA/APP`

> Adaptar según la organización real (puede ser por cliente, país, línea de negocio, etc.).

### 3.3. Resource Pools

Si se usan Resource Pools, documentar aquí:

- Resource Pools existentes y su propósito.
- Reglas actuales de asignación (qué entra en cada pool).
- Problemas detectados (pools sin uso, VMs en el root, etc.).

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

- Resumen de principales desviaciones detectadas entre AS-IS y TO-BE.
- Riesgos asociados (por ejemplo, difícil identificar qué VMs son críticas en incidentes).
- Quick wins sugeridos para Fase 1:
  - Normalizar nombres de VMs nuevas según el estándar.
  - Empezar a aplicar tags mínimos en todas las VMs nuevas.
  - Reorganizar carpetas para **un** datacenter piloto (por ejemplo, Contingencia).

---

## 6. Aprobaciones / Decisiones

- Fecha de validación de este estándar.
- Áreas que lo aprueban (Infraestructura, Seguridad, Arquitectura, etc.).
- Observaciones finales.
