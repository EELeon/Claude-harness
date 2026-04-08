# refinamiento-evolucion-v3

## Setup inicial
1. Creá la rama: `git checkout -b feat/refinamiento-evolucion-v3`
2. Lee las reglas de orquestación en `.ai/rules-v3.md` y seguílas estrictamente.
3. **Verificación de prerequisitos:** Confirmá que estos archivos existen (creados por P1 y P2):
   - `references/output-budgets.md`
   - `references/concurrency-classes.md`
   - `references/recovery-matrix.md`
   - `references/compaction-policy.md`
   - `references/experience-library.md`
   - `references/decision-capture.md`
   - `references/task-locks.md`
   Si alguno falta, PARÁ y reportá: "Sprint P1/P2 incompleto — falta [archivo]"

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | T-10 — Perfiles de permiso | `.ai/specs/active/ticket-10.md` | Simple |
| 2 | T-11 — Estructura project_notes/ | `.ai/specs/active/ticket-11.md` | Simple |
| 3 | T-12 — Métricas de ejecución | `.ai/specs/active/ticket-12.md` | Simple |

### --- PUNTO DE CORTE ---
Antes de continuar, ejecutá la Regla 5 de .ai/rules.md

| 4 | T-9 — Prompt Evolution | `.ai/specs/active/ticket-9.md` | Media |

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/ticket-[N].md`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, corré los tests, y hacé un commit atómico con el número de ticket en el mensaje. Devolvé: resumen (1-3 líneas), hash del commit, estado de tests (passed/failed), lista de archivos tocados, y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NO devuelvas logs completos ni output de tests.
2. Después del subagente, aplicá Reglas 2 + 2b + 2c (scope → tests → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn refinamiento-evolucion-v3 completo`
2. Creá el PR: `gh pr create --title "feat: refinamiento y evolución v3 — prompt evolution, permisos, project notes, métricas" --body "$(cat .ai/runs/results.tsv)"`
