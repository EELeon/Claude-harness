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
  cambios en un codebase. También actívalo si el usuario menciona: "definir meta",
  "auditoría recursiva", "recursive audit", "auditar contra el meta", "loop de
  auditoría", "cerrar gaps", o cualquier referencia a auditar completitud del
  sistema contra una visión de alto nivel.
---

# Code Orchestrator — De tickets a ejecución autónoma en Claude Code

## Propósito

Convertir un lote de tickets en un paquete que Claude Code ejecute
de manera autónoma, con una sola línea.

## Modelo de ejecución

- **Una sola rama, un solo PR** — todos los tickets en secuencia
- **Commits atómicos por ticket** — revertibles individualmente con `git revert`
- **Subagentes por ticket** — contexto fresco (~200k tokens) por cada uno
- **Estado en disco** — `.ai/runs/results.tsv` (TSV: ticket, commit, tests,
  status, failure_category, description) permite retomar si se pierde contexto
- **Compactación proactiva** — pedir `/compact` después de 3+ tickets
- **Puntos de corte** — pausas para `/clear` (NO son fronteras de git)

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
| 2 | Ordenar tickets y definir puntos de corte | `references/flujo-principal.md` |
| 3 | Generar specs por ticket | `references/reglas-specs.md` |
| 3.5 | Preflight: validar specs | `commands/preflight.md` |
| 4 | Prompt → `.ai/prompts/[nombre-batch].md` + `.ai/rules.md` | `templates/orchestrator-prompt.md` |
| 5 | Artefactos de soporte (progresivo) | `references/flujo-principal.md` |
| 6 | Revisión + línea de ejecución para el usuario | `references/flujo-principal.md` |

## Meta y auditoría recursiva

El **meta** es un documento de alto nivel (`.ai/meta.md`) que describe
QUÉ debe ser capaz de hacer el sistema completo — la visión que origina
los specs. El loop recursivo audita el código contra el meta, no contra
los specs, para encontrar gaps que nunca se especificaron.

| Archivo | Cuándo leerlo |
|---------|--------------|
| `templates/meta-template.md` | Al crear .ai/meta.md para un proyecto |
| `commands/validate-meta.md` | Al validar un meta existente |
| `commands/recursive-audit.md` | Al ejecutar el loop recursivo |

**Flujo del meta:**
1. Si no existe `.ai/meta.md` → guiar al usuario con AskUserQuestion
2. Si existe → validar con lógica de `commands/validate-meta.md`
3. Si el usuario pide auditoría recursiva → ejecutar `commands/recursive-audit.md`

**Pipeline de auditoría (3 subagentes secuenciales):**
1. Auditor (Explore, ~60-100K) → `.ai/audit/iteration-N/raw-gaps.md`
2. Analista+Planificador (Plan, ~35K) → `.ai/audit/iteration-N/plan.md`
3. Spec Writer (General-purpose, ~40-70K) → `.ai/specs/active/ticket-*.md`
4. Orchestrator existente → implementa los specs

El loop se repite hasta: gaps = 0, max_iterations, coverage_threshold,
o diminishing returns (parámetros configurables en el meta).

## Bootstrap de un repo nuevo

Leer `references/bootstrap.md` para el protocolo completo.

Resumen: auditar repo → instalar scaffold (CLAUDE.md, .claude/commands/,
settings.json, hooks/) → personalizar para el repo → reportar al usuario.

## Entrega

Leer `references/entrega-sprint.md` para artefactos, mapa de archivos,
y flujo de ejecución.

**Regla de carpetas:** Siempre `mkdir -p` antes de escribir a una ruta.
Si la carpeta no existe, crearla. Esto aplica a Cowork y a Claude Code.

## Reglas de specs

Leer `references/reglas-specs.md` para estructura obligatoria y límites.

## Archivos de referencia del skill

Todas las rutas son relativas a este skill.

| Archivo | Cuándo leerlo |
|---------|--------------|
| `references/flujo-principal.md` | Al ejecutar el flujo de 6 pasos |
| `references/bootstrap.md` | Al instalar harness en un repo nuevo |
| `references/reglas-specs.md` | Al escribir specs |
| `references/entrega-sprint.md` | Al entregar una ejecución |
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
| `commands/retrospective.md` | Al instalar /retrospective (post primera ejecución) |
| `commands/cleanup-ai.md` | Al limpiar .ai/ desorganizado + migrar hook |
| `commands/validate-meta.md` | Al validar .ai/meta.md |
| `commands/recursive-audit.md` | Al ejecutar loop recursivo de auditoría |
| `templates/meta-template.md` | Al crear .ai/meta.md para un proyecto |
