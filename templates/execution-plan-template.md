# Template para .ai/plan.md

<!-- Este archivo se genera junto con los specs y se commitea al repo como .ai/plan.md -->

# Plan de Ejecución — [Nombre del batch]

Generado: [fecha]
Total tickets: [N]
Rama: `[nombre-rama]`

## Orden de ejecución

| # | Ticket | Título | Complejidad | Modo | Subtareas | Estado |
|---|--------|--------|-------------|------|-----------|--------|
| 1 | T-[N]  | [título] | [S/M/A] | Subagente | [N] | ⬜ |
| 2 | T-[N]  | [título] | [S/M/A] | Subagente | [N] | ⬜ |
| 3 | T-[N]  | [título] | [S/M/A] | Subagente | [N] | ⬜ |
| — | **PUNTO DE CORTE** | /compact o /clear | — | — | — | — |
| 4 | T-[N]  | [título] | Alta | Subagente | [N] | ⬜ |
| 5 | T-[N]  | [título] | [S/M/A] | Sesión principal | [N] | ⬜ |

<!--
Estados: ⬜ pendiente | 🔄 en progreso | ✅ completado | ❌ bloqueado

Modo de ejecución:
  Subagente (default): corre como subagente dentro del prompt.
  Sesión principal: corre fuera del prompt, directamente en el
    contexto principal de Claude Code. Usar SOLO cuando el ticket
    es de complejidad Alta + tiene 4 subtareas de 5+ archivos cada una.
    Estos tickets necesitan lanzar sus propios subagentes internos,
    lo cual no es posible si ya corren como subagente.

Puntos de corte: pausas para /compact o /clear. NO son fronteras de git.
Toda la ejecución ocurre en una sola rama y un solo PR.
-->

## Dependencias

- T-[X] antes de T-[Y] — [razón]
- T-[Z] independiente

## Tickets fuera del prompt

[ninguno | T-[N] — razón: complejidad Alta + 4 subtareas de 5+ archivos]

---

## Ejecución — línea para Claude Code

<!--
El prompt vive en .ai/prompts/[nombre-batch].md como archivo independiente.
El usuario solo pega esta línea en Claude Code.
-->

```
Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.
```

Para tickets fuera del prompt (excepcionalmente complejos):
```
Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.
```

## Fallback: ejecución manual

Si la ejecución autónoma falla a mitad:
1. Revisar qué tickets ya se completaron: `/status`
2. Para el ticket que falló: `/next-ticket` (ejecuta el siguiente pendiente)
3. Después de corregir: `/learn ticket-[N] [título]`
4. `/clear` y continuar con `/next-ticket`

## Rollback de un ticket específico

Cada ticket tiene un commit atómico con el número de ticket en el mensaje.
Para revertir un ticket sin afectar al resto:
```bash
# Encontrar el commit del ticket
git log --oneline --grep="T-[N]"
# Revertir solo ese commit
git revert [hash] --no-edit
```

---

## Infraestructura instalada

### Comandos

| Comando | Archivo | Propósito |
|---------|---------|-----------|
| `/learn` | `.claude/commands/learn.md` | Captura lecciones en `.ai/done-tasks.md` |
| `/next-ticket` | `.claude/commands/next-ticket.md` | Inicia siguiente ticket pendiente |
| `/status` | `.claude/commands/status.md` | Muestra progreso |
| `/preflight` | `.claude/commands/preflight.md` | Validación pre-ejecución de specs |
| `/validate-meta` | `.claude/commands/validate-meta.md` | Validación del documento meta |
| `/recursive-audit` | `.claude/commands/recursive-audit.md` | Loop recursivo de auditoría contra meta |

### Estructura .ai/

```
.ai/
├── standards/           # Harness de auditoría (ChatGPT) — no tocar
├── meta.md              # Meta del proyecto (permanente) — visión de alto nivel
├── specs/
│   ├── active/          # Specs del batch actual
│   └── archive/         # Specs de batches pasados
│       └── [nombre]/    # mkdir -p al archivar
├── audit/               # Artifacts de auditoría recursiva (permanente)
│   ├── iteration-N/     # Una carpeta por iteración
│   │   ├── raw-gaps.md  # Gaps encontrados
│   │   ├── plan.md      # Plan priorizado
│   │   └── results.tsv  # Copia del tracking
│   └── summary.md       # Reporte final del loop
├── runs/
│   └── results.tsv      # Tracking (temporal, se borra post-ejecución)
├── prompts/             # UN archivo por batch (permanente)
│   └── [nombre-batch].md
├── rules.md             # Reglas de orquestación (temporal)
├── plan.md              # Este archivo (temporal)
└── done-tasks.md        # Lecciones acumulativas (NO borrar)
```

### Guard destructivo (PreToolUse hook)

- **Script:** `.claude/hooks/guard-destructive.sh`
- **Config:** `.claude/settings.json`
- **Tipo:** PreToolUse — bloquea comandos destructivos (`rm -rf`, `git push --force`)
- **Nota:** Compatible con rollback de Regla 2 (no bloquea `git reset --hard`)

### Tracking de resultados (dos archivos)

**`.ai/runs/results.tsv`** — Escrito por el orquestador. Tracking estructurado
para retomar después de `/clear` y para análisis de /retrospective.
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

## Infraestructura diferida (evaluar después de la primera ejecución)

| Componente | Archivo | Cuándo instalar |
|------------|---------|----------------|
| `/retrospective` | `.claude/commands/retrospective.md` | Después de la primera ejecución completa |
| Hook anti-racionalización (Stop) | `.claude/settings.json` | Si Claude declara victoria prematura durante ejecución |
| Agentes custom | `.claude/agents/[nombre].md` | Si `/learn` detecta el mismo tipo de error 3+ veces en un dominio |
