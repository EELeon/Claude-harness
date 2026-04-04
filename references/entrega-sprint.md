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
│   │   └── archive/            # Specs de sprints pasados
│   │       └── sprint-A/       # Se crea al archivar Sprint A
│   ├── runs/
│   │   └── results.tsv         # Tracking (se crea vacío con header)
│   ├── prompts/                # UN archivo .md por sprint — listo para pegar
│   │   ├── sprint-a.md         # Prompt lean del Sprint A
│   │   ├── sprint-b.md         # Prompt lean del Sprint B
│   │   └── ...
│   ├── rules.md                # Reglas de orquestación (leídas de disco)
│   ├── plan.md                 # Plan de ejecución (sin prompts embebidos)
│   └── done-tasks.md           # Se crea con el primer /learn
├── CLAUDE.md                   # Inamovible — Claude Code lo lee de acá
└── .claude/                    # Inamovible — Claude Code lo lee de acá
    ├── commands/
    └── settings.json
```

## Mapa de archivos: qué genera Cowork y dónde va

| Artefacto | Ruta exacta | Quién lo genera | Cuándo |
|-----------|-------------|-----------------|--------|
| Spec de ticket | `.ai/specs/active/ticket-N.md` | Cowork (Paso 3) | Al preparar sprint |
| Prompt de sprint | `.ai/prompts/sprint-[letra].md` | Cowork (Paso 4) | Al preparar sprint |
| Reglas de orquestación | `.ai/rules.md` | Cowork (Paso 4) | Al preparar sprint |
| Plan de ejecución | `.ai/plan.md` | Cowork (Paso 5) | Al preparar sprint |
| Tracking de resultados | `.ai/runs/results.tsv` | Claude Code (Regla 4) | Al ejecutar sprint |
| Lecciones aprendidas | `.ai/done-tasks.md` | Claude Code (`/learn`) | Post-ticket |

**Regla de carpetas:** Antes de escribir cualquier archivo, crear la
carpeta destino si no existe con `mkdir -p`. Esto aplica tanto a Cowork
al generar artefactos como a Claude Code al archivar.

## Artefactos temporales vs permanentes

**Temporales (se archivan/borran al terminar el sprint):**
`.ai/specs/active/*`, `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv`

**Permanentes (sobreviven entre sprints):**
`.ai/done-tasks.md`, `.ai/prompts/*`, `.ai/specs/archive/*`,
`.ai/standards/`, `CLAUDE.md`, `.claude/`

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

## Limpieza post-sprint

Al finalizar el sprint, el orquestador archiva y limpia automáticamente
(paso 5 de "Al terminar todos los tickets" en .ai/rules.md).

**Comandos exactos (ejecutar en este orden):**

```bash
# 1. Crear carpeta de archivo si no existe
mkdir -p .ai/specs/archive/sprint-[LETRA]

# 2. Mover specs activos al archivo
mv .ai/specs/active/* .ai/specs/archive/sprint-[LETRA]/

# 3. Borrar artefactos temporales del sprint
rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv

# 4. Commit de limpieza
git add -A && git commit -m "chore: archivar specs y limpiar sprint [LETRA]"
```

**NO borrar:**
- `.ai/done-tasks.md` — acumulativo entre sprints
- `.ai/prompts/*` — historial de prompts, permanente
- `.ai/standards/` — harness de auditoría
- `CLAUDE.md`, `.claude/` — infraestructura de Claude Code

## Instrucciones para el usuario

> **Para ejecutar un sprint:**
> 1. Pegar en Claude Code la línea que Cowork te dio, por ejemplo:
>    `Lee .ai/prompts/sprint-a.md y ejecutá el Sprint A completo.`
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
