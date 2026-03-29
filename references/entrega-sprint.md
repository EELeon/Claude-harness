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
Se generan cuando hay trabajo real que ejecutar.

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

## Instrucciones para el usuario

> **Para ejecutar un sprint:**
> 1. `git checkout -b sprint-[X]-[nombre]`
> 2. `claude`
> 3. Pegar el prompt del sprint (está en EXECUTION_PLAN.md — es lean, ~1-2K tokens)
> 4. El orquestador lee ORCHESTRATOR_RULES.md y cada subagente lee su spec de disco
> 5. Esperar a que Claude Code termine todos los tickets
> 6. Revisar el resumen final
> 7. `gh pr create --title "Sprint [X]: [nombre]"`
>
> **Si un ticket falla durante la ejecución autónoma:**
> Claude Code lo reportará en el resumen. Podés corregirlo manualmente
> o correr `/next-ticket` para reintentar.
>
> **Para tickets sacados del prompt (excepcionalmente complejos):**
> 1. Ejecutar el prompt del sprint primero (tickets normales)
> 2. Después: `> Lee specs/ticket-[N].md e impleméntalo. Usa subagents.`
> 3. `> /learn ticket-[N] [título]`
