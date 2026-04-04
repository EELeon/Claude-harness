---
name: preflight
description: >
  Validar specs antes de ejecutar un sprint. Usa este skill cuando el usuario
  diga: "validar specs", "preflight", "revisar specs", "verificar specs",
  o quiera asegurarse de que los specs están bien formados antes de ejecutar.
---

# Preflight — Validación de specs

## Propósito

Validar los specs en `.ai/specs/active/` antes de que el orquestador
los ejecute. Detecta problemas estructurales y semánticos que causarían
fallos durante la ejecución autónoma.

## Instrucciones

Leer `${CLAUDE_PLUGIN_ROOT}/commands/preflight.md` para la lógica completa
de validación (2 capas, 5 niveles).

### Resumen de validaciones

**Capa 1 — Estructural (determinista):**
- Nivel 1: Headings obligatorios presentes
- Nivel 2: Secciones no vacías
- Nivel 3: Formato correcto (rutas con backtick, commits, criterios como checkbox)
- Nivel 4: Cruces numéricos (allowlist ≥ archivos, denylist > 0, restricciones ≤ 10)

**Capa 2 — Semántico (requiere interpretación):**
- Campos obligatorios: objetivo, modo, scope fence, archivos, tests, aceptación
- Campos warning: restricciones, dependencias, complejidad, pasos concretos
- Cruces: archivos del spec vs allowlist, dependencias vs specs existentes

### Severidad

- **FAIL**: Corregir antes de ejecutar
- **PASS WITH WARNINGS**: Ejecutable pero revisar
- **PASS**: Listo para ejecución

NO ejecutar un sprint si hay specs con FAIL.
