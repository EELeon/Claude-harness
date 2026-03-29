# Template para CLAUDE.md de proyecto

<!--
REGLA: Mantener este archivo bajo 100 líneas / 2500 tokens.
Cada línea debe existir porque resolvió un problema real.
Si una regla no ha evitado un error concreto, borrarla.

CRITERIO DE SIMPLICIDAD:
Si borrar una regla no causa errores nuevos, borrarla es una mejora.
Si simplificar una regla la hace más clara sin perder protección, simplificarla.
Dos reglas que dicen lo mismo → consolidar en una.
Una regla que nunca se activa → eliminar.
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
- [Convención 1 — e.g., "Usar snake_case para funciones"]
- [Convención 2 — e.g., "Tests en tests/ con pytest"]
- [Convención 3 — e.g., "Imports absolutos, nunca relativos"]

## Reglas de dominio
<!-- Las reglas que Claude viola sin esta guía -->
- [Regla 1 — e.g., "Un pedido solo puede tener un estado a la vez"]
- [Regla 2 — e.g., "Nunca mezclar datos de producción con staging"]
- [Regla 3 — e.g., "Separar siempre validación de input vs lógica de negocio vs output"]

## 🚫 NO hacer (lecciones aprendidas)
<!-- Se actualiza con /learn después de cada ticket -->
- [Error que Claude cometió y cómo evitarlo]

## Workflow
- Siempre empezar leyendo el spec en `specs/ticket-N.md`
- Usar subagentes para subtareas marcadas en el spec
- Commit atómico después de cada subtarea
- Correr tests antes de marcar como completado
- Ejecutar `/learn` al terminar cada ticket para capturar lecciones
  y verificar que no se dupliquen reglas en este archivo
- Si se usa mega-prompt: el orquestador maneja las transiciones entre tickets
- Si se ejecuta manualmente: `/clear` entre tickets para contexto fresco
