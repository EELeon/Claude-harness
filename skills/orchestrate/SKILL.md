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

## Propósito

Convertir un lote de tickets en un paquete que Claude Code ejecute
de manera autónoma, con una sola línea.

## Modelo de ejecución

- **Una sola rama, un solo PR** — todos los tickets en secuencia
- **Commits atómicos por ticket** — revertibles individualmente con `git revert`
- **Subagentes por ticket** — contexto fresco (~200k tokens) por cada uno
- **Estado en disco** — `.ai/runs/results.tsv` permite retomar si se pierde contexto
- **Compactación proactiva** — pedir `/compact` después de 3+ tickets
- **Puntos de corte** — pausas para `/clear` (NO son fronteras de git)

**Límites:** máx 5 subagentes concurrentes, no sub-subagentes,
cada subagente empieza con contexto en blanco.

**Capas de protección:**
- Primaria (siempre activa): Preflight → Scope fence + diff audit →
  Tests → Completitud → Ledger
- Secundaria (hooks opcionales): Guard destructivo + Anti-racionalización

## Flujo principal (6 pasos)

Leer `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` para los pasos completos.

| Paso | Qué hace | Detalle en |
|------|----------|-----------|
| 0 | Meta del proyecto (condicional) | `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` |
| 1 | Inventario y análisis de tickets | `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` |
| 2 | Ordenar tickets y definir puntos de corte | `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` |
| 3 | Generar specs por ticket | `${CLAUDE_PLUGIN_ROOT}/references/reglas-specs.md` |
| 3.5 | Preflight: validar specs | `${CLAUDE_PLUGIN_ROOT}/commands/preflight.md` |
| 4 | Prompt → `.ai/prompts/[batch].md` + `.ai/rules.md` | `${CLAUDE_PLUGIN_ROOT}/templates/orchestrator-prompt.md` |
| 5 | Artefactos de soporte (progresivo) | `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` |
| 6 | Revisión + línea de ejecución para el usuario | `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` |

## Reglas de specs

Leer `${CLAUDE_PLUGIN_ROOT}/references/reglas-specs.md` para estructura obligatoria y límites.

## Entrega

Leer `${CLAUDE_PLUGIN_ROOT}/references/entrega-sprint.md` para artefactos, mapa de archivos,
y flujo de ejecución.

**Regla de carpetas:** Siempre `mkdir -p` antes de escribir a una ruta.

## Archivos de referencia

Todas las rutas usan `${CLAUDE_PLUGIN_ROOT}` para resolver archivos compartidos del plugin.

| Archivo | Cuándo leerlo |
|---------|--------------|
| `${CLAUDE_PLUGIN_ROOT}/references/flujo-principal.md` | Al ejecutar el flujo de 6 pasos |
| `${CLAUDE_PLUGIN_ROOT}/references/reglas-specs.md` | Al escribir specs |
| `${CLAUDE_PLUGIN_ROOT}/references/entrega-sprint.md` | Al entregar una ejecución |
| `${CLAUDE_PLUGIN_ROOT}/references/subagent-sizing.md` | Al dividir tickets en subtareas |
| `${CLAUDE_PLUGIN_ROOT}/references/agent-patterns.md` | Al crear agentes custom |
| `${CLAUDE_PLUGIN_ROOT}/templates/spec-template.md` | Plantilla completa de cada spec |
| `${CLAUDE_PLUGIN_ROOT}/templates/orchestrator-prompt.md` | Plantilla del prompt + reglas |
| `${CLAUDE_PLUGIN_ROOT}/templates/stop-hook.md` | Al configurar hooks |
| `${CLAUDE_PLUGIN_ROOT}/templates/claudemd-template.md` | Al generar CLAUDE.md |
| `${CLAUDE_PLUGIN_ROOT}/templates/execution-plan-template.md` | Al generar el plan de ejecución |
