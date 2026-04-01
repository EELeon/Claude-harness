# Entrega de sprint

Cuando se prepara un sprint (Pasos 1-6), se generan estos artefactos
en el repo montado:

```
repo-target/
├── .ai/
│   ├── standards/              # Harness de auditoría (ChatGPT) — NO tocar
│   ├── specs/
│   │   ├── active/             # Specs del sprint actual
│   │   │   ├── ticket-1.md
│   │   │   ├── ticket-2.md
│   │   │   └── ...
│   │   └── archive/            # Specs de sprints pasados (historial)
│   ├── runs/
│   │   └── results.tsv         # Tracking (se crea vacío con header)
│   ├── prompts/                # Prompts lean archivados
│   ├── rules.md                # Reglas de orquestación (leídas de disco)
│   ├── plan.md                 # Plan + prompts lean por sprint
│   └── done-tasks.md           # Se crea con el primer /learn
├── CLAUDE.md                   # Inamovible — Claude Code lo lee de acá
└── .claude/                    # Inamovible — Claude Code lo lee de acá
    ├── commands/
    └── settings.json
```

Los archivos bajo `.ai/specs/active/`, `.ai/rules.md`, `.ai/plan.md`
y `.ai/runs/results.tsv` son **artefactos de sprint**. Se generan
cuando hay trabajo real y se archivan/borran al finalizar el sprint.

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

## Limpieza post-sprint

Al finalizar el sprint, el orquestador archiva y limpia automáticamente
(paso 5 de "Al terminar todos los tickets" en .ai/rules.md):

- **Se archivan:** `.ai/specs/active/*` → `.ai/specs/archive/sprint-[LETRA]/`
- **Se borran:** `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv`
- **Se conservan:** `.ai/done-tasks.md` (acumulativo), `.ai/standards/`, `CLAUDE.md`, `.claude/`

## Instrucciones para el usuario

> **Para ejecutar un sprint:**
> 1. Pegar el prompt del sprint (está en `.ai/plan.md` — es lean, ~1-2K tokens)
> 2. El prompt ya incluye: crear rama, leer `.ai/rules.md`, ejecutar
>    cada ticket como subagente leyendo su spec de `.ai/specs/active/ticket-N.md`,
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
> 2. Después: `> Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.`
> 3. `> /learn ticket-[N] [título]`
