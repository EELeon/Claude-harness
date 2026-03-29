# /learn — Captura de conocimiento post-ticket

Acabas de terminar de implementar: $ARGUMENTS

Ejecuta este ciclo de aprendizaje:

## 1. Reflexión

Revisa todo lo que pasó en este thread:
- ¿Qué errores cometiste que tuviste que corregir?
- ¿Qué archivos resultaron relevantes que no estaban en el spec?
- ¿Qué patrones del codebase descubriste que no sabías?
- ¿Hubo algo que el spec no cubría y tuviste que decidir?

## 2. Actualizar CLAUDE.md

Abre CLAUDE.md y agrega a la sección "🚫 NO hacer (lecciones aprendidas)":
- Una línea por cada error que cometiste, formulada como regla preventiva
- Formato: "No [hacer X] — [por qué falla] → [qué hacer en su lugar]"
- Solo agregar si la regla es generalizable (no específica a este ticket)

Si descubriste convenciones de código o reglas de dominio que faltan,
agregarlas a las secciones correspondientes.

## 3. Actualizar agentes (si aplica)

Si el error fue específico de un dominio que tiene agente custom
en `.claude/agents/`, actualizar el agente con la lección.

## 4. Registrar en done-tasks.md

Agregar al archivo `done-tasks.md` (crear si no existe):
```
## [fecha] — Ticket [N]: [título]
- Subtareas completadas: [lista]
- Tests: [pasaron/fallaron]
- Lecciones: [resumen de 1 línea]
- Tiempo aproximado de contexto usado: [bajo/medio/alto]
```

## 5. Preparar para el siguiente

Reporta:
- ✅ Qué se completó
- 📝 Qué se agregó a CLAUDE.md
- ⚠️ Cualquier deuda técnica detectada
- ➡️ Recomendación para el siguiente ticket

NO hagas /clear automáticamente — Edwin decide cuándo limpiar contexto.
