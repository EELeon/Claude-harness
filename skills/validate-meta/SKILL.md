---
name: validate-meta
description: >
  Validar el documento meta del proyecto. Usa este skill cuando el usuario
  diga: "validar meta", "verificar meta", "revisar meta", "el meta está bien?",
  o quiera asegurarse de que .ai/meta.md está bien formado antes de una auditoría.
---

# Validate Meta — Validación del documento meta

## Propósito

Validar `.ai/meta.md` en dos capas (estructural + semántica) antes de
usarlo como referencia para la auditoría recursiva.

## Instrucciones

Leer `${CLAUDE_PLUGIN_ROOT}/commands/validate-meta.md` para la lógica
completa de validación (8 niveles en 2 capas).

### Resumen de validaciones

**Capa 1 — Estructural (determinista):**
- Headings obligatorios (Visión, Dominios, Capacidades, Restricciones, Parámetros)
- Contenido no vacío
- IDs únicos con formato correcto
- Parámetros del loop válidos

**Capa 2 — Semántica:**
- Criterios realmente verificables por un agente
- Granularidad consistente entre capacidades
- Cobertura de dominios (sin huecos obvios)
- Restricciones con método de verificación

### Severidad

- **FAIL**: Corregir antes de `/code-orchestrator:recursive-audit`
- **PASS WITH WARNINGS**: Usable pero con riesgo
- **PASS**: Listo para auditoría
