# Reglas de orquestación — refinamiento-evolucion-v3

## Regla 1 — Subagentes
Cada ticket se ejecuta en un subagente general-purpose. El prompt incluye ruta al spec, instrucción de leer CLAUDE.md, y formato Heat Shield.

## Regla 2 — Verificación post-subagente
- 2a (Scope): Tocó archivos fuera del scope fence? rollback
- 2b (Tests): Pasaron todos los tests? si no, retry (max 2 en standard)
- 2c (Completitud): Cada criterio cumplido? si parcial, decidir keep/retry

## Regla 3 — Heat Shield
Subagente devuelve SOLO: resumen (1-3 líneas), hash commit, tests (passed/failed), archivos tocados, criterios (sí/no/parcial). NO logs, NO output de tests, NO contenido.

## Regla 4 — Registro en ledger
Registrar en .ai/runs/results.tsv con formato (tab-separated):
ticket | commit | tests | status | failure_category | iterations | scope_warnings | complexity | description

Columnas nuevas vs P1/P2: iterations (intentos, 1=primera vez), scope_warnings (0=limpio), complexity (Simple/Media/Alta)

## Regla 5 — Punto de corte
Después de T-12 (antes de T-9):
1. Persistir estado a disco
2. Revisar resultados T-10, T-11, T-12
3. Si 2+ discards: PARAR y reportar
4. Si ok: continuar con T-9

## Regla 6 — Commit atómico
Cada ticket = 1 commit con mensaje del spec. Retry revierte con git reset --hard.

## Regla 7 — No sub-subagentes
Máximo 1 nivel de profundidad.
