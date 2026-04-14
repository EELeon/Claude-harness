# hardening-02 — Worktree obligatorio para paralelismo

## Objetivo

Modificar la Regla 9 (ejecución paralela) en `templates/orchestrator-prompt.md` para que exija `isolation: "worktree"` desde la punta del branch del sprint, no desde main. Actualmente la regla no especifica de dónde crear el worktree.

## Complejidad: Simple

## Dependencias

- Requiere: hardening-01 (para que la numeración de reglas sea consistente)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `references/concurrency-classes.md` — lo cubre hardening-03
- `.ai/rules-v3.md` — instancia vieja

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Reforzar Regla 9 con requisito de worktree + base branch |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md` y localizar la Regla 9 ("Ejecución paralela con /batch").
2. En la sección "Cómo ejecutar" de la Regla 9, agregar después del punto 1 (agrupar tickets batch-eligible):

```
   1b. **Crear worktrees desde la punta del sprint branch:**
       Cada subagente paralelo DEBE correr con `isolation: "worktree"`.
       El worktree se crea desde el HEAD actual del branch del sprint,
       NO desde main ni desde un commit anterior.
       
       Esto es crítico: si el worktree se crea desde main, el cherry-pick
       posterior tendrá divergencia máxima y causará conflictos innecesarios.
       
       **Tickets secuenciales** (shared_write o con dependencias) corren
       en la sesión principal, sin worktree.
```

3. En la sección "Cuándo usar /batch", agregar un requisito adicional:
   - Después de "No comparten archivos en sus scope fences", agregar: `- Cada subagente usa isolation: "worktree" (obligatorio, no opcional)`

4. Commit: `"feat(hardening-02): worktree obligatorio para paralelismo — refuerzo Regla 9"`

---

## Tests que deben pasar

```bash
grep "isolation.*worktree" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "punta del sprint branch\|HEAD actual del branch" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "NO desde main" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea
```

- [ ] `grep_isolation`: El archivo menciona `isolation: "worktree"` como obligatorio
- [ ] `grep_sprint_branch`: El archivo especifica crear worktree desde HEAD del sprint branch
- [ ] `grep_not_main`: El archivo prohíbe explícitamente crear desde main

## Criterios de aceptación

- [ ] La Regla 9 exige `isolation: "worktree"` para tickets paralelos
- [ ] La Regla 9 especifica que el worktree se crea desde HEAD del branch del sprint
- [ ] La Regla 9 prohíbe crear worktrees desde main
- [ ] Los tickets secuenciales (shared_write) siguen en sesión principal

## NO hacer

- NUNCA cambiar la estructura de la Regla 9 (solo agregar contenido)
- NUNCA eliminar el texto existente sobre /batch
- NUNCA tocar reglas que no sean la 9
