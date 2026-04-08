# infraestructura-estado-v2

## Setup inicial
1. Creá la rama: `git checkout -b feat/infraestructura-estado-v2`
2. Lee las reglas de orquestación en `.ai/rules.md` y seguílas estrictamente.
3. **Verificación de prerequisitos:** Confirmá que estos archivos existen (fueron creados por Sprint P1):
   - `references/output-budgets.md`
   - `references/concurrency-classes.md`
   - `references/token-optimization.md`
   - `references/recovery-matrix.md`
   Si alguno falta, PARÁ y reportá: "Sprint P1 incompleto — falta [archivo]"

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | T-5 — Política de compactación 3 niveles | `.ai/specs/active/ticket-5.md` | Media |
| 2 | T-6 — Task Locks en disco | `.ai/specs/active/ticket-6.md` | Media |
| 3 | T-7 — Experience Library | `.ai/specs/active/ticket-7.md` | Media |
| 4 | T-8 — Decision Capture Pipeline MVP | `.ai/specs/active/ticket-8.md` | Media |

### --- PUNTO DE CORTE (después de T-6) ---
Antes de continuar con T-7, ejecutá la Regla 5 de .ai/rules.md

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/ticket-[N].md`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, corré los tests, y hacé un commit atómico con el número de ticket en el mensaje. Devolvé: resumen (1-3 líneas), hash del commit, estado de tests (passed/failed), lista de archivos tocados, y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NO devuelvas logs completos ni output de tests.
2. Después del subagente, aplicá Reglas 2 + 2b + 2c (scope → tests → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn infraestructura-estado-v2 completo`
2. Creá el PR: `gh pr create --title "feat: infraestructura de estado v2 — compactación, locks, experience library, decision capture" --body "$(cat .ai/runs/results.tsv)"`
