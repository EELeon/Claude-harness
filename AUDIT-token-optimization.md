# Auditoría de optimización de tokens — Code Orchestrator

**Fecha:** 2026-04-15
**Total plugin:** ~14,350 líneas (~172K tokens estimados)

---

## Resumen ejecutivo

El plugin tiene buena arquitectura conceptual (lazy loading de specs, reglas en disco, Heat Shield) pero ha acumulado deuda de tokens por duplicación, verbosidad en templates, y artefactos de sprints anteriores que nunca se limpiaron. El ahorro estimado es de **~40-50% del peso total** sin perder funcionalidad.

---

## Hallazgo 1: Specs duplicados entre active/ y archive/ — CRÍTICO

**Impacto: ~2,200 líneas / ~26K tokens desperdiciados**

Los 17 specs en `.ai/specs/active/` (hardening-01 a 13 + ticket-9 a 12) son **idénticos byte a byte** a sus copias en `.ai/specs/archive/harden-sprint/`. La única diferencia es CRLF vs LF.

**Acción:** Eliminar los 17 specs de `active/` — el sprint ya terminó y están archivados.

---

## Hallazgo 2: Commands duplicados en dos directorios

**Impacto: ~632 líneas / ~7.5K tokens**

| Archivo | commands/ | .claude/commands/ | Relación |
|---------|-----------|-------------------|----------|
| learn.md | 180 lín | 196 lín | Casi idéntico (.claude añade tags OP) |
| next-ticket.md | 24 | 24 | Idéntico |
| preflight.md | 245 | 148 | Diferente (root=español completo, .claude=inglés abreviado) |
| recursive-audit.md | 355 | 118 | Diferente (root=operativo, .claude=referencia) |
| status.md | 34 | 34 | Idéntico |
| validate-meta.md | 134 | 118 | Casi idéntico (traducción) |

**Problema real:** cleanup-ai.md y retrospective.md solo existen en `commands/` pero no en `.claude/commands/`. No hay consistencia sobre cuál directorio es la fuente de verdad.

**Acción:** Elegir UN directorio como canónico. Los `.claude/commands/` son los que Claude Code lee nativamente — mantener esos y eliminar `commands/` o convertirlo en alias con `Read commands/[x].md`.

---

## Hallazgo 3: orchestrator-prompt.md — el archivo más pesado

**Impacto: 616 líneas / ~7.4K tokens (se lee en cada sprint)**

Desglose del contenido:

| Sección | Líneas | Tipo |
|---------|--------|------|
| Comentario HTML de diseño (líneas 1-51) | 51 | Documentación interna — NO se necesita en runtime |
| Template del prompt generado (53-93) | 40 | **Esencial** — lo que realmente se genera |
| Comentario sobre rules.md (97-106) | 10 | Documentación interna |
| Template de rules.md (108-600+) | ~500 | Reglas detalladas con tablas y ejemplos |

**Problema:** Las 51 líneas de comentarios HTML se leen cada vez que el skill genera un prompt. Son útiles para un humano diseñando el sistema, pero el LLM no los necesita para generar el archivo. Las reglas (Regla 2, 2b, 2c, 2d) son exhaustivas con tablas de decisión que podrían comprimirse a reglas imperativas.

**Acción:**
- Mover comentarios HTML de diseño a un `references/design-rationale.md` separado
- Comprimir las reglas: las tablas de clasificación de scope (líneas 166-178) y completitud (líneas 215-221) pueden ser listas de 3 líneas cada una
- Estimado: 616 → ~280 líneas (ahorro 55%)

---

## Hallazgo 4: Templates sobredimensionados

| Template | Líneas | Puede bajar a | Problema principal |
|----------|--------|---------------|--------------------|
| spec-template.md | 246 | ~125 | Ejemplos explicativos que duplican lo que ya dice reglas-specs.md |
| stop-hook.md | 257 | ~100 | Dos ejemplos completos cuando uno basta; notas de implementación que van en references/ |
| execution-plan-template.md | 174 | ~80 | Tabla de infraestructura repite CLAUDE.md y flujo-principal |

