---
name: code-orchestrator
description: >
  Orquestador de tickets para Claude Code. Usa este skill siempre que el usuario tenga
  múltiples tickets, tareas, features o issues que implementar con Claude Code.
  Actívalo cuando diga: "tengo estos tickets", "implementar estos cambios",
  "preparar specs para Code", "dividir en subtareas", "organizar trabajo para Code",
  "sprint de desarrollo", "batch de features", o cualquier referencia a preparar
  trabajo de programación en lote. También actívalo si el usuario pide preparar o
  instalar un repo para Code ("instalar harness", "preparar este repo para Code",
  "bootstrap"), o pregunta cómo dividir trabajo entre subagentes, cómo manejar
  contexto en sesiones largas de Code, o cómo organizar implementación de múltiples
  cambios en un codebase.
---

# Code Orchestrator — De tickets a ejecución autónoma en Claude Code

## Propósito

Convertir un lote de tickets en un paquete que Claude Code ejecute
de manera autónoma, con un solo prompt por sprint.

## Modelo de ejecución

- **Subagentes por ticket** — contexto fresco (~200k tokens) por cada uno
- **Estado en disco** — `results.tsv` (TSV: ticket, commit, tests, status,
  failure_category, description) permite retomar si se pierde contexto
- **Compactación proactiva** — pedir `/compact` después de 3+ tickets
- **Puntos de corte** — para sprints de 5+ tickets, pausas para `/clear`

**Límites:** máx 5 subagentes concurrentes, no sub-subagentes,
cada subagente empieza con contexto en blanco.

**Capas de protección:**
- Primaria (siempre activa): Preflight → Scope fence + diff audit →
  Tests → Completitud → Ledger
- Secundaria (hooks opcionales): Guard destructivo + Anti-racionalización

## Flujo principal (6 pasos)

Leer `references/flujo-principal.md` para los pasos completos.

| Paso | Qué hace | Detalle en |
|------|----------|-----------|
| 1 | Inventario y análisis de tickets | `references/flujo-principal.md` |
| 2 | Agrupación en sprints | `references/flujo-principal.md` |
| 3 | Generar specs por ticket | `references/reglas-specs.md` |
| 3.5 | Preflight: validar specs | `commands/preflight.md` |
| 4 | Prompt lean + ORCHESTRATOR_RULES.md | `templates/orchestrator-prompt.md` |
| 5 | Artefactos de soporte (progresivo) | `references/flujo-principal.md` |
| 6 | Revisión con el usuario | `references/flujo-principal.md` |

## Bootstrap de un repo nuevo

Leer `references/bootstrap.md` para el protocolo completo.

Resumen: auditar repo → instalar scaffold (CLAUDE.md, .claude/commands/,
settings.json) → personalizar para el repo → reportar al usuario.

## Entrega de sprint

Leer `references/entrega-sprint.md` para artefactos y flujo de ejecución.

## Reglas de specs

Leer `references/reglas-specs.md` para estructura obligatoria y límites.

## Archivos de referencia del skill

Todas las rutas son relativas a este skill.

| Archivo | Cuándo leerlo |
|---------|--------------|
| `references/flujo-principal.md` | Al ejecutar el flujo de 6 pasos |
| `references/bootstrap.md` | Al instalar harness en un repo nuevo |
| `references/reglas-specs.md` | Al escribir specs |
| `references/entrega-sprint.md` | Al entregar un sprint |
| `references/subagent-sizing.md` | Al dividir tickets en subtareas |
| `references/agent-patterns.md` | Al crear agentes custom |
| `templates/spec-template.md` | Plantilla completa de cada spec |
| `templates/orchestrator-prompt.md` | Plantilla del prompt + reglas |
| `templates/stop-hook.md` | Al configurar hooks |
| `templates/claudemd-template.md` | Al generar CLAUDE.md |
| `templates/execution-plan-template.md` | Al generar el plan de ejecución |
| `commands/learn.md` | Al instalar /learn |
| `commands/next-ticket.md` | Al instalar /next-ticket |
| `commands/status.md` | Al instalar /status |
| `commands/preflight.md` | Al instalar /preflight |
| `commands/retrospective.md` | Al instalar /retrospective (post Sprint 1) |
