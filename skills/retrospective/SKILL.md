---
name: retrospective
description: >
  Análisis retroactivo de sesiones de Claude Code para encontrar patrones de
  fricción. Usa este skill cuando el usuario diga: "retrospectiva", "retrospective",
  "analizar sesiones", "qué patrones hay", "qué funciona mal", o quiera hacer un
  análisis panorámico de múltiples ejecuciones.
---

# Retrospective — Análisis multi-sesión

## Propósito

Analizar el historial de sesiones de Claude Code para encontrar patrones
de fricción y sugerir mejoras sistémicas. Complementa a `/learn` (que
captura lecciones por ticket) con una vista panorámica.

## Instrucciones

Leer `${CLAUDE_PLUGIN_ROOT}/commands/retrospective.md` para el flujo completo
(5 fases: encontrar → analizar → sintetizar → cross-reference → reportar).

### Resumen

1. **Encontrar** conversaciones recientes en `~/.claude/projects/`
2. **Analizar** en paralelo (subagentes por conversación + datos de results.tsv)
3. **Sintetizar** patrones de fricción rankeados por frecuencia
4. **Cross-reference** contra configuración actual (CLAUDE.md, hooks, agents)
5. **Generar** `RETROSPECTIVE.md` con diagnóstico y sugerencias

### Cuándo usarlo

- Después de la primera ejecución completa del orquestador
- Cada 2-3 ejecuciones para vista panorámica
- Cuando el ratio keep/discard es bajo (>50% discards)
- Cuando el usuario siente que algo "no funciona bien" pero no sabe qué

### Output

Genera `RETROSPECTIVE.md` con patrones de fricción, lo que funciona bien,
infraestructura sugerida, y log crudo de citas. NO aplica cambios
automáticamente — es diagnóstico, no tratamiento.
