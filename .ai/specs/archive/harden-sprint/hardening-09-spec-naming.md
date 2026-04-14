# hardening-09 — Convención de naming para specs

## Objetivo

Crear `references/spec-naming.md` que define la convención de nombres para specs: `[sprint-prefix]-[seq]-[slug].md`. Actualizar el spec template y el orchestrator-prompt para usar esta convención en vez del genérico `ticket-N.md`.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: hardening-10 (el registry referencia la convención de naming)

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/spec-naming.md` (crear)
- `templates/spec-template.md`
- `templates/orchestrator-prompt.md`
- `references/entrega-sprint.md`

### Archivos prohibidos
- `.ai/specs/active/*` — no renombrar specs existentes
- `.ai/specs/archive/*` — no tocar archivos históricos

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/spec-naming.md` | Convención de naming para specs, con reglas, ejemplos, y árbol de decisión |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Cambiar `# Ticket [N]` por el formato con naming convention |
| `templates/orchestrator-prompt.md` | Actualizar referencias a `ticket-N.md` con el nuevo patrón |
| `references/entrega-sprint.md` | Actualizar el mapa de archivos para reflejar el nuevo naming |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Crear `references/spec-naming.md` con este contenido:

```markdown
# Convención de naming para specs

## Formato

```
[sprint-prefix]-[seq]-[slug].md
```

Donde:
- **sprint-prefix**: Identificador corto del sprint, derivado del nombre de la rama.
  Ejemplos: `hardening`, `runtime-fixes`, `audit-close`, `contracts-v1`
- **seq**: Secuencia de 2 dígitos, en orden de ejecución. Empieza en 01.
- **slug**: Descripción corta en kebab-case (2-4 palabras). Describe QUÉ hace el ticket.

### Ejemplos

| Sprint | Rama | Spec |
|--------|------|------|
| Hardening P4 | `feat/hardening-p4` | `hardening-01-cherrypick-safe.md` |
| Runtime fixes | `feat/sprint-f-runtime` | `runtime-01-scheduler-drift.md` |
| Audit close | `sprint-1-audit-close` | `audit-01-enum-canon.md` |

### Reglas

1. El **sprint-prefix** se define UNA VEZ al crear el sprint y se usa para TODOS los specs del batch.
2. La **secuencia** refleja orden de ejecución, no prioridad.
3. El **slug** debe ser único dentro del sprint (no entre sprints).
4. El ID completo (prefix + seq) aparece en:
   - El nombre del archivo: `hardening-01-cherrypick-safe.md`
   - El header del spec: `# hardening-01 — Protocolo de cherry-pick seguro`
   - El commit message: `feat(hardening-01): protocolo de cherry-pick seguro`
   - El results.tsv: columna `ticket` = `hardening-01`
5. NUNCA reusar un ID dentro del mismo sprint.
6. Los specs archivados mantienen su nombre original (no renombrar al archivar).

### Migración de naming viejo

Los sprints P1-P3 usaron `ticket-N.md` con IDs `T-1` a `T-12`. Estos archivos
ya archivados conservan su nombre. El nuevo naming aplica desde P4 en adelante.

### En el orchestrator-prompt

La tabla de tickets usa el ID completo:

```
| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | hardening-01 — Cherry-pick seguro | `.ai/specs/active/hardening-01-cherrypick-safe.md` | Simple |
```

El prompt del subagente referencia el spec por ruta completa, no por ID.
```

2. Leer `templates/spec-template.md`. Cambiar la primera línea:

**Antes:** `# Ticket [N] — [Título descriptivo]`
**Después:** `# [sprint-prefix]-[seq] — [Título descriptivo]`

Y agregar debajo del título:

```
<!-- Naming convention: ver references/spec-naming.md
     Formato del archivo: [sprint-prefix]-[seq]-[slug].md
     Ejemplo: hardening-01-cherrypick-safe.md -->
```

3. Leer `templates/orchestrator-prompt.md`. En la tabla de tickets del template, cambiar:

**Antes:** `| 1 | T-[N] — [Título] | \`.ai/specs/active/ticket-[N].md\` | [Simple/Media/Alta] |`
**Después:** `| 1 | [prefix]-[seq] — [Título] | \`.ai/specs/active/[prefix]-[seq]-[slug].md\` | [Simple/Media/Alta] |`

4. Leer `references/entrega-sprint.md`. En el mapa de estructura, cambiar:

**Antes:**
```
│   │   ├── active/             # Specs del batch actual
│   │   │   ├── ticket-1.md
│   │   │   ├── ticket-2.md
```

**Después:**
```
│   │   ├── active/             # Specs del batch actual
│   │   │   ├── [prefix]-01-[slug].md
│   │   │   ├── [prefix]-02-[slug].md
```

5. Commit: `"feat(hardening-09): convención de naming para specs"`

---

## Tests que deben pasar

```bash
test -f references/spec-naming.md
# Debe existir

grep "sprint-prefix.*seq.*slug" references/spec-naming.md
# Debe retornar el formato

grep "\[sprint-prefix\]-\[seq\]" templates/spec-template.md
# Debe retornar la primera línea del template

grep "\[prefix\]-\[seq\]" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea
```

- [ ] `file_exists`: `references/spec-naming.md` existe
- [ ] `grep_format`: El documento define el formato con las 3 partes
- [ ] `grep_template`: El spec template usa el nuevo formato en el header
- [ ] `grep_prompt`: El orchestrator prompt usa el nuevo formato en la tabla

## Criterios de aceptación

- [ ] `references/spec-naming.md` existe con formato, reglas, y ejemplos
- [ ] El spec template usa `[sprint-prefix]-[seq]` en vez de `Ticket [N]`
- [ ] El orchestrator-prompt usa el nuevo formato en la tabla de tickets
- [ ] `references/entrega-sprint.md` refleja el nuevo patrón de archivos
- [ ] El ID aparece en 4 lugares documentados: archivo, header, commit, results.tsv

## NO hacer

- NUNCA renombrar specs existentes en archive/ — solo aplica para specs nuevos
- NUNCA usar más de 4 palabras en el slug
- NUNCA cambiar el formato de results.tsv — solo el valor de la columna `ticket`
