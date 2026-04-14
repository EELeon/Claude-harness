# Entrega de ejecución

Cuando se prepara un batch de tickets (Pasos 1-6), se generan estos
artefactos en el repo montado:

```
repo-target/
├── .ai/
│   ├── standards/              # Harness de auditoría (ChatGPT) — NO tocar
│   ├── meta.md                 # Meta del proyecto (visión de alto nivel)
│   ├── specs/
│   │   ├── active/             # Specs del batch actual
│   │   │   ├── [prefix]-01-[slug].md
│   │   │   ├── [prefix]-02-[slug].md
│   │   │   └── ...
│   │   └── archive/            # Specs de batches pasados
│   │       └── [nombre-batch]/ # Se crea al archivar
│   ├── audit/                  # Artifacts de auditoría recursiva
│   │   ├── iteration-1/        # Una carpeta por iteración del loop
│   │   │   ├── raw-gaps.md     # Gaps encontrados por el auditor
│   │   │   ├── plan.md         # Plan priorizado de implementación
│   │   │   └── results.tsv     # Copia del results.tsv de esa iteración
│   │   └── summary.md          # Reporte final del loop recursivo
│   ├── runs/
│   │   ├── results.tsv         # Tracking (se crea vacío con header)
│   │   └── archive/            # results.tsv archivados por sprint
│   │       └── [nombre-batch].tsv
│   ├── prompts/                # UN archivo .md por batch — listo para pegar
│   │   └── [nombre-batch].md
│   ├── rules.md                # Reglas de orquestación (leídas de disco)
│   ├── plan.md                 # Plan de ejecución
│   └── done-tasks.md           # Se crea con el primer /learn
├── CLAUDE.md                   # Inamovible — Claude Code lo lee de acá
└── .claude/                    # Inamovible — Claude Code lo lee de acá
    ├── commands/
    ├── hooks/
    │   └── guard-destructive.sh
    └── settings.json
```

## Mapa de archivos: qué genera Cowork y dónde va

| Artefacto | Ruta exacta | Quién lo genera | Cuándo |
|-----------|-------------|-----------------|--------|
| Meta del proyecto | `.ai/meta.md` | Usuario + Cowork | Al iniciar proyecto |
| Gaps de auditoría | `.ai/audit/iteration-N/raw-gaps.md` | Subagente auditor | Por iteración del loop |
| Plan de auditoría | `.ai/audit/iteration-N/plan.md` | Subagente analista | Por iteración del loop |
| Resumen de auditoría | `.ai/audit/summary.md` | Orquestador | Al finalizar loop |
| Spec de ticket | `.ai/specs/active/[prefix]-[seq]-[slug].md` | Cowork (Paso 3) | Al preparar batch |
| Prompt de ejecución | `.ai/prompts/[nombre-batch].md` | Cowork (Paso 4) | Al preparar batch |
| Reglas de orquestación | `.ai/rules.md` | Cowork (Paso 4) | Al preparar batch |
| Plan de ejecución | `.ai/plan.md` | Cowork (Paso 5) | Al preparar batch |
| Guard destructivo | `.claude/hooks/guard-destructive.sh` | Cowork (Paso 5) | Primera vez |
| Tracking de resultados | `.ai/runs/results.tsv` | Claude Code (Regla 4) | Al ejecutar |
| Lecciones aprendidas | `.ai/done-tasks.md` | Claude Code (`/learn`) | Post-ticket |

**Regla de carpetas:** Antes de escribir cualquier archivo, crear la
carpeta destino si no existe con `mkdir -p`. Esto aplica tanto a Cowork
al generar artefactos como a Claude Code al archivar.

## Artefactos temporales vs permanentes

**Temporales (se archivan/borran al terminar):**
`.ai/specs/active/*`, `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv` (se archiva antes de borrar en `.ai/runs/archive/`)

**Permanentes (sobreviven entre ejecuciones):**
`.ai/meta.md`, `.ai/audit/*`, `.ai/done-tasks.md`, `.ai/prompts/*`,
`.ai/specs/archive/*`, `.ai/standards/`, `.ai/sprint-registry.md`,
`.ai/runs/archive/*` -- historial de results.tsv por sprint,
`CLAUDE.md`, `.claude/`

## Modelo de ejecución

**Una sola rama, un solo PR, todos los tickets en secuencia.**

Los puntos de corte son pausas para `/compact` o `/clear` — NO son
fronteras de git. Cada ticket termina con un commit atómico que incluye
el número de ticket, lo que permite revertir cualquier ticket
individualmente con `git revert` sin afectar al resto.

## Limpieza post-ejecución

Al finalizar, el orquestador archiva y limpia automáticamente
(paso 5 de "Al terminar todos los tickets" en .ai/rules.md).

**Comandos exactos (ejecutar en este orden):**

```bash
# 1. Crear carpeta de archivo si no existe
mkdir -p .ai/specs/archive/[nombre-batch]

# 1b. Registrar en sprint registry
# Si no existe, crear con header
if [ ! -f .ai/sprint-registry.md ]; then
  echo "# Sprint Registry" > .ai/sprint-registry.md
  echo "" >> .ai/sprint-registry.md
  echo "| Sprint | Rama | Fecha | PR | Tickets | Keep | Discard | Rollbacks | Results |" >> .ai/sprint-registry.md
  echo "|--------|------|-------|----|---------|------|---------|-----------|---------|" >> .ai/sprint-registry.md
fi
# Agregar fila (el orquestador calcula los valores leyendo results.tsv)
echo "| [sprint] | [rama] | [fecha] | #[pr] | [total] | [keep] | [discard] | [rollbacks] | .ai/runs/archive/[sprint].tsv |" >> .ai/sprint-registry.md

# 2. Mover specs al archivo
mv .ai/specs/active/* .ai/specs/archive/[nombre-batch]/

# 2b. Archivar results.tsv antes de borrar
mkdir -p .ai/runs/archive
cp .ai/runs/results.tsv .ai/runs/archive/[nombre-batch].tsv

# 3. Borrar artefactos temporales
rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv

# 4. Commit de limpieza
git add -A && git commit -m "chore: archivar specs y limpiar [nombre-batch]"
```

**NO borrar:**
- `.ai/done-tasks.md` — acumulativo entre ejecuciones
- `.ai/prompts/*` — historial permanente
- `.ai/standards/` — harness de auditoría
- `.ai/sprint-registry.md` — historial acumulativo de sprints
- `.ai/runs/archive/*` — historial de results.tsv por sprint
- `CLAUDE.md`, `.claude/` — infraestructura de Claude Code

## Instrucciones para el usuario

> **Para ejecutar:**
> 1. Pegar en Claude Code la línea que Cowork te dio:
>    `Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.`
> 2. El prompt ya incluye: crear rama, leer `.ai/rules.md`, ejecutar
>    cada ticket como subagente con commit atómico, y crear el PR al final.
> 3. Esperar ejecución autónoma y revisar el resumen final.
>
> Funciona igual desde Claude Code CLI (`claude`) o Claude Code Desktop.
>
> **Si un ticket falla durante la ejecución autónoma:**
> Claude Code lo reportará en el resumen. Podés corregirlo manualmente
> o correr `/next-ticket` para reintentar.
>
> **Para revertir un ticket específico sin afectar al resto:**
> ```bash
> git log --oneline --grep="T-[N]"
> git revert [hash] --no-edit
> ```
>
> **Para tickets sacados del prompt (excepcionalmente complejos):**
> 1. Ejecutar el prompt primero (tickets normales)
> 2. Después: `> Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.`
> 3. `> /learn ticket-[N] [título]`
