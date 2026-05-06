# {{NOMBRE_DEL_REPO}}

> Plantilla del harness v5. Adapta las secciones marcadas con `{{...}}` y borra esta línea.

## Stack
- Lenguaje: {{lenguaje}}
- Test: `{{comando_test}}`
- Lint/typecheck: `{{comando_lint}}`
- Build (si aplica): `{{comando_build}}`

## Cómo trabajar en este repo

### Planificación
- SIEMPRE usar TodoWrite si el goal tiene >3 pasos. Marcar completado uno a uno, no en lote.
- Si el goal es ambiguo o el scope no está claro, preguntar antes de empezar — no asumir.

### Paralelización
- SIEMPRE delegar subtareas independientes con `Agent` + `isolation: "worktree"` cuando tocan archivos distintos. Sin worktree los subagentes se pisan en el working tree.
- SIEMPRE scheduling continuo: cuando un subagente termina, evaluar inmediatamente si hay subtarea pendiente y lanzarla — NO esperar a que el resto del lote termine. Mantener el slot ocupado mientras haya trabajo en cola.
- Subtareas dependientes (la salida de A alimenta B) van secuenciales en el agente principal, no en subagentes.
- NO crear sub-subagentes (Claude Code no los soporta) — máximo 1 nivel de delegación.

### Iteración hasta convergencia
- Si el goal pide iterar hasta que algo pase ("hasta que los tests pasen", "hasta que el lint quede limpio"), usar `/loop` con auto-pacing en vez de un único turn largo.
- Si el goal es one-shot (un cambio acotado), no entrar en loop.

### Commits y rollback
- SIEMPRE commit atómico por subtarea — un commit revertible por unidad de trabajo.
- Rollback es `git reset --hard HEAD~N` sobre commits del run actual. NO hay ledger; git log es la fuente de verdad.
- Si una subtarea falla irrecuperablemente, revertir su commit y reportar — no apilar fixes sobre código roto.

### Scope fence
- Out-of-bounds (no tocar sin permiso explícito): {{rutas_protegidas, ej: migrations/, infra/}}
- Comandos vetados sin confirmación: {{comandos_destructivos_específicos_del_repo}}

### Cuándo abortar y pedir ayuda
- Si después de 2 intentos un test sigue fallando por la misma razón.
- Si el cambio requiere tocar algo fuera del scope fence.
- Si descubres trabajo en progreso (ramas, archivos sin commitear) que no esperabas — investigar antes de sobrescribir.

## Convenciones del repo
{{Idioma de docs/comentarios, formato de commit messages, nombres de ramas, etc.}}
