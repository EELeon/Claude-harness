# contratos-operativos-v1

## Setup inicial
1. Creá la rama: `git checkout -b feat/contratos-operativos-v1`
2. Lee las reglas de orquestación en `.ai/rules.md` y seguílas estrictamente.

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | T-1 — Result Budgeting formal | `.ai/specs/active/ticket-1.md` | Simple |
| 2 | T-2 — Clases de ejecución formal | `.ai/specs/active/ticket-2.md` | Simple |
| 3 | T-3 — Optimización de tokens | `.ai/specs/active/ticket-3.md` | Simple |
| 4 | T-4 — Recovery Matrix | `.ai/specs/active/ticket-4.md` | Simple |

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/ticket-[N].md`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, corré los tests, y hacé un commit atómico con el número de ticket en el mensaje. Devolvé: resumen (1-3 líneas), hash del commit, estado de tests (passed/failed), lista de archivos tocados, y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NO devuelvas logs completos ni output de tests.
2. Después del subagente, aplicá Reglas 2 + 2b + 2c (scope → tests → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn contratos-operativos-v1 completo`
2. Creá el PR: `gh pr create --title "feat: contratos operativos v1 — result budgeting, execution classes, token optimization, recovery matrix" --body "$(cat .ai/runs/results.tsv)"`
