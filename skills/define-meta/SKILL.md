---
name: define-meta
description: >
  Definir o editar el meta del proyecto (.ai/meta.md). Usa este skill cuando el
  usuario diga: "definir meta", "crear meta", "editar meta", "visión del proyecto",
  "qué debe hacer el sistema", o cualquier referencia a definir las capacidades
  de alto nivel del sistema.
---

# Define Meta — Definir la visión del proyecto

## Propósito

Guiar al usuario para crear `.ai/meta.md`, el documento que describe
QUÉ debe ser capaz de hacer el sistema completo. Este documento es
la referencia contra la cual audita el loop recursivo.

## Plantilla

Leer `${CLAUDE_PLUGIN_ROOT}/templates/meta-template.md` para la estructura completa.

## Flujo

### Si no existe `.ai/meta.md`:

1. Preguntar al usuario (AskUserQuestion):
   "¿Cuál es la visión general del sistema? Describilo en 2-3 párrafos."

2. Con la respuesta, generar un borrador de `.ai/meta.md`:
   - Identificar dominios funcionales
   - Extraer capacidades con IDs únicos (DOMINIO-NN)
   - Definir criterios verificables para cada capacidad
   - Asignar prioridades (Alta/Media/Baja)
   - Identificar restricciones transversales
   - Configurar parámetros del loop recursivo con defaults razonables

3. Presentar el borrador al usuario para revisión

4. Iterar hasta que el usuario apruebe (AskUserQuestion para cada ronda)

5. Validar con la lógica de `${CLAUDE_PLUGIN_ROOT}/commands/validate-meta.md`

6. Guardar `.ai/meta.md` en el repo

### Si ya existe `.ai/meta.md`:

1. Leer el meta existente
2. Preguntar qué quiere cambiar (AskUserQuestion)
3. Aplicar cambios preservando IDs existentes
4. Revalidar
5. Guardar

## Reglas del meta

- Cada capacidad tiene ID único (DOMINIO-NN)
- Cada capacidad tiene criterio verificable por un agente (observable, no subjetivo)
- El meta es DECLARATIVO (qué) no IMPERATIVO (cómo)
- El meta es EXHAUSTIVO sobre el alcance funcional
- Solo el usuario modifica el meta — el loop recursivo NUNCA lo muta
