---
name: recursive-audit
description: >
  Loop recursivo de auditoría contra el meta del proyecto. Usa este skill cuando
  el usuario diga: "auditoría recursiva", "recursive audit", "auditar contra el meta",
  "loop de auditoría", "cerrar gaps", "auditar completitud", o cualquier referencia
  a auditar el sistema contra una visión de alto nivel y cerrar gaps automáticamente.
---

# Recursive Audit — Auditoría recursiva contra meta

## Propósito

Comparar el estado actual del código contra el meta del proyecto (`.ai/meta.md`),
encontrar gaps, generar specs para cerrarlos, implementar, y repetir hasta
que no queden gaps abiertos.

## Prerequisitos

- `.ai/meta.md` debe existir y pasar validación
- El repo debe tener CLAUDE.md y la infraestructura del orquestador

## Pipeline (3 subagentes secuenciales)

```
AUDITOR (Explore, ~60-100K) → raw-gaps.md
    ↓
ANALISTA+PLANIFICADOR (Plan, ~35K) → plan.md
    ↓
SPEC WRITER (General-purpose, ~40-70K) → ticket-*.md
    ↓
ORCHESTRATOR EXISTENTE → implementa
    ↓
¿Gaps restantes? → volver al AUDITOR
```

## Instrucciones

Leer `${CLAUDE_PLUGIN_ROOT}/commands/recursive-audit.md` para el flujo completo
(7 pasos, criterios de parada, gestión de contexto, resumibilidad).

## Criterios de parada

| Criterio | Condición |
|----------|-----------|
| Sin gaps | Gaps = 0 |
| Max iterations | Iteración ≥ max_iterations (configurable en meta) |
| Coverage threshold | Cobertura ≥ coverage_threshold% |
| Diminishing returns | Gaps cerrados < diminishing_returns en un ciclo |

## Artifacts

Los artifacts se guardan en `.ai/audit/iteration-N/` por iteración.
Al finalizar, se genera `.ai/audit/summary.md` con el reporte final.
