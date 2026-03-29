# Template para EXECUTION_PLAN.md

<!-- Este archivo se genera junto con los specs y se commitea al repo -->

# Plan de Ejecución — [Nombre del batch]

Generado: [fecha]
Total tickets: [N]
Sprints: [N]

## Orden de ejecución

| # | Ticket | Título | Sprint | Complejidad | Subtareas | Estado |
|---|--------|--------|--------|-------------|-----------|--------|
| 1 | T-[N]  | [título] | A | [S/M/A] | [N] | ⬜ |
| 2 | T-[N]  | [título] | A | [S/M/A] | [N] | ⬜ |

<!-- Estados: ⬜ pendiente | 🔄 en progreso | ✅ completado | ❌ bloqueado -->

## Sprints

### Sprint A — [Nombre temático]
- **Rama:** `sprint-a-[nombre]`
- **Tickets:** T-[N], T-[N], T-[N]
- **Dependencias internas:** T-[X] antes de T-[Y]
- **Sesiones estimadas:** [N] (con /clear entre tickets)

### Sprint B — [Nombre temático]
- **Rama:** `sprint-b-[nombre]`
- **Tickets:** T-[N], T-[N]
- **Dependencias:** Requiere Sprint A mergeado
- **Sesiones estimadas:** [N]

<!-- Repetir por sprint -->

## Instrucciones de ejecución

```bash
# Sprint A
git checkout -b sprint-a-[nombre]
claude
# Dentro de Claude Code:
#   > /next-ticket
#   > /learn ticket-N [título]
#   > /clear
#   > (repetir)
gh pr create --title "Sprint A: [nombre]"

# Sprint B (después de mergear Sprint A)
git checkout main && git pull
git checkout -b sprint-b-[nombre]
claude
# ...
```

## Agentes custom instalados

| Agente | Archivo | Dominio |
|--------|---------|---------|
| [nombre] | `.claude/agents/[nombre].md` | [dominio] |

## Comandos instalados

| Comando | Archivo | Propósito |
|---------|---------|-----------|
| `/learn` | `.claude/commands/learn.md` | Captura lecciones post-ticket |
| `/next-ticket` | `.claude/commands/next-ticket.md` | Inicia siguiente ticket |
| `/status` | `.claude/commands/status.md` | Muestra progreso del sprint |
