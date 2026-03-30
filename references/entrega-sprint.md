# Entrega de sprint

Cuando se prepara un sprint (Pasos 1-6), se generan estos artefactos
en el repo montado:

```
repo-target/
├── specs/
│   ├── ticket-1.md
│   ├── ticket-2.md
│   └── ...
├── ORCHESTRATOR_RULES.md        # Reglas de orquestación (leídas de disco)
├── EXECUTION_PLAN.md            # Plan + prompts lean por sprint
├── results.tsv                  # Tracking (se crea vacío con header)
└── done-tasks.md                # Se crea con el primer /learn
```

Estos archivos son **artefactos de sprint**, no scaffold permanente.
Se generan cuando hay trabajo real que ejecutar y se borran al final
del sprint (ver "Limpieza" abajo).

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

## Limpieza post-sprint

Al finalizar el sprint, el orquestador borra automáticamente los
artefactos que ya no sirven (paso 5 de "Al terminar todos los tickets"
en ORCHESTRATOR_RULES.md):

- **Se borran:** `specs/`, `ORCHESTRATOR_RULES.md`, `EXECUTION_PLAN.md`, `results.tsv`
- **Se conservan:** `done-tasks.md` (acumulativo entre sprints), `CLAUDE.md`, `.claude/`

Esto mantiene el repo limpio entre sprints. Los próximos specs se
regeneran desde cero cuando hay nuevos tickets.

## Instrucciones para el usuario

> **Para ejecutar un sprint:**
> 1. Pegar el prompt del sprint (está en EXECUTION_PLAN.md — es lean, ~1-2K tokens)
> 2. El prompt ya incluye: crear rama, leer ORCHESTRATOR_RULES.md, ejecutar
>    cada ticket como subagente leyendo su spec de `specs/ticket-N.md`,
>    y crear el PR con `gh` al final.
> 3. Esperar ejecución autónoma y revisar el resumen final.
>
> Funciona igual desde Claude Code CLI (`claude`) o Claude Code Desktop.
>
> **Si un ticket falla durante la ejecución autónoma:**
> Claude Code lo reportará en el resumen. Podés corregirlo manualmente
> o correr `/next-ticket` para reintentar.
>
> **Para tickets sacados del prompt (excepcionalmente complejos):**
> 1. Ejecutar el prompt del sprint primero (tickets normales)
> 2. Después: `> Lee specs/ticket-[N].md e impleméntalo. Usa subagents.`
> 3. `> /learn ticket-[N] [título]`
