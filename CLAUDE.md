# Code Orchestrator — Plugin de orquestación para Claude Code

## Qué es
Plugin que convierte tickets/tareas en specs autocontenidos y ejecuta sprints autónomos con Claude Code. Todo el estado vive en disco (`.ai/`), los prompts son lean, y cada ticket produce un commit atómico revertible.

## Estructura
```
skills/           # 7 skills invocables desde Cowork (orchestrate, bootstrap, etc.)
commands/         # 8 comandos Claude Code (/learn, /status, /preflight, etc.)
references/       # Documentación de arquitectura y flujos
templates/        # Plantillas para specs, prompts, CLAUDE.md, meta, hooks
.ai/              # Estado de ejecución (specs, runs, audit, prompts)
.claude/          # Commands instalados + hooks + settings
```

## Comandos esenciales
```bash
# No hay build/test/lint — el repo es 100% markdown
# Validar specs antes de sprint
# /preflight

# Ver estado del sprint
# /status

# Capturar lecciones post-ticket
# /learn [ticket] [título]
```

## Convenciones
- SIEMPRE escribir en español (docs, specs, prompts, comments)
- SIEMPRE usar forma imperativa en reglas: "NUNCA X" / "SIEMPRE Y"
- NUNCA copiar templates sin adaptar al contexto del repo target
- SIEMPRE mantener specs autocontenidos — el subagente NO tiene acceso a meta ni plan
- NUNCA crear agentes custom sin evidencia de 3+ errores repetidos del mismo tipo

## Reglas de dominio
- NUNCA exceder 100 líneas en CLAUDE.md de repos target — simplicidad > exhaustividad
- Tickets triviales (≤5 archivos, cambio mecánico) van como INLINE en el prompt — sin spec completo
- Sub-subagentes: NO soportados por Claude Code (constraint de plataforma, no regla de diseño) — máximo 1 nivel
- SIEMPRE persistir estado a disco antes de /clear o reset — el disco es la fuente de verdad
- Un spec SIEMPRE tiene: objetivo, scope fence, archivos, tests, criterios de aceptación, commit message
- El ledger (.ai/runs/results.tsv) es la fuente de verdad — SIEMPRE registrar
- NUNCA pedir /compact manualmente — Claude Code auto-compacta cuando hace falta
- Re-leer archivos solo si (a) se modificaron después de la última lectura o (b) hay duda razonable del estado — confiar en lo ya leído cuando aplique

## NO hacer
- NUNCA bloquear `git reset --hard` en hooks — el orchestrator lo usa para rollback
- NUNCA ejecutar sprint si algún spec tiene FAIL en preflight
- NUNCA archivar specs antes de que el sprint termine completo
- NUNCA crear .ai/done-tasks.md manualmente — se crea con el primer /learn

## Intentos fallidos
<!-- Se actualiza con /learn después de cada ticket -->

## Workflow
- SIEMPRE empezar leyendo el spec en `.ai/specs/active/ticket-N.md`
- SIEMPRE usar subagentes para subtareas marcadas en el spec
- SIEMPRE commit atómico después de cada subtarea
- SIEMPRE correr validación antes de marcar como completado
- Ejecutar `/learn` SOLO si el ticket tuvo problemas (rollback, >1 intento, desviaciones). Un /learn al final del sprint para lo general
- Si se usa prompt del sprint: el orquestador maneja transiciones + checkpoint dinámico entre tickets
- Si se ejecuta manualmente: `/clear` entre tickets para contexto fresco
