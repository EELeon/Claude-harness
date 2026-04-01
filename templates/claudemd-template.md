# Template para CLAUDE.md de proyecto

<!--
META-REGLAS (reglas sobre cómo escribir reglas):
- Mantener este archivo bajo 100 líneas / ~2500 tokens
- Cada regla debe existir porque resolvió un problema real
- Usar forma IMPERATIVA: "SIEMPRE X" / "NUNCA Y" (94% compliance vs 73% descriptivo)
- Máximo 1-2 frases por regla + justificación breve si no es obvia
- Test de sustracción: "¿Qué error cometería Claude SIN esta regla?" — si no hay
  respuesta clara y concreta, no agregar la regla
- Reglas procedurales (lint, formato, permisos) → hooks/settings.json, NO aquí
- Reglas que el modelo ya sabe (e.g., "usar convenciones de React") → no agregar

CRITERIO DE SIMPLICIDAD:
Si borrar una regla no causa errores nuevos → borrarla es una mejora.
Dos reglas que dicen lo mismo → consolidar en una.
Una regla que nunca se activó en .ai/runs/results.tsv → eliminar.
Una regla que referencia archivos borrados o APIs deprecated → eliminar.
-->

# [Nombre del proyecto]

## Qué es
[1-2 frases describiendo el proyecto]

## Estructura
```
[Árbol de directorios — solo los folders principales]
```

## Comandos esenciales
```bash
# Instalar dependencias
[comando]

# Correr tests
[comando]

# Correr la app
[comando]

# Lint/format
[comando]
```

## Convenciones de código
- [SIEMPRE usar snake_case para funciones]
- [NUNCA usar imports relativos — SIEMPRE absolutos]
- [Tests en tests/ con pytest]

## Reglas de dominio
<!-- Reglas que Claude viola sin esta guía — forma imperativa obligatoria -->
- [NUNCA mezclar datos de producción con staging]
- [SIEMPRE separar validación de input vs lógica de negocio vs output]
- [Un pedido SOLO puede tener un estado a la vez]

## 🚫 NO hacer (lecciones aprendidas)
<!-- Se actualiza con /learn después de cada ticket -->
<!-- Formato: "NUNCA [hacer X] — [por qué falla] → [qué hacer en su lugar]" -->

## ❌ Intentos fallidos
<!-- Caminos muertos que Claude NO debe volver a explorar -->
<!-- Sin esta sección, Claude reintenta soluciones que ya fracasaron, inflando costos -->
<!-- Formato: "Intenté [X] y falló porque [Y] — usar [Z] en su lugar" -->

## Workflow
- SIEMPRE empezar leyendo el spec en `.ai/specs/active/ticket-N.md`
- SIEMPRE usar subagentes para subtareas marcadas en el spec
- SIEMPRE commit atómico después de cada subtarea
- SIEMPRE correr tests antes de marcar como completado
- SIEMPRE ejecutar `/learn` al terminar cada ticket
- Si se usa prompt del sprint: el orquestador maneja las transiciones entre tickets
- Si se ejecuta manualmente: `/clear` entre tickets para contexto fresco
