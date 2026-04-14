# Ticket 11 — Estructura project_notes/ en .ai

## Objetivo

Crear la estructura y convenciones para un subdirectorio `.ai/docs/project_notes/` que almacene conocimiento no-efímero del proyecto: bugs conocidos, decisiones arquitectónicas, hechos clave, e issues abiertos. Esto complementa la experience library (conocimiento destilado de ejecuciones) con conocimiento estático del proyecto que no cambia entre sprints.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: read_only

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/project-notes-guide.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `.claude/commands/learn.md` — fuera de scope
- `templates/spec-template.md` — fuera de scope
- `references/experience-library.md` — complemento, no modificar

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/project-notes-guide.md` | Guía de estructura, convenciones, y uso de project_notes/ |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar referencia a project_notes/ en la sección de setup para que el orquestador los consulte |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/project-notes-guide.md` con:

   **Estructura:**
   ```
   .ai/docs/project_notes/
   ├── bugs.md          # Bugs conocidos no resueltos — con severidad y workaround
   ├── decisions.md     # Decisiones arquitectónicas del proyecto (complementa .ai/decisions/)
   ├── key_facts.md     # Hechos clave: constraints externos, dependencias, límites técnicos
   └── issues.md        # Issues abiertos no cubiertos por specs actuales
   ```

   **Convenciones por archivo:**

   `bugs.md`:
   ```markdown
   ### [BUG-N] — [Título]
   - **Severidad:** alta | media | baja
   - **Descripción:** [Qué falla]
   - **Workaround:** [Cómo evitarlo mientras no se resuelve]
   - **Archivos afectados:** [rutas]
   - **Reportado:** [fecha]
   ```

   `decisions.md`:
   ```markdown
   ### [ADR-N] — [Título]
   - **Estado:** aceptada | superseded | deprecated
   - **Contexto:** [Por qué se tomó esta decisión]
   - **Decisión:** [Qué se decidió]
   - **Consecuencias:** [Qué implica para el proyecto]
   ```

   `key_facts.md`:
   ```markdown
   ### [Categoría]
   - [Hecho concreto con fuente/referencia]
   ```

   `issues.md`:
   ```markdown
   ### [ISSUE-N] — [Título]
   - **Prioridad:** alta | media | baja
   - **Descripción:** [Qué necesita resolverse]
   - **Bloqueado por:** [dependencia externa, decisión pendiente, etc.]
   ```

   **Diferencia con otros archivos del harness:**
   - `done-tasks.md` = registro cronológico de ejecuciones (efímero por sprint)
   - `.ai/experience/` = insights destilados de ejecuciones (evolucionan con ADD/MERGE/PRUNE)
   - `.ai/decisions/` = decisiones tomadas durante sprints específicos (por batch)
   - `project_notes/` = conocimiento estático del proyecto (actualizado manualmente, no por el orquestador)

   **Quién lo mantiene:** El usuario, con ayuda de `/learn` que puede sugerir agregar entradas. El orquestador NO modifica project_notes — solo los lee como contexto.

   **Cuándo crear:** Los archivos se crean cuando hay contenido real. No pre-crear archivos vacíos.

2. Leer `templates/orchestrator-prompt.md` y agregar en "Setup inicial" o en la sección de consulta de experiencia:
   ```markdown
   Si existe `.ai/docs/project_notes/`, leé `bugs.md` y `key_facts.md` para contexto del proyecto.
   Tené en cuenta bugs conocidos al verificar resultados de subagentes.
   NO modifiques archivos en project_notes/ — son mantenidos por el usuario.
   ```

3. Verificar consistencia
4. Commit: `"feat(T-11): agregar estructura y guía de project_notes/ para conocimiento estático"`

## Tests que deben pasar

```bash
# Verificar que la guía existe
test -s references/project-notes-guide.md && echo "PASS" || echo "FAIL"
# Verificar que define los 4 archivos
grep -c "bugs.md\|decisions.md\|key_facts.md\|issues.md" references/project-notes-guide.md | xargs test 4 -le && echo "PASS" || echo "FAIL"
# Verificar referencia en orchestrator-prompt
grep -qi "project_notes" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_guide_exists`: El archivo `references/project-notes-guide.md` existe
- [ ] `test_four_files_defined`: La guía define los 4 archivos con formato
- [ ] `test_prompt_reference`: `templates/orchestrator-prompt.md` referencia project_notes/

## Criterios de aceptación

- [ ] Existe `references/project-notes-guide.md` con estructura y convenciones
- [ ] Define 4 archivos (bugs, decisions, key_facts, issues) con formato concreto
- [ ] Aclara la diferencia con done-tasks, experience library, y .ai/decisions/
- [ ] `templates/orchestrator-prompt.md` consulta project_notes/ como contexto read-only
- [ ] No se crean archivos vacíos en `.ai/docs/project_notes/`

## NO hacer

- NUNCA crear los archivos dentro de `.ai/docs/project_notes/` — se crean cuando hay contenido real
- NUNCA hacer que el orquestador modifique project_notes — son read-only para el harness
- NUNCA duplicar el formato de `.ai/decisions/` — project_notes/decisions.md es para ADRs arquitectónicos, .ai/decisions/ es para decisiones de sprint

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
