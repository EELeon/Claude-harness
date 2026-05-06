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
- SIEMPRE delegar subtareas independientes con `Agent` + `isolation: "worktree"`. Sin worktree los subagentes se pisan en el working tree.
- SIEMPRE particionar el trabajo por **directorios/archivos disjuntos**. **NO hay cap numérico de subagentes paralelos** — si los scopes son verdaderamente disjuntos, 5/10/20 subagentes simultáneos son seguros. Lanza tantos como haya trabajo independiente.
- Si hay archivos compartidos que múltiples subagentes necesitarían editar (ej. `core/enums.py`, registries, `config/*.yaml`, `Procfile`, schemas comunes): bundlear esas ediciones en **UN solo subagente** con justificación cruzada en el commit message ("agrupado por shared infra: A4 + A5 + A7 tocan capabilities.yaml"). Los demás subagentes referencian el resultado pero NO lo tocan.
- SIEMPRE scheduling continuo: cuando un subagente termina, evaluar inmediatamente si hay subtarea pendiente y lanzarla — NO esperar a que el resto del lote termine. Mantener el slot ocupado mientras haya trabajo en cola.
- Subtareas dependientes (la salida de A alimenta B) van secuenciales en el agente principal, no en subagentes.
- NO crear sub-subagentes (Claude Code no los soporta) — máximo 1 nivel de **profundidad** de delegación. El cap es de profundidad, NO de cantidad horizontal.

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
- Si el cambio requiere tocar un archivo en la lista **NO TOCAR** del scope fence (los protegidos explícitamente).
- Si descubres trabajo en progreso (ramas, archivos sin commitear) que no esperabas — investigar antes de sobrescribir.

### Expansión de scope mid-run (autorizada, sin pausa)
La lista "TOCAR" del scope fence es **expectativa razonable, no jaula**. Si necesitas tocar un archivo no listado pero tampoco en NO TOCAR para cumplir el objetivo, expande sin pausa: declara la razón en el commit message (`chore(scope+): ...`) y sigue. El objetivo manda. NO arregles bugs no relacionados encontrados de paso — esos van a `docs/pendientes/` o equivalente.

## Convenciones del repo
{{Idioma de docs/comentarios, formato de commit messages, nombres de ramas, etc.}}
