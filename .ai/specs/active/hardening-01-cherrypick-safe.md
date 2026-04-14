# hardening-01 — Protocolo de cherry-pick seguro

## Objetivo

Agregar Regla 10 a `templates/orchestrator-prompt.md` que define el protocolo obligatorio de integración post-worktree, eliminando el uso de `--theirs` como resolución default de conflictos en cherry-picks.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: hardening-02, hardening-03, hardening-04

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `.ai/rules-v3.md` — es instancia vieja, no template
- `references/concurrency-classes.md` — lo cubre hardening-03
- `references/recovery-matrix.md` — lo cubre hardening-04
- `CLAUDE.md` — fuera de alcance

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar Regla 10 después de Regla 9 |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md` completo para entender la estructura de reglas existente (R1-R9).
2. Agregar la siguiente regla después de la Regla 9 (dentro del bloque markdown que empieza con ````markdown`), manteniendo el mismo estilo y nivel de detalle:

```
## Regla 10: Protocolo de cherry-pick seguro (integración post-worktree)
Cuando se integran commits de worktrees al branch del sprint via cherry-pick:

**Paso 1 — Dry-run obligatorio:**
Antes de cherry-pick real, ejecutar `git cherry-pick --no-commit [hash]`
para detectar conflictos. Si hay conflictos, abortar con `git cherry-pick --abort`.

**Paso 2 — Resolución de conflictos:**
- Si NO hay conflictos: `git cherry-pick [hash]` (normal)
- Si hay conflictos: resolver manualmente con estas reglas:
  1. NUNCA usar `--theirs` en archivos que otros tickets del sprint ya modificaron.
     `--theirs` sobrescribe los cambios de tickets anteriores, causando regresiones silenciosas.
  2. SIEMPRE preservar HEAD para el contenido existente y agregar SOLO las líneas nuevas del worktree.
  3. Si el conflicto es en un archivo que el worktree no debería haber tocado (fuera de scope),
     resolver con `git checkout HEAD -- [archivo]` para descartar los cambios del worktree en ese archivo.

**Paso 3 — Verificación post-merge:**
Después de cada cherry-pick con conflictos resueltos, correr los tests del sprint
ANTES de continuar con el siguiente cherry-pick. Un conflicto mal resuelto
se detecta más fácil con 1 cherry-pick que con 5 acumulados.

**Evidencia:** En 4 sprints observados, `--theirs` causó regresiones silenciosas
en 4+ ocasiones, requiriendo commits `fix(merge)` costosos.
```

3. Verificar que la numeración de reglas es consistente (no hay otra Regla 10 ya definida).
4. Commit: `"feat(hardening-01): protocolo de cherry-pick seguro — Regla 10"`

---

## Tests que deben pasar

```bash
# Verificar estructura del archivo
grep -c "## Regla 10" templates/orchestrator-prompt.md
# Debe retornar 1

grep "NUNCA usar.*--theirs" templates/orchestrator-prompt.md
# Debe retornar la línea de la regla

grep "cherry-pick --no-commit" templates/orchestrator-prompt.md
# Debe retornar la línea del dry-run
```

- [ ] `grep_regla_10`: Existe exactamente una "## Regla 10" en el archivo
- [ ] `grep_no_theirs`: La regla menciona explícitamente "NUNCA usar `--theirs`"
- [ ] `grep_dry_run`: La regla menciona `cherry-pick --no-commit` como paso obligatorio

## Criterios de aceptación

- [ ] `templates/orchestrator-prompt.md` contiene Regla 10 con el protocolo de cherry-pick
- [ ] La regla incluye los 3 pasos: dry-run, resolución, verificación post-merge
- [ ] La regla prohíbe explícitamente `--theirs` en archivos compartidos
- [ ] El estilo es consistente con las reglas R1-R9 existentes

## NO hacer

- NUNCA modificar el contenido de las Reglas 1-9 existentes
- NUNCA agregar la regla fuera del bloque markdown del template (hay un bloque ````markdown` que contiene las reglas)
- NUNCA tocar archivos que no sean `templates/orchestrator-prompt.md`
