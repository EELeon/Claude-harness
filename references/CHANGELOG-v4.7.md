# CHANGELOG — v4.7

Recalibración del harness para Opus 4.7. El núcleo arquitectónico (disco como
fuente de verdad, commits atómicos, scope fences, subagentes con contexto
fresco) se mantiene intacto. Los cambios afectan umbrales empíricos y
reglas defensivas que se calibraron contra modelos más viejos.

## Principio de la migración

Un harness acumula defensas. Algunas son cicatrices de fallas específicas
de un modelo particular; otras son arquitectónicas. Esta versión separa
las dos: conserva lo arquitectónico, suaviza o elimina las cicatrices
que Opus 4.7 ya no necesita.

## Cambios

### Umbrales de tamaño (más permisivos)

| Concepto | v4.6 | v4.7 |
|----------|------|------|
| Trivial inline (sin spec) | ≤2 archivos | ≤5 archivos |
| NO dividir ticket | ≤3 archivos y ≤3 pasos | ≤5 archivos y ≤3 pasos |
| Dividir en 2-3 subtareas | 4-8 archivos | 6-10 archivos |
| Dividir en 3-5 subtareas | 9+ archivos | 11+ archivos |
| Specs por subagente (generación) | 6 | 8 |
| Señal de complejidad "muchos archivos" | >8 archivos | >10 archivos |
| Tokens por spec (target) | ~5K | ~8K |
| Zona segura fidelidad total | 0-5K tokens | 0-8K tokens |
| Degradación medible del orquestador | ~100K tokens | ~120K tokens |
| Checkpoint duro (reset sugerido) | 8+ tickets sin reset | 12+ tickets sin reset |
| Constraints por delegación (duro) | 10 | 10 zona segura / 15 umbral real |

**Rationale:** Opus 4.7 sostiene fidelidad de instrucciones sobre scopes
más grandes sin degradación medible. Los umbrales anteriores eran
defensivos contra paraphrase loss que ya no ocurre con la misma frecuencia.

### Reglas eliminadas o suavizadas

1. **Removido:** `SIEMPRE usar /compact antes de pausas largas (>5 min)`
   del CLAUDE.md del harness y del claudemd-template.
   - Contradecía `compaction-policy.md` y `design-rationale.md` que ya
     decían "NUNCA pedir /compact manualmente — Claude Code auto-compacta".
   - Marcado como **[LEGADO]** en `token-optimization.md`.

2. **Suavizado:** `NUNCA re-leer un archivo que ya está en contexto` →
   `Re-leer solo si se modificó después de la última lectura o si hay
   duda razonable del estado`.
   - La regla dura generaba casos donde el orquestador actuaba sobre
     memoria obsoleta después de rollback o post-subagente. La regla
     suave sigue desalentando re-lecturas innecesarias pero permite
     verificación cuando aplique.

3. **Clarificado:** `NUNCA permitir sub-subagentes` →
   `Sub-subagentes: NO soportados por Claude Code (constraint de
   plataforma, no regla de diseño)`.
   - Antes sonaba a decisión del orquestador. Es una restricción de la
     plataforma — si algún día Claude Code lo soporta, el harness no
     necesita bloquearlo.

4. **Reemplazado:** `Cada 3-4 tickets: /compact o /clear` →
   `Checkpoint dinámico (Regla 5) decide`.
   - Puntos de corte hardcoded ignoraban si había degradación real.
     El checkpoint dinámico ya existía; esta versión lo prioriza.

### Reglas conservadas (arquitectura, no cicatriz)

- Commits atómicos por ticket — revertibilidad
- Scope fence obligatorio — previene over-engineering (más crítico con
  modelos capaces que pueden hacer cambios correctos fuera de scope)
- Self-contained specs — los subagentes arrancan con contexto blanco
  independientemente del modelo
- Ledger (`.ai/runs/results.tsv`) — fuente de verdad post-compact
- Frontmatter YAML parseable en specs — contrato mecánico
- Imperative form (SIEMPRE/NUNCA) — el margen de compliance vs
  descriptivo sigue siendo real
- /learn condicional (ya era así en v4.6)
- Guard destructivo (PreToolUse hook)
- Preflight estructural + semántico (Niveles 0-5)
- Máx 5 subagentes concurrentes — plataforma
- Sub-subagentes deshabilitados — plataforma

## Migración desde v4.6

El harness v4.7 es retrocompatible: los specs escritos en v4.6 siguen
pasando preflight sin cambios. Los umbrales son ahora más permisivos,
no más estrictos, así que nada "rompe".

Si vienes de v4.6:
- No hace falta regenerar specs existentes.
- Los sprints en curso terminan con las reglas de v4.6; los nuevos
  arrancan con v4.7.
- El CLAUDE.md del repo target puede regenerarse con
  `templates/claudemd-template.md` si querés eliminar la línea obsoleta
  de `/compact`.

## Archivos modificados

- `CLAUDE.md` — umbrales, quitar /compact manual, suavizar re-lectura
- `templates/claudemd-template.md` — mismo tratamiento para repos target
- `templates/spec-template.md` — umbrales de subtareas
- `references/flujo-principal.md` — trivial ≤5, specs-por-subagente 8, presupuesto de tokens
- `references/subagent-sizing.md` — sub-subagentes como platform-constraint, umbrales 10/6-10/11+
- `references/reglas-specs.md` — target 8K tokens, constraints zona-segura vs umbral real
- `references/design-rationale.md` — estimaciones de contexto actualizadas
- `references/token-optimization.md` — marcar cache-expiry fix como [LEGADO]
- `references/compaction-policy.md` — checkpoint Nivel 3 a 12+ tickets
- `references/permission-profiles.md` — puntos de corte por checkpoint dinámico
- `skills/orchestrate/SKILL.md` — límite de specs y clarificación sub-subagentes
- `.claude-plugin/plugin.json` — bump 4.6.0 → 4.7.0
