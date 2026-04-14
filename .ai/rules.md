# Reglas de orquestación — hardening-p4

## Regla 1 — Subagentes
Cada ticket se ejecuta en un subagente general-purpose. El prompt incluye ruta al spec, instrucción de leer CLAUDE.md, y formato Heat Shield.

## Regla 2 — Verificación post-subagente
- 2a (Commit): Hash pre/post subagente idénticos? → discard con no_commit, re-ejecutar
- 2b (Scope): Tocó archivos fuera del scope fence? → revertir esos archivos con git checkout HEAD -- [archivo], registrar en scope_warnings. Si tocó archivos en denylist → rollback completo
- 2c (Tests): Pasaron todos los tests? si no, retry (max 2)
- 2d (Completitud): Cada criterio cumplido? si parcial, decidir keep/retry

Orden: 2a → 2b → 2c → 2d. Si cualquier paso falla, NO ejecutar los siguientes.

## Regla 3 — Heat Shield
Subagente devuelve SOLO: resumen (1-3 líneas), hash commit, tests (passed/failed), archivos tocados, conteo estimado de caracteres procesados (input+output), criterios de aceptación (sí/no/parcial). NO logs, NO output de tests, NO contenido de archivos.

## Regla 4 — Registro en ledger
Registrar en .ai/runs/results.tsv con formato v3 (tab-separated, 12 columnas):
ticket | commit | tests | status | failure_category | iterations | scope_warnings | complexity | tokens_used | duration_s | rollback_count | description

**Propiedad exclusiva:** Los archivos en `.ai/` son EXCLUSIVOS del orquestador. Subagentes NUNCA escriben en `.ai/`.

## Regla 5 — Checkpoint dinámico
Después de cada ticket completado, evaluar degradación de contexto.
- ¿Estoy releyendo rules.md o specs porque no recuerdo?
- ¿Confundo resultados de tickets diferentes?
- ¿Llevo 8+ tickets desde el último /clear?

Si hay degradación: persistir estado a disco, sugerir /clear al usuario.

## Regla 6 — Commit atómico
Cada ticket = 1 commit con ID del ticket en el mensaje (ej: `feat(hardening-01): ...`). Retry revierte con git reset --hard.

## Regla 7 — No sub-subagentes
Máximo 1 nivel de profundidad.

## Regla 8 — Autonomía total (NEVER STOP)
No parar a preguntar. Continuar ejecutando hasta terminar todos los tickets o hasta error sistémico.

## Regla 9 — Lint pre-commit
Antes de aceptar un commit del subagente, verificar que pasa lint. Si no, correr `ruff check --fix && ruff format` sobre los archivos tocados. Si ruff no existe, ignorar.

## Formato de .ai/runs/results.tsv

```
ticket	commit	tests	status	failure_category	iterations	scope_warnings	complexity	tokens_used	duration_s	rollback_count	description
```
