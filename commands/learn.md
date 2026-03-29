# /learn — Captura de conocimiento post-ticket

Acabas de terminar de implementar: $ARGUMENTS

Ejecuta este ciclo de aprendizaje:

## 1. Reflexión

Revisa todo lo que pasó en este thread:
- ¿Qué errores cometiste que tuviste que corregir?
- ¿Qué archivos resultaron relevantes que no estaban en el spec?
- ¿Qué patrones del codebase descubriste que no sabías?
- ¿Hubo algo que el spec no cubría y tuviste que decidir?

## 2. Cross-reference contra CLAUDE.md existente

ANTES de agregar cualquier regla nueva, leé CLAUDE.md completo y verificá:

- **¿Ya existe una regla que cubra este error?**
  Si sí → NO agregar duplicado. En su lugar, evaluá:
  - ¿La regla existente es clara? Si no, reformulala
  - ¿La regla existente fue ignorada? Si sí, movela a una posición más
    visible o marcala con mayor énfasis
  - Reportá: "La regla ya existía en línea N pero no la seguí porque [razón]"

- **¿La nueva regla contradice alguna existente?**
  Si sí → resolver la contradicción. Quedarse con la versión más correcta
  basada en la experiencia real de este ticket

- **¿Hay reglas existentes que este ticket demostró que son incorrectas?**
  Si sí → corregirlas o eliminarlas. Las reglas que no reflejan la
  realidad del codebase hacen más daño que bien

## 3. Actualizar CLAUDE.md (solo lo necesario)

Después del cross-reference, agregar a la sección "NO hacer (lecciones aprendidas)":
- Una línea por cada error NUEVO (que no estaba cubierto por reglas existentes)
- Formato: "No [hacer X] — [por qué falla] → [qué hacer en su lugar]"
- Solo agregar si la regla es generalizable (no específica a este ticket)

Si descubriste convenciones de código o reglas de dominio que faltan,
agregarlas a las secciones correspondientes.

**Meta-regla de simplicidad:** Después de actualizar, contar las líneas
de CLAUDE.md. Si supera 100 líneas, aplicar el criterio de simplicidad:
- Si borrar una regla no causa errores nuevos → borrarla es una mejora
- Dos reglas que dicen lo mismo → consolidar en una
- Una regla que nunca se activó en ningún ticket de results.tsv → eliminar
- Simplificar redacción sin perder protección → siempre vale la pena

Un CLAUDE.md corto y preciso es más efectivo que uno largo y exhaustivo.

## 4. Actualizar agentes (si aplica)

Si el error fue específico de un dominio que tiene agente custom
en `.claude/agents/`, actualizar el agente con la lección.

## 5. Evaluar si hace falta nueva infraestructura

Basado en los patrones de este ticket y los anteriores:

- **¿Se repite el mismo tipo de error 3+ veces en results.tsv/done-tasks.md?**
  → Sugerir crear un agente custom para ese dominio
- **¿Claude declaró "listo" prematuramente en este ticket?**
  → Sugerir instalar el hook Stop si no está instalado
- **¿El spec era ambiguo en puntos que podrían haberse previsto?**
  → Sugerir mejorar el template de specs

NO crear la infraestructura automáticamente — sugerir al usuario
y dejar que decida.

## 6. Registrar en done-tasks.md

Agregar al archivo `done-tasks.md` (crear si no existe):
```
## [fecha] — Ticket [N]: [título]
- Subtareas completadas: [lista]
- Tests: [pasaron/fallaron]
- Lecciones: [resumen de 1 línea]
- Reglas nuevas en CLAUDE.md: [N agregadas, N modificadas, N eliminadas]
- Infraestructura sugerida: [ninguna | agente para X | hook Stop | etc.]
- Tiempo aproximado de contexto usado: [bajo/medio/alto]
```

## 7. Preparar para el siguiente

Reporta:
- Qué se completó
- Qué se cambió en CLAUDE.md (agregados, modificados, eliminados)
- Cualquier deuda técnica detectada
- Infraestructura sugerida (si aplica)
- Recomendación para el siguiente ticket

NO hagas /clear automáticamente — el usuario decide cuándo limpiar contexto.

$ARGUMENTS
