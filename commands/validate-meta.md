# /validate-meta — Validación del documento meta

Validá el documento meta del proyecto. $ARGUMENTS

<!--
Dos modos de uso:
1. Sin argumento: valida .ai/meta.md
2. Con argumento: valida la ruta indicada (ej: /validate-meta .ai/meta.md)

Este comando se ejecuta:
- Como paso previo al /recursive-audit (obligatorio)
- Cuando el usuario quiere verificar su meta antes de un sprint
- Dentro del skill code-orchestrator al detectar .ai/meta.md existente
-->

## Instrucciones

Leé el archivo `.ai/meta.md` (o la ruta pasada como argumento).
Validá en dos capas: estructural primero, semántica después.

### Capa 1 — Estructural (determinista)

Ejecutar estas validaciones mecánicas PRIMERO. Si fallan, reportar
pero continuar con el resto para dar feedback completo.

**Nivel 1: Headings obligatorios (FAIL si falta)**

Verificar que el meta contiene EXACTAMENTE estos headings:
```
## Visión
## Dominios
## Capacidades
## Restricciones transversales
## Parámetros del loop recursivo
```

Método: buscar la cadena exacta. Si falta → FAIL con "heading faltante: [nombre]".

**Nivel 2: Contenido no vacío (FAIL si vacío)**

Para cada heading obligatorio, verificar que hay al menos 1 línea de
contenido (excluyendo comentarios HTML y líneas en blanco).

**Nivel 3: Formato de capacidades (FAIL si no cumple)**

| Check | Qué verificar | Criterio |
|-------|--------------|----------|
| IDs únicos | Cada capacidad tiene un ID con formato `[A-Z]+-[0-9]+` | No hay IDs duplicados |
| Criterio verificable | Cada fila de capacidad tiene columna "Criterio verificable" no vacía | No hay celdas vacías |
| Prioridad válida | Cada fila tiene Alta, Media, o Baja | No hay valores fuera del enum |
| Dominio declarado | Cada prefijo de ID (DOM1, AUTH, etc.) aparece en la sección Dominios | No hay prefijos huérfanos |

**Nivel 4: Parámetros del loop (FAIL si no cumple)**

| Check | Criterio |
|-------|----------|
| max_iterations | Entero > 0 y ≤ 10 |
| coverage_threshold | Entero entre 50 y 100 (es un %) |
| diminishing_returns | Entero ≥ 1 |
| priority_cutoff | Alta, Media, o Baja |
| audit_split | "single" o "by_domain" |

### Capa 2 — Semántica (requiere interpretación)

Estas validaciones requieren juicio. Reportar como WARN, no FAIL.

**Nivel 5: Calidad de criterios verificables (WARN)**

Para cada capacidad, evaluar si el criterio es realmente verificable
por un agente Explore (read-only, sin estado de runtime):

| Tipo de criterio | Verificable? | Ejemplo |
|-----------------|-------------|---------|
| Existencia de archivo/función | ✅ Sí | "Existe src/auth/login.ts" |
| Output de comando | ✅ Sí | "npm test pasa" |
| Patrón en código | ✅ Sí | "Endpoint POST /auth/login existe en router" |
| Comportamiento en runtime | ⚠️ Parcial | "Retorna 200" — necesita servidor corriendo |
| Cualidad subjetiva | ❌ No | "Es rápido", "UX buena" |
| Sin threshold medible | ❌ No | "Maneja muchos usuarios" |

Si el criterio no es verificable → WARN con sugerencia de cómo reformularlo.

**Nivel 6: Consistencia de granularidad (WARN)**

Evaluar si las capacidades están al mismo nivel de abstracción:
- Si hay capacidades muy granulares mezcladas con muy abstractas → WARN
- Ejemplo de inconsistencia: "AUTH-01: El usuario puede registrarse" (alto nivel)
  junto con "AUTH-02: El campo email tiene validación regex /^[a-z].../" (muy bajo nivel)

**Nivel 7: Cobertura de dominios (WARN)**

Para cada dominio declarado en `## Dominios`:
- ¿Tiene al menos 1 capacidad definida? Si no → WARN "dominio sin capacidades"
- ¿Hay gaps obvios? (ej: dominio AUTH tiene login pero no logout) → WARN con sugerencia

**Nivel 8: Restricciones transversales (WARN)**

- ¿Cada restricción tiene un método de verificación concreto? Si no → WARN
- ¿Hay restricciones que contradicen capacidades? Si sí → WARN

## Formato de salida

```
## .ai/meta.md — [PASS | PASS WITH WARNINGS | FAIL]

### Estructural (determinista)
✅ Headings: 5/5 presentes
✅ Contenido no vacío: 5/5 secciones
✅ IDs: 15 capacidades, 0 duplicados, 0 prefijos huérfanos
❌ Parámetros: max_iterations falta

### Semántico
✅ Criterios verificables: 14/15 verificables
⚠️ AUTH-05: criterio "el sistema es seguro" no es observable → sugerir: "npm audit devuelve 0 vulnerabilidades críticas"
⚠️ Granularidad: AUTH-02 es significativamente más granular que AUTH-01
✅ Cobertura: todos los dominios tienen capacidades
✅ Restricciones: 3/3 con método de verificación

### Resumen
  Capacidades: 15 (12 Alta, 2 Media, 1 Baja)
  Dominios: 3
  Restricciones: 3
  Criterios verificables: 14/15 (93%)
  Estado: PASS WITH WARNINGS — 2 warnings semánticos
```

## Severidad

- **FAIL**: El meta no puede usarse para auditoría. Corregir antes de /recursive-audit.
- **PASS WITH WARNINGS**: Usable pero con riesgo de gaps en la auditoría. Revisar warnings.
- **PASS**: Listo para /recursive-audit.

$ARGUMENTS
