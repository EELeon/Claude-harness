# hardening-03 — Protocolo de integración en concurrency classes

## Objetivo

Agregar sección "Protocolo de integración post-worktree" a `references/concurrency-classes.md` para que las clases `isolated_write` y `shared_write` documenten cómo integrar los commits al branch principal después de ejecución paralela.

## Complejidad: Simple

## Dependencias

- Requiere: hardening-01 (la nueva sección referencia la Regla 10)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/concurrency-classes.md`

### Archivos prohibidos
- `templates/orchestrator-prompt.md` — lo cubren hardening-01 y hardening-02
- `.ai/rules-v3.md` — instancia vieja

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `references/concurrency-classes.md` | Agregar sección de protocolo de integración al final |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `references/concurrency-classes.md` completo.
2. Agregar al final del archivo (después de la sección "Ejemplos de tickets reales por clase") la siguiente sección:

```markdown
## Protocolo de integración post-worktree

Cuando tickets `isolated_write` o `shared_write` se ejecutan en worktrees paralelos,
sus commits deben integrarse al branch del sprint. Este protocolo define cómo.

Ver Regla 10 en `templates/orchestrator-prompt.md` para las reglas detalladas de cherry-pick.

### Para `isolated_write` (paralelo en worktree)

1. Crear worktree desde HEAD del branch del sprint (NUNCA desde main)
2. Subagente ejecuta y hace commit en el worktree
3. Cherry-pick al branch del sprint: `git cherry-pick [hash]`
4. Si no hay conflicto → OK
5. Si hay conflicto (raro para isolated_write, pero posible en archivos transversales
   como imports o __init__.py) → resolver preservando HEAD + agregar líneas nuevas
6. Correr tests después del cherry-pick

### Para `shared_write` (secuencial estricto)

Los tickets `shared_write` NO deben ejecutarse en worktrees paralelos.
Se ejecutan secuencialmente en la sesión principal. Si por error se ejecutan
en paralelo y hay colisión, aplicar situación #9 de `references/recovery-matrix.md`.

### Antipatrón: `--theirs` en cherry-pick

NUNCA resolver conflictos con `git cherry-pick --theirs`. Esto reemplaza el archivo
completo con la versión del worktree, perdiendo todos los cambios que tickets
anteriores del sprint ya integraron al branch. Esta es la causa más frecuente
de regresiones silenciosas en sprints multi-ticket.
```

3. Commit: `"feat(hardening-03): protocolo de integración post-worktree en concurrency classes"`

---

## Tests que deben pasar

```bash
grep "Protocolo de integración post-worktree" references/concurrency-classes.md
# Debe retornar la línea del título de sección

grep "NUNCA.*--theirs" references/concurrency-classes.md
# Debe retornar la línea del antipatrón

grep "Regla 10" references/concurrency-classes.md
# Debe retornar la cross-reference
```

- [ ] `grep_section`: Existe la sección "Protocolo de integración post-worktree"
- [ ] `grep_antipattern`: Se documenta el antipatrón de `--theirs`
- [ ] `grep_crossref`: Hay cross-reference a Regla 10

## Criterios de aceptación

- [ ] La sección documenta el flujo para `isolated_write` y `shared_write`
- [ ] Hay cross-reference a la Regla 10 del orchestrator-prompt
- [ ] Se documenta el antipatrón de `--theirs` con razón
- [ ] El formato es consistente con las secciones existentes del documento

## NO hacer

- NUNCA modificar la tabla de clases ni el árbol de decisión existentes
- NUNCA duplicar contenido que ya está en Regla 10 — solo referenciar
