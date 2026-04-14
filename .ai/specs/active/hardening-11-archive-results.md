# hardening-11 — Archivar results.tsv por sprint

## Objetivo

Modificar el flujo de limpieza post-ejecución en `references/entrega-sprint.md` y `templates/orchestrator-prompt.md` para que results.tsv se copie a `.ai/runs/archive/[sprint].tsv` ANTES de borrarlo. Actualmente se borra sin respaldo, perdiendo el detalle por ticket.

## Complejidad: Simple

## Dependencias

- Requiere: hardening-10 (el registry referencia la ruta del results.tsv archivado)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/entrega-sprint.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `.ai/runs/results.tsv` — datos, no template
- `references/sprint-registry.md` — lo cubre hardening-10

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `references/entrega-sprint.md` | Agregar paso de archivado de results.tsv antes de borrar |
| `templates/orchestrator-prompt.md` | Agregar paso de archivado en limpieza |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `references/entrega-sprint.md`. En la sección "## Limpieza post-ejecución", los comandos actuales son:

```bash
# 1. Crear carpeta de archivo si no existe
mkdir -p .ai/specs/archive/[nombre-batch]
# 2. Mover specs al archivo
mv .ai/specs/active/* .ai/specs/archive/[nombre-batch]/
# 3. Borrar artefactos temporales
rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv
```

Insertar entre paso 2 y paso 3:

```bash
# 2b. Archivar results.tsv antes de borrar
mkdir -p .ai/runs/archive
cp .ai/runs/results.tsv .ai/runs/archive/[nombre-batch].tsv
```

Y cambiar la línea de "**Temporales**" para reflejar que results.tsv se archiva:

**Antes:** ``.ai/specs/active/*`, `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv``
**Después:** ``.ai/specs/active/*`, `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv` (se archiva antes de borrar en `.ai/runs/archive/`)``

2. Agregar `.ai/runs/archive/` a la lista de permanentes:

```
`.ai/runs/archive/*` — historial de results.tsv por sprint
```

3. En el mapa de estructura del archivo, agregar:

```
│   ├── runs/
│   │   ├── results.tsv         # Tracking (se crea vacío con header)
│   │   └── archive/            # results.tsv archivados por sprint
│   │       └── [nombre-batch].tsv
```

4. Leer `templates/orchestrator-prompt.md`. En la sección "## Al terminar todos los tickets", paso 5 ("Limpieza de artefactos"), insertar antes del `rm -f`:

```bash
   # Archivar results.tsv
   mkdir -p .ai/runs/archive
   cp .ai/runs/results.tsv .ai/runs/archive/[nombre-batch].tsv
```

5. Commit: `"feat(hardening-11): archivar results.tsv por sprint antes de borrar"`

---

## Tests que deben pasar

```bash
grep "runs/archive" references/entrega-sprint.md
# Debe retornar al menos 2 líneas (comando + mapa)

grep "runs/archive" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "cp.*results.tsv.*archive" references/entrega-sprint.md
# Debe retornar el comando de copia
```

- [ ] `grep_entrega_archive`: entrega-sprint.md menciona runs/archive
- [ ] `grep_prompt_archive`: orchestrator-prompt.md menciona runs/archive
- [ ] `grep_cp_command`: Hay comando `cp` de results.tsv a archive

## Criterios de aceptación

- [ ] El flujo de limpieza copia results.tsv a `.ai/runs/archive/[nombre-batch].tsv` antes de borrar
- [ ] `.ai/runs/archive/` está en el mapa de estructura
- [ ] `.ai/runs/archive/*` está listado como permanente (NO borrar)
- [ ] El orchestrator-prompt tiene el paso de archivado

## NO hacer

- NUNCA mover results.tsv — copiarlo (cp, no mv), luego borrar con el rm -f existente
- NUNCA cambiar el formato de results.tsv
