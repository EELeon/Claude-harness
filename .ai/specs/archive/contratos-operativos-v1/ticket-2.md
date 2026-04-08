# Ticket 2 — Clases de ejecución formal (concurrencia)

## Objetivo

Agregar un campo obligatorio `execution_class` a cada spec que clasifique el tipo de concurrencia permitida para ese ticket. Esto formaliza el criterio de paralelismo que hoy es implícito ("no compartir archivos") y habilita scheduling más seguro.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `.claude/commands/preflight.md`
- `references/concurrency-classes.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `templates/orchestrator-prompt.md` — lo tocan T-1 y T-4
- `.claude/settings.json` — configuración de hooks, fuera de scope
- `references/output-budgets.md` — lo crea T-1

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/concurrency-classes.md` | Documento de referencia con la taxonomía de clases de ejecución y reglas de scheduling por clase |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar campo `execution_class` con las 4 opciones y documentación inline |
| `.claude/commands/preflight.md` | Agregar validación del campo `execution_class` en la capa estructural |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/concurrency-classes.md` con:
   - Tabla de 4 clases: `read_only`, `isolated_write`, `shared_write`, `repo_wide`
   - Definición clara de cada clase con ejemplos concretos
   - Reglas de scheduling: read_only → paralelo libre, isolated_write → paralelo en worktree, shared_write → secuencial estricto, repo_wide → sesión principal
   - Guía para clasificar: "¿Cómo decidir qué clase asignar?" con árbol de decisión
   - Ejemplos de tickets reales para cada clase
2. Leer `templates/spec-template.md` y agregar después de la línea `## Modo de ejecución`:
   ```
   ## Clase de ejecución: [read_only | isolated_write | shared_write | repo_wide]
   ```
   Con un comentario HTML explicando cada opción y cuándo usarla
3. Leer `.claude/commands/preflight.md` y agregar en la sección "Level 1: Heading existence":
   - `## Clase de ejecución` como heading obligatorio
   Y en la sección "Level 3: Data format":
   - Validar que el valor sea uno de los 4 permitidos: `read_only | isolated_write | shared_write | repo_wide`
4. Verificar consistencia: los nombres de las clases en los 3 archivos deben ser idénticos
5. Commit: `"feat(T-2): agregar clases de ejecución formal para concurrencia segura"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/concurrency-classes.md && echo "PASS" || echo "FAIL"
# Verificar que spec-template tiene execution_class
grep -q "execution_class\|Clase de ejecución" templates/spec-template.md && echo "PASS" || echo "FAIL"
# Verificar que preflight valida execution_class
grep -q "execution_class\|Clase de ejecución" .claude/commands/preflight.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/concurrency-classes.md` existe y no está vacío
- [ ] `test_spec_template_field`: `templates/spec-template.md` contiene el campo de clase de ejecución
- [ ] `test_preflight_validates`: `.claude/commands/preflight.md` valida el campo de clase de ejecución

## Criterios de aceptación

- [ ] Existe `references/concurrency-classes.md` con las 4 clases definidas
- [ ] Cada clase tiene definición, regla de scheduling, y al menos 1 ejemplo
- [ ] `templates/spec-template.md` incluye el campo `Clase de ejecución` con las 4 opciones
- [ ] `.claude/commands/preflight.md` valida que el campo exista y tenga un valor válido
- [ ] Los nombres de las 4 clases son idénticos en los 3 archivos

## NO hacer

- NUNCA inventar más de 4 clases — la taxonomía debe ser simple y memorable
- NUNCA modificar la lógica de detección de batch-eligible en `references/flujo-principal.md` — eso es un cambio separado
- NUNCA cambiar el formato de los headings existentes en preflight — solo agregar el nuevo
- NUNCA agregar validación semántica de la clase vs el scope fence (eso es mejora futura)

---

## Checklist de autocontención

- [x] ¿Tiene scope fence (archivos permitidos + prohibidos)?
- [x] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [x] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [x] ¿Tiene comando exacto de tests?
- [x] ¿Tiene commit message definido?
- [x] ¿Tiene criterios de aceptación observables?
- [x] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [x] ¿Tiene ≤10 restricciones totales?
- [x] ¿No depende de contexto que solo existe en la conversación?
