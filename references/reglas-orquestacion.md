# Reglas estándar de orquestación

Estas reglas se aplican a TODOS los sprints. El archivo `.ai/rules.md` del sprint
solo debe contener overrides (puntos de corte, comando de tests, perfil de permiso).

## Regla 1: Cada ticket como subagente
Lanzá un subagente general-purpose por ticket. El subagente lee el spec de disco.
NO implementes tickets en el contexto principal (excepto correcciones menores post-rollback).

## Regla 2: Verificación y rollback automático

**Orden post-subagente:** 2d (commit) → 2b (scope) → tests → 2c (completitud) → 2e (verificadores).
Si cualquier paso falla, NO ejecutar los siguientes. Registrar failure_category del PRIMER fallo.

Antes de cada subagente: `PREV_HASH=$(git rev-parse HEAD)`, `START_TS=$(date +%s)`, `ROLLBACKS=0`.

**2d — Commit:** `git rev-parse HEAD` vs PREV_HASH. Si iguales → `discard` + `no_commit`. NO rescatar uncommitted.

**2b — Scope:** `git diff --name-only $PREV_HASH..HEAD` vs scope fence:
- En allowlist → OK
- En denylist → rollback, `scope_violation`
- Fuera de toda lista → `git checkout HEAD -- [archivo]` + warning (NO bloquear)
- Condicional → verificar diff vs condición. Solo warn, nunca bloquea.

**Tests:** Correr comando del spec. Fallo → máx 2 intentos, luego rollback + `test_failure`.

**2c — Completitud:** Todos criterios → `keep`. ≥80% sin críticos faltantes → `keep` + warn. <80% o falta crítico → 1 intento, luego `discard` + `incomplete`.

**2e — Verificadores determinísticos:**
Obligatorios: commit existe, diff no vacío, archivos ⊆ allowed, artefactos existen, tests corrieron, criterios ≥80%.
Coherencia (warn): código+docs ambos presentes, max_attempts no excedido, desviaciones ≤2.

**Rollback:** `git reset --hard $PREV_HASH`, `ROLLBACKS++`, registrar métricas.
**Commits atómicos:** formato `feat(T-N): ...`, revertibles con `git revert`.

## Regla 3: Autonomía total
NO pares a preguntar. Continuá hasta terminar o ser interrumpido.

## Regla 4: Registro en ledger
Registrar en `.ai/runs/results.tsv` (tabs, 12 columnas):
`ticket commit tests status failure_category iterations scope_warnings complexity tokens_used duration_s rollback_count description`

Categorías: `none`, `scope_violation`, `test_failure`, `incomplete`, `rationalization`, `spec_ambiguity`, `no_commit`, `verification_failed`.

## Regla 5: Checkpoint dinámico
Post-ticket: ¿releyendo archivos? ¿confundiendo resultados? ¿8+ tickets sin reset?
Sin degradación → continuar. Con degradación → persistir results.tsv, pedir /clear al usuario.

## Regla 6: Retomar post-clear
Si results.tsv tiene tickets → saltarlos. Leer results.tsv → rules.md → CLAUDE.md → continuar.

## Regla 7: /learn condicional
Post-ticket, ejecutar `/learn` SOLO si:
- El ticket requirió más de 1 intento (iterations > 1)
- Hubo rollback (rollback_count > 0)
- El subagente encontró algo inesperado (desviaciones en el reporte)
- El ticket fue descartado (status = discard)

Si el ticket pasó limpio a la primera → NO /learn. Un solo `/learn` al final del sprint captura lo general.

## Regla 8: /simplify (opcional)
Post-verificación para Media/Alta. Aplicar → re-test → amend si pasan, descartar si fallan.

## Regla 9: /batch (opcional)
3+ tickets sin dependencias, S/M, sin archivos compartidos → locks + /batch + verificar cada uno.

## Al terminar
1. Suite completa de tests
2. `/learn [batch] completo` — este es el /learn obligatorio del sprint (captura lecciones generales)
3. Archivar: `mkdir -p .ai/specs/archive/[batch] && mv .ai/specs/active/* .ai/specs/archive/[batch]/ && mkdir -p .ai/runs/archive && cp .ai/runs/results.tsv .ai/runs/archive/[batch].tsv && rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv && git add -A && git commit -m "chore: archivar [batch]"`
4. Registrar en sprint-registry.md
5. Resumen final + ofrecer /loop si hay CI
