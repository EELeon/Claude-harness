# hardening-p4

## Setup inicial
1. Creá la rama: `git checkout -b feat/hardening-p4`
2. Lee las reglas de orquestación en `.ai/rules.md` y seguílas estrictamente.

## Nota sobre ejecución

Casi todos los tickets modifican `templates/orchestrator-prompt.md`, lo que los hace
`shared_write`. Ejecutarlos TODOS secuencialmente, SIN paralelismo.
Esto es consistente con las mejoras que este sprint implementa.

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | hardening-01 — Protocolo de cherry-pick seguro | `.ai/specs/active/hardening-01-cherrypick-safe.md` | Simple |
| 2 | hardening-02 — Worktree obligatorio para paralelismo | `.ai/specs/active/hardening-02-worktree-mandatory.md` | Simple |
| 3 | hardening-05 — Lint obligatorio pre-commit | `.ai/specs/active/hardening-05-lint-precommit.md` | Simple |
| 4 | hardening-06 — Scope fence estricto | `.ai/specs/active/hardening-06-scope-strict.md` | Simple |
| 5 | hardening-07 — Validación de commit post-subagente | `.ai/specs/active/hardening-07-commit-validation.md` | Simple |
| 6 | hardening-08 — results.tsv exclusivo del orquestador | `.ai/specs/active/hardening-08-results-ownership.md` | Simple |
| 7 | hardening-09 — Convención de naming para specs | `.ai/specs/active/hardening-09-spec-naming.md` | Simple |
| 8 | hardening-10 — Sprint registry | `.ai/specs/active/hardening-10-sprint-registry.md` | Simple |
| 9 | hardening-12 — Trigger cuantitativo de compact | `.ai/specs/active/hardening-12-compact-trigger.md` | Simple |
| 10 | hardening-13 — Dependencias de lectura en spec template | `.ai/specs/active/hardening-13-read-dependencies.md` | Simple |
| 11 | hardening-03 — Concurrency classes integration | `.ai/specs/active/hardening-03-concurrency-integration.md` | Simple |
| 12 | hardening-04 — Recovery matrix cherry-pick | `.ai/specs/active/hardening-04-recovery-cherrypick.md` | Simple |
| 13 | hardening-11 — Archivar results.tsv por sprint | `.ai/specs/active/hardening-11-archive-results.md` | Simple |

**Orden de ejecución:**
- Tickets 1-2: Cherry-pick + worktree (Reglas 10 y 9 del orchestrator-prompt)
- Tickets 3-6: Calidad de subagentes (Reglas 2b, 2d, 4, prompt del subagente)
- Tickets 7-8: Naming + registry (spec-template + entrega-sprint)
- Ticket 9: Compact (Regla 5 + compaction-policy)
- Ticket 10: Read dependencies (spec-template)
- Tickets 11-12: References aislados (concurrency-classes, recovery-matrix) — dependen de ticket 1
- Ticket 13: Archive results (entrega-sprint + orchestrator-prompt) — depende de ticket 8

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `[ruta del spec]`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, corré los tests, y hacé un commit atómico con el ID del ticket en el mensaje. Antes de hacer commit, corré `ruff check [archivos_que_tocaste] --fix && ruff format [archivos_que_tocaste]` si ruff está disponible. Devolvé: resumen (1-3 líneas), hash del commit, estado de tests (passed/failed), lista de archivos tocados, conteo estimado de caracteres procesados (input+output del subagente), y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NUNCA modifiques archivos en .ai/. NO devuelvas logs completos ni output de tests.
2. Después del subagente, aplicá Reglas 2a + 2b + 2c + 2d (commit → scope → tests → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn hardening-p4 completo`
2. Archivá specs y limpiá artefactos temporales
3. Creá el PR: `gh pr create --title "feat: hardening P4 — cherry-pick safety, scope strict, naming, sprint registry" --body "$(cat .ai/runs/results.tsv)"`
