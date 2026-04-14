# hardening-10 — Sprint registry: archivo de trazabilidad

## Objetivo

Crear `references/sprint-registry.md` que documenta el protocolo de registro de sprints ejecutados. Agregar el paso de registro al flujo de entrega en `references/entrega-sprint.md`. El archivo de datos real (`.ai/sprint-registry.md`) se crea en cada repo target al ejecutar el primer sprint — este ticket solo crea la documentación y el template.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: hardening-11 (archive de results.tsv referencia el registry)

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/sprint-registry.md` (crear)
- `references/entrega-sprint.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `.ai/sprint-registry.md` — NO crear el archivo de datos en el plugin; se crea en cada repo
- `.ai/rules-v3.md` — instancia vieja

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/sprint-registry.md` | Protocolo de registro + template del archivo de datos |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `references/entrega-sprint.md` | Agregar paso de registro en sprint-registry al flujo de entrega |
| `templates/orchestrator-prompt.md` | Agregar paso de registro al bloque "Al terminar todos los tickets" |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Crear `references/sprint-registry.md` con este contenido:

```markdown
# Sprint Registry — Protocolo de trazabilidad

## Propósito

Registrar cada sprint ejecutado para trazabilidad histórica. El registro permite:
- Saber cuántos sprints se han corrido en un repo
- Ver la tasa de keep/discard por sprint
- Identificar tendencias de calidad a lo largo del tiempo
- Encontrar el results.tsv archivado de cualquier sprint

## Ubicación del archivo de datos

```
repo-target/.ai/sprint-registry.md
```

Se crea con el header al ejecutar el primer sprint. Se acumula con cada sprint posterior.

## Formato

```markdown
# Sprint Registry

| Sprint | Rama | Fecha | PR | Tickets | Keep | Discard | Rollbacks | Results |
|--------|------|-------|----|---------|------|---------|-----------|---------|
| hardening-p4 | feat/hardening-p4 | 2026-04-13 | #6 | 13 | 13 | 0 | 0 | .ai/runs/archive/hardening-p4.tsv |
```

### Columnas

1. **Sprint**: Nombre del sprint (el prefix usado en specs)
2. **Rama**: Branch de git
3. **Fecha**: Fecha de creación del PR (YYYY-MM-DD)
4. **PR**: Número del PR (con #)
5. **Tickets**: Total de tickets ejecutados
6. **Keep**: Tickets con status keep
7. **Discard**: Tickets con status discard
8. **Rollbacks**: Total de rollbacks (suma de rollback_count de results.tsv)
9. **Results**: Ruta al results.tsv archivado

## Cuándo registrar

Al terminar todos los tickets de un sprint, DESPUÉS de crear el PR y ANTES
de archivar specs. El orquestador calcula los totales leyendo results.tsv
y agrega una fila al registry.

## Primer sprint en un repo nuevo

Si `.ai/sprint-registry.md` no existe, crearlo con el header markdown antes
de agregar la primera fila.

## Relación con otros artefactos

- `results.tsv` tiene el detalle por ticket → sprint-registry tiene el resumen
- `entrega-sprint.md` define el flujo → sprint-registry es un paso dentro del flujo
- Los specs archivados en `.ai/specs/archive/[sprint]/` complementan el historial
```

2. Leer `references/entrega-sprint.md`. En la sección "## Limpieza post-ejecución", agregar un paso ANTES del paso de mover specs (entre "Crear carpeta de archivo" y "Mover specs al archivo"):

```bash
# 1b. Registrar en sprint registry
# Si no existe, crear con header
if [ ! -f .ai/sprint-registry.md ]; then
  echo "# Sprint Registry" > .ai/sprint-registry.md
  echo "" >> .ai/sprint-registry.md
  echo "| Sprint | Rama | Fecha | PR | Tickets | Keep | Discard | Rollbacks | Results |" >> .ai/sprint-registry.md
  echo "|--------|------|-------|----|---------|------|---------|-----------|---------|" >> .ai/sprint-registry.md
fi
# Agregar fila (el orquestador calcula los valores leyendo results.tsv)
echo "| [sprint] | [rama] | [fecha] | #[pr] | [total] | [keep] | [discard] | [rollbacks] | .ai/runs/archive/[sprint].tsv |" >> .ai/sprint-registry.md
```

3. En la misma sección, agregar `.ai/sprint-registry.md` a la lista de "**NO borrar:**":

```
- `.ai/sprint-registry.md` — historial acumulativo de sprints
```

4. También agregar al mapa de archivos de entrega-sprint.md, en la sección "**Permanentes**":

```
`.ai/sprint-registry.md`
```

5. Leer `templates/orchestrator-prompt.md`. En la sección "## Al terminar todos los tickets", agregar un paso 5b después de "Limpieza de artefactos" (paso 5):

```
5b. **Registrar en sprint registry:**
   Si `.ai/sprint-registry.md` no existe, crearlo con header markdown (tabla con 9 columnas).
   Leer `.ai/runs/results.tsv` y calcular totales. Agregar una fila con:
   sprint name, rama, fecha de hoy, número del PR, total tickets,
   count(keep), count(discard), sum(rollback_count), ruta al results.tsv archivado.
```

6. Commit: `"feat(hardening-10): sprint registry — protocolo de trazabilidad"`

---

## Tests que deben pasar

```bash
test -f references/sprint-registry.md
# Debe existir

grep "Sprint Registry" references/sprint-registry.md
# Debe retornar el título

grep "sprint-registry" references/entrega-sprint.md
# Debe retornar al menos 1 línea

grep "sprint registry\|sprint-registry" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea
```

- [ ] `file_exists`: `references/sprint-registry.md` existe
- [ ] `grep_registry_doc`: El documento tiene formato y protocolo
- [ ] `grep_entrega`: `entrega-sprint.md` referencia el sprint registry
- [ ] `grep_prompt`: El orchestrator prompt incluye paso de registro

## Criterios de aceptación

- [ ] `references/sprint-registry.md` existe con formato, columnas, y protocolo
- [ ] `references/entrega-sprint.md` incluye paso de registro en limpieza post-ejecución
- [ ] `templates/orchestrator-prompt.md` tiene paso 5b de registro
- [ ] El sprint-registry.md se lista como archivo permanente (NO borrar)
- [ ] NO se crea `.ai/sprint-registry.md` en el plugin — solo la documentación

## NO hacer

- NUNCA crear `.ai/sprint-registry.md` en el plugin — se crea en cada repo target
- NUNCA hacer backfill de sprints históricos — esto es responsabilidad de cada repo
- NUNCA poner datos reales en `references/sprint-registry.md` — es solo documentación