**Ahorro combinado: ~370 líneas / ~4.4K tokens**

---

## Hallazgo 5: References con verbosidad comprimible

| Reference | Líneas | Puede bajar a | Nota |
|-----------|--------|---------------|------|
| flujo-principal.md | 369 | ~165 | Preámbulos de 20 líneas por paso → comprimir a tablas de decisión |
| recovery-matrix.md | 260 | ~185 | Ya está bien; las 11 situaciones son necesarias |
| subagent-sizing.md | 192 | ~125 | Ejemplos de error redundantes |
| compaction-policy.md | 171 | ~100 | Explicaciones pedagógicas innecesarias para el LLM |

**Ahorro combinado: ~420 líneas / ~5K tokens**

---

## Hallazgo 6: Artefactos stale en .ai/

| Archivo | Líneas | Estado |
|---------|--------|--------|
| .ai/rules.md | 48 | **SUPERSEDED** por rules-v3.md — eliminar |
| .ai/plan-v3.md | 11 | **STALE** — sprint terminado, archivar |

---

## Hallazgo 7: El costo real de un sprint

Cuando el skill `orchestrate` corre un sprint, el orquestador necesita leer:

| Componente | Tokens aprox |
|------------|-------------|
| CLAUDE.md | 744 |
| orchestrate/SKILL.md | 1,368 |
| flujo-principal.md | 4,428 |
| reglas-specs.md | 1,212 |
| entrega-sprint.md | 1,788 |
| subagent-sizing.md | 2,304 |
| recovery-matrix.md | 3,120 |
| orchestrator-prompt.md (template) | 7,392 |
| spec-template.md | 2,952 |
| execution-plan-template.md | 2,088 |
| stop-hook.md | 3,084 |
| **Subtotal infraestructura** | **~30,480** |
| + rules.md generado | ~400 |
| + specs (avg 1,564 × N tickets) | variable |

**Para un sprint de 5 tickets:** ~30K infra + 400 rules + 7,800 specs = **~38K tokens solo para configurar el sprint**, antes de que un solo subagente ejecute.

---

## Plan de acción priorizado

### Prioridad 1 — Limpieza inmediata (0 riesgo, ~35K tokens)
1. Eliminar los 17 specs duplicados de `active/` (sprint ya archivado)
2. Eliminar `.ai/rules.md` (superseded por v3)
3. Archivar `.ai/plan-v3.md`
4. Unificar commands en un solo directorio

### Prioridad 2 — Comprimir templates (riesgo bajo, ~12K tokens)
5. Extraer comentarios de diseño de orchestrator-prompt.md → design-rationale.md
6. Comprimir tablas de decisión en reglas a formato imperativo
7. Reducir spec-template a la mitad eliminando ejemplos redundantes
8. Fusionar los dos ejemplos de stop-hook en uno paramétrico

### Prioridad 3 — Comprimir references (riesgo medio, ~5K tokens)
9. flujo-principal: preámbulos narrativos → tablas de decisión
10. subagent-sizing: un ejemplo por categoría de error
11. compaction-policy: eliminar explicaciones pedagógicas

### Prioridad 4 — Rediseño estructural (investigar)
12. Evaluar si el orquestador realmente necesita leer los 7 references en cada sprint o si puede hacer lazy-load solo los relevantes al tipo de sprint
13. Evaluar un "modo lite" de specs para tickets simples (50 líneas en vez de 130)

---

## Estimado de ahorro total

| Categoría | Tokens actuales | Tokens después | Ahorro |
|-----------|----------------|----------------|--------|
| Duplicados (specs + commands) | ~34K | 0 | 34K |
| Templates comprimidos | ~15.5K | ~7K | 8.5K |
| References comprimidos | ~13K | ~8K | 5K |
| Stale artifacts | ~700 | 0 | 700 |
| **Total** | **~63K** | **~15K** | **~48K tokens** |

El costo de infraestructura por sprint bajaría de ~30K a ~17K tokens.
