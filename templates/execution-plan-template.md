# Template para .ai/plan.md

<!-- Este archivo se genera junto con los specs y se commitea al repo como .ai/plan.md -->

# Plan de Ejecución — [Nombre del batch]

Generado: [fecha]
Total tickets: [N]
Sprints: [N]

## Orden de ejecución

| # | Ticket | Título | Sprint | Complejidad | Modo | Subtareas | Estado |
|---|--------|--------|--------|-------------|------|-----------|--------|
| 1 | T-[N]  | [título] | A | [S/M/A] | Subagente | [N] | ⬜ |
| 2 | T-[N]  | [título] | A | [S/M/A] | Subagente | [N] | ⬜ |
| 3 | T-[N]  | [título] | B | Alta | Sesión principal | [N] | ⬜ |

<!--
Estados: ⬜ pendiente | 🔄 en progreso | ✅ completado | ❌ bloqueado

Modo de ejecución:
  Subagente (default): corre dentro del prompt del sprint como subagente.
  Sesión principal: corre fuera del prompt del sprint, directamente en el
    contexto principal de Claude Code. Usar SOLO cuando el ticket
    es de complejidad Alta + tiene 4 subtareas de 5+ archivos cada una.
    Estos tickets necesitan lanzar sus propios subagentes internos,
    lo cual no es posible si ya corren como subagente.
-->

## Sprints

### Sprint A — [Nombre temático]
- **Rama:** `sprint-a-[nombre]`
- **Tickets:** T-[N], T-[N], T-[N]
- **Dependencias internas:** T-[X] antes de T-[Y]
- **Prompt:** `.ai/prompts/sprint-a.md`
- **Tickets fuera del prompt:** [ninguno | T-[N] (razón)]

### Sprint B — [Nombre temático]
- **Rama:** `sprint-b-[nombre]`
- **Tickets:** T-[N], T-[N]
- **Dependencias:** Requiere Sprint A mergeado
- **Prompt:** `.ai/prompts/sprint-b.md`
- **Tickets fuera del prompt:** [ninguno | T-[N] (razón)]

<!-- Repetir por sprint -->

---

## Ejecución — líneas para Claude Code

<!--
Los prompts ya NO están embebidos en este archivo.
Cada sprint tiene su propio archivo en .ai/prompts/sprint-[letra].md.
El usuario solo pega la línea correspondiente en Claude Code.
-->

```
# Sprint A
Lee .ai/prompts/sprint-a.md y ejecutá el Sprint A completo.

# Sprint B (después de mergear Sprint A)
Lee .ai/prompts/sprint-b.md y ejecutá el Sprint B completo.

# Tickets fuera del prompt (excepcionalmente complejos)
Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.
```

## Fallback: ejecución manual (si el prompt del sprint falla)

Si la ejecución autónoma falla a mitad del sprint:
1. Revisar qué tickets ya se completaron: `/status`
2. Para el ticket que falló: `/next-ticket` (ejecuta el siguiente pendiente)
3. Después de corregir: `/learn ticket-[N] [título]`
4. `/clear` y continuar con `/next-ticket`

---

## Infraestructura instalada

### Comandos

| Comando | Archivo | Propósito |
|---------|---------|-----------|
| `/learn` | `.claude/commands/learn.md` | Captura lecciones en `.ai/done-tasks.md` |
| `/next-ticket` | `.claude/commands/next-ticket.md` | Inicia siguiente ticket pendiente |
| `/status` | `.claude/commands/status.md` | Muestra progreso del sprint |
| `/preflight` | `.claude/commands/preflight.md` | Validación pre-ejecución de specs |

### Estructura .ai/

```
.ai/
├── standards/           # Harness de auditoría (ChatGPT) — no tocar
├── specs/
│   ├── active/          # Specs del sprint actual
│   └── archive/         # Specs de sprints pasados
│       └── sprint-A/    # mkdir -p al archivar
├── runs/
│   └── results.tsv      # Tracking del sprint actual
├── prompts/             # UN archivo por sprint (permanente)
│   ├── sprint-a.md
│   └── sprint-b.md
├── rules.md             # Reglas de orquestación (temporal, se borra post-sprint)
├── plan.md              # Este archivo (temporal, se borra post-sprint)
└── done-tasks.md        # Lecciones acumulativas (NO borrar)
```

### Guard destructivo (PreToolUse hook)

- **Archivo:** `.claude/settings.json`
- **Tipo:** PreToolUse — bloquea comandos destructivos (`rm -rf`, `git push --force`)
- **Nota:** Compatible con rollback de Regla 2 (no bloquea `git reset --hard`)

### Tracking de resultados (dos archivos)

**`.ai/runs/results.tsv`** — Escrito por el orquestador. Tracking estructurado
para retomar sprints después de `/clear` y para análisis de /retrospective.
```
ticket	commit	tests	status	failure_category	description
T-1	a1b2c3d	passed	keep	none	block por nivel con tabla y capa DXF
T-5	c3d4e5f	failed	discard	test_failure	capas eléctricas — tests fallaron
T-5	d4e5f6g	passed	keep	none	capas eléctricas — fix aplicado
T-8	0000000	crash	discard	scope_violation	motor DXF — tocó config global
```

**`.ai/done-tasks.md`** — Escrito por `/learn`. Lecciones narrativas
para humanos y para que `/retrospective` analice.
```
## [fecha] — Ticket [N]: [título]
- Subtareas completadas: [lista]
- Tests: [pasaron/fallaron]
- Lecciones: [resumen de 1 línea]
- Reglas nuevas en CLAUDE.md: [N agregadas, N modificadas, N eliminadas]
```

Ambos archivos se commitean al repo.

---

## Infraestructura diferida (evaluar después del Sprint 1)

| Componente | Archivo | Cuándo instalar |
|------------|---------|----------------|
| `/retrospective` | `.claude/commands/retrospective.md` | Después del primer sprint completo |
| Hook anti-racionalización (Stop) | `.claude/settings.json` | Si Claude declara victoria prematura durante ejecución |
| Agentes custom | `.claude/agents/[nombre].md` | Si `/learn` detecta el mismo tipo de error 3+ veces en un dominio |
