# harden-01 — Contrato parseable con YAML frontmatter

## Objetivo

Agregar un bloque YAML frontmatter obligatorio al spec-template con campos estructurados que permitan validación determinística por preflight, auditoría y cierre.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: harden-02, harden-03, harden-04

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `references/reglas-specs.md`

### Archivos prohibidos
- `commands/preflight.md` — se actualiza en harden-04
- `templates/orchestrator-prompt.md` — se actualiza en harden-05
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- Ninguna

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar bloque YAML frontmatter al inicio del template, antes del heading `## Objetivo`. Mover campos existentes dispersos (Complejidad, Modo de ejecución, Clase de ejecución) al frontmatter. Mantener las secciones markdown existentes intactas. |
| `references/reglas-specs.md` | Agregar sección "Frontmatter obligatorio" que documente los campos YAML requeridos y sus tipos/valores válidos. |

## Archivos a crear

Ninguno.

---

## Subtareas

### Implementación directa — sin subdivisión

**Pasos:**
1. En `templates/spec-template.md`, agregar al inicio del archivo (después del heading H1) un bloque YAML frontmatter con estos campos obligatorios:
   ```yaml
   ---
   id: "[sprint-prefix]-[seq]"
   title: "[Título descriptivo]"
   goal: "[1-2 frases — mismo contenido que ## Objetivo]"
   complexity: Simple | Media | Alta
   execution_mode: Subagente | Sesion_principal
   execution_class: read_only | isolated_write | shared_write | repo_wide
   allowed_paths:
     - "ruta/exacta/archivo.py"
   denied_paths:
     - "ruta/config_produccion.py"
   dependencies:
     requires: [] | ["harden-01"]
     blocks: [] | ["harden-02"]
   closure_criteria:
     - "Criterio observable y verificable"
   required_validations:
     - "comando o check específico"
   max_attempts: 3
   ---
   ```
2. Mantener las secciones markdown existentes (`## Objetivo`, `## Scope fence`, etc.) como documentación expandida. El frontmatter es el contrato parseable; las secciones markdown son el detalle para el subagente.
3. Agregar un comentario HTML después del frontmatter explicando: "El frontmatter es la fuente de verdad para validación automática. Las secciones markdown expanden el detalle para el subagente ejecutor."
4. En `references/reglas-specs.md`, agregar sección `## Frontmatter obligatorio` con tabla de campos, tipos válidos y regla de que el preflight valida contra el frontmatter (no contra las secciones markdown).
5. Verificar que el template resultante sigue siendo legible y que el frontmatter no duplica información innecesariamente — los campos del frontmatter son los que se validan; las secciones markdown son las que el subagente lee para ejecutar.

**Tests:** No aplica (repo 100% markdown). Validación manual:
```bash
# Verificar que el frontmatter es YAML válido
head -50 templates/spec-template.md
```

- [ ] `estructura_frontmatter`: El bloque YAML tiene los 10 campos obligatorios (id, title, goal, complexity, execution_mode, execution_class, allowed_paths, denied_paths, closure_criteria, required_validations, max_attempts)
- [ ] `campos_tipados`: Cada campo tiene tipo/valores válidos documentados
- [ ] `template_legible`: El template resultante es legible y autocontenido

## Criterios de aceptación

- [ ] `templates/spec-template.md` tiene un bloque YAML frontmatter con los 10 campos obligatorios
- [ ] `references/reglas-specs.md` documenta los campos, tipos y valores válidos del frontmatter
- [ ] Los campos `complexity`, `execution_mode`, `execution_class` están en el frontmatter Y se removieron como headings sueltos del body (evitar duplicación)
- [ ] El comentario HTML de guía está presente después del frontmatter

## NO hacer

- NUNCA eliminar las secciones markdown existentes del template — el frontmatter complementa, no reemplaza
- NUNCA duplicar `allowed_paths` y `## Archivos permitidos` con contenido idéntico — el frontmatter tiene las rutas, la sección markdown puede tener comentarios/razones
- NUNCA agregar campos al frontmatter que no sean verificables por tooling (nada subjetivo como "riesgo: alto")

## Checklist de autocontención

- [x] Tiene scope fence (archivos permitidos + prohibidos)
- [x] Tiene dependencias de lectura listadas (Ninguna)
- [x] Tiene rutas EXACTAS de archivos a modificar/crear
- [x] Tiene pasos concretos (no "investigar" o "explorar")
- [x] Tiene comando exacto de tests
- [x] Tiene commit message definido (abajo)
- [x] Tiene criterios de aceptación observables
- [x] Tiene restricciones claras en forma imperativa
- [x] Tiene ≤10 restricciones totales
- [x] No depende de contexto que solo existe en la conversación

**Commit:** `"feat(harden-01): agregar YAML frontmatter parseable al spec-template"`
