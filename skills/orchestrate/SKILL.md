---
name: orchestrate
description: >
  Pipeline completo de tickets a ejecución autónoma en Claude Code. Usa este skill
  cuando el usuario tenga múltiples tickets, tareas, features o issues que implementar.
  Actívalo cuando diga: "tengo estos tickets", "implementar estos cambios",
  "preparar specs para Code", "dividir en subtareas", "organizar trabajo para Code",
  "sprint de desarrollo", "batch de features", o cualquier referencia a preparar
  trabajo de programación en lote.
---

# Code Orchestrator — De tickets a ejecución autónoma

## Modelo de ejecución

- Una sola rama, un solo PR, commits atómicos por ticket, subagentes con contexto fresco
- Estado en disco (`.ai/runs/results.tsv`), checkpoint dinámico post-ticket
- Máx 5 subagentes concurrentes, no sub-subagentes, máx 6 specs por subagente

**Capas de protección:**
- Primaria (siempre): Preflight → Scope fence + diff → Tests → Completitud → Ledger
- Secundaria (hooks): Guard destructivo + Anti-racionalización
- Terciaria (Claude Code): /simplify + /batch + /loop

## Flujo principal (7 pasos)

| Paso | Qué hace | Referencia (leer bajo demanda) |
|------|----------|-------------------------------|
| 0 | Meta del proyecto (condicional) | flujo-principal.md |
| 1 | Inventario y análisis de tickets | flujo-principal.md |
| **1.5** | **Triage de tamaño (gate)** | flujo-principal.md |
| 2 | Ordenar tickets y puntos de corte | flujo-principal.md |
| 3 | Generar specs por ticket | reglas-specs.md |
| 3.5 | Preflight: validar specs | commands/preflight.md |
| 4 | Prompt + rules | orchestrator-prompt.md |
| 5 | Artefactos de soporte | flujo-principal.md |
| 6 | Revisión + línea de ejecución | entrega-sprint.md |

## Lazy-load de referencias

LEER SOLO cuando el paso lo requiera. NO leer todo al inicio.

**Siempre leer (Paso 1):**
- `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` — flujo completo

**Leer al escribir specs (Paso 3):**
- `${CLAUDE_PLUGIN_ROOT}/references/reglas-specs.md`
- `${CLAUDE_PLUGIN_ROOT}/templates/spec-template.md`

**Leer solo si hay tickets que dividir (Paso 1.5):**
- `${CLAUDE_PLUGIN_ROOT}/references/subagent-sizing.md`

**Leer al generar prompt (Paso 4):**
- `${CLAUDE_PLUGIN_ROOT}/templates/orchestrator-prompt.md`

**Leer al entregar (Paso 6):**
- `${CLAUDE_PLUGIN_ROOT}/references/entrega-sprint.md`
- `${CLAUDE_PLUGIN_ROOT}/templates/execution-plan-template.md`

**Leer solo si hay errores/recovery:**
- `${CLAUDE_PLUGIN_ROOT}/references/recovery-matrix.md`

**Leer solo si se configuran hooks:**
- `${CLAUDE_PLUGIN_ROOT}/templates/stop-hook.md`

**Leer solo si se crean agentes custom:**
- `${CLAUDE_PLUGIN_ROOT}/references/agent-patterns.md`

## Entregables obligatorios — NUNCA omitir

1. **`.ai/rules.md`** — SOLO overrides del sprint (perfil, comando tests, puntos de corte).
   Las reglas estándar viven en `${CLAUDE_PLUGIN_ROOT}/references/reglas-orquestacion.md`.
   El prompt apunta a ambos archivos. NO copiar reglas estándar al rules.md.
2. **`.ai/prompts/[batch].md`** — Prompt ultra-lean (~1K tokens). Tabla de tickets + referencias.
3. **Línea de ejecución:** `Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.`

Si specs listos pero rules.md y prompt NO existen → flujo incompleto. Continuar a Paso 4 → 5 → 6.

## Checklist de cierre

- [ ] Specs en `.ai/specs/active/`
- [ ] Preflight pasado (0 FAIL)
- [ ] `.ai/rules.md` generado
- [ ] `.ai/prompts/[batch].md` generado
- [ ] Artefactos: CLAUDE.md, comandos, plan de ejecución
- [ ] Línea de ejecución entregada

**Regla de carpetas:** Siempre `mkdir -p` antes de escribir.
