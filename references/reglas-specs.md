# Reglas de escritura de specs

Un spec debe permitir que Claude Code ejecute **sin preguntar nada**.
Si Claude Code tiene que "entender" o "explorar" antes de actuar,
el spec está incompleto.

## Límites empíricos para specs efectivos

- Máximo **10 constraints** por spec (más causa omisiones críticas)
- Target ~5000 tokens por spec (>5K = pérdida de fidelidad en instrucciones)
- Forma imperativa en restricciones: "NUNCA X", "SIEMPRE Y"
- Si hay dependencia fuerte con otro ticket, usar patrón Interface-First
  (definir contrato/stub compartido antes de implementar)

## Estructura obligatoria de cada spec

```markdown
# Ticket N — [Título]

## Objetivo (1-2 frases)

## Scope fence
### Archivos permitidos
- `ruta/exacta/archivo.py`
### Archivos prohibidos
- `ruta/config_prod.py` — razón

## Archivos a modificar
- `ruta/exacta/archivo.py` — qué cambiar

## Archivos a crear
- `ruta/exacta/nuevo.py` — qué contiene

## Subtareas (si aplica)
### Subtarea 1 — [nombre]
**Archivos:** [lista]
**Pasos:** [paso a paso concreto]
**Tests:** `[comando exacto]`
**Commit:** `"[tipo]: descripción"`

## Tests que deben pasar
- [ ] Test 1: descripción exacta
- [ ] Test 2: descripción exacta

## Criterios de aceptación
- [ ] Criterio observable 1
- [ ] Criterio observable 2

## NO hacer
- NUNCA [restricción 1 — por qué]
- NUNCA [restricción 2 — por qué]
```

## Frontmatter obligatorio

Cada spec DEBE iniciar con un bloque YAML frontmatter (delimitado por `---`) inmediatamente después del heading H1. El frontmatter es la **fuente de verdad para validación automática** — el preflight valida contra el frontmatter, no contra las secciones markdown.

| Campo | Tipo | Valores válidos | Descripción |
|-------|------|----------------|-------------|
| `id` | string | `"[sprint-prefix]-[seq]"` | Identificador único del ticket (ej: `"harden-01"`) |
| `title` | string | texto libre | Título descriptivo del ticket |
| `goal` | string | 1-2 frases | Mismo contenido que `## Objetivo` |
| `complexity` | enum | `Simple` \| `Media` \| `Alta` | Complejidad estimada |
| `execution_mode` | enum | `Subagente` \| `Sesion_principal` | Cómo se ejecuta el ticket |
| `execution_class` | enum | `read_only` \| `isolated_write` \| `shared_write` \| `repo_wide` | Clase de concurrencia |
| `allowed_paths` | list[string] | rutas exactas de archivos | Archivos que el ticket puede modificar |
| `denied_paths` | list[string] | rutas exactas de archivos | Archivos que NUNCA deben tocarse |
| `dependencies.requires` | list[string] | IDs de tickets o `[]` | Tickets que deben completarse antes |
| `dependencies.blocks` | list[string] | IDs de tickets o `[]` | Tickets que este bloquea |
| `closure_criteria` | list[string] | criterios observables | Condiciones verificables para cerrar el ticket |
| `required_validations` | list[string] | comandos o checks | Validaciones que deben pasar antes de cerrar |
| `max_attempts` | integer | `1`-`5` (default: `3`) | Intentos máximos antes de escalar |

**Reglas:**
- SIEMPRE incluir los 10 campos obligatorios (id, title, goal, complexity, execution_mode, execution_class, allowed_paths, denied_paths, closure_criteria, required_validations) + dependencies + max_attempts
- NUNCA duplicar `complexity`, `execution_mode` o `execution_class` como headings sueltos en el body — solo viven en el frontmatter
- NUNCA agregar campos subjetivos al frontmatter (nada que no sea verificable por tooling)
- Las secciones markdown (`## Objetivo`, `## Scope fence`, etc.) expanden el detalle para el subagente ejecutor; el frontmatter es el contrato parseable

## Referencia

Para la plantilla completa con todos los campos opcionales y
ejemplos detallados, leer `templates/spec-template.md`.
