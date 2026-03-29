# /learn — Captura de conocimiento post-ticket

Acabas de terminar de implementar: $ARGUMENTS

Ejecuta este ciclo de aprendizaje:

## 1. Reflexión

Revisa todo lo que pasó en este thread:
- ¿Qué errores cometiste que tuviste que corregir?
- ¿Qué archivos resultaron relevantes que no estaban en el spec?
- ¿Qué patrones del codebase descubriste que no sabías?
- ¿Hubo algo que el spec no cubría y tuviste que decidir?
- ¿Intentaste algo que falló? (candidato para sección "Intentos fallidos")

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

- **¿Hay reglas stale?** (referencian archivos borrados, APIs deprecated,
  o no se activaron en ningún ticket de results.tsv)
  Si sí → eliminarlas. Las reglas muertas diluyen la atención del modelo
  sobre las reglas críticas

## 3. Test de sustracción causal (gate obligatorio)

Para CADA regla que quieras agregar, preguntate:
> "¿Qué error CONCRETO cometería Claude SIN esta regla?"

- Si la respuesta es clara y específica → la regla pasa el test
- Si la respuesta es vaga ("podría confundirse", "es buena práctica") → NO agregar
- Si la regla describe algo que el modelo ya sabe por pre-training
  (e.g., "usar convenciones de React") → NO agregar

## 4. Umbral de confirmación (anti-ruido)

Antes de clasificar destino, verificar que la regla tiene peso suficiente:

| Evidencia | Acción |
|-----------|--------|
| El error ocurrió en 2+ tickets (buscar en results.tsv y done-tasks.md) | → Agregar a CLAUDE.md como regla permanente |
| El error ocurrió en 1 ticket pero causó rollback o pérdida significativa | → Agregar a CLAUDE.md marcada como `[1 ocurrencia]` |
| El error ocurrió en 1 ticket y fue menor (corregido rápido, sin rollback) | → Registrar SOLO en done-tasks.md como observación. NO agregar a CLAUDE.md todavía |
| El error es de un dominio que tiene agente custom | → Agregar al agente, no a CLAUDE.md |

**Lógica:** Una micro-regla de un solo incidente menor infla CLAUDE.md sin
evidencia de que el patrón se repita. Es mejor esperar a que se confirme
en un segundo ticket (via /learn de sprint o del siguiente ticket) antes
de promoverla a regla permanente.

**Excepción:** Si la regla previene pérdida de datos, corrupción, o un
error que no puede deshacerse con rollback → agregarla inmediatamente
sin importar cuántas ocurrencias tenga.

## 5. Clasificar el destino de cada regla

No todo va a CLAUDE.md. Clasificar cada regla que pasó el umbral:

| Destino | Criterio | Ejemplo |
|---------|----------|---------|
| **CLAUDE.md** | Regla de dominio o decisión que Claude no puede inferir | "NUNCA mezclar presupuesto con cotización" |
| **hooks/settings.json** | Regla procedural verificable por código | Lint, formato, permisos de archivos |
| **Intentos fallidos** | Camino muerto que NO se debe reintentar | "Intenté X y falló porque Y" |
| **Agente custom** | Regla específica de un dominio con agente en .claude/agents/ | Regla eléctrica → agente eléctrico |
| **No agregar** | Ya cubierta, redundante con pre-training, o no generalizable | "Usar camelCase en JS" |

## 6. Actualizar CLAUDE.md (solo reglas que pasaron umbral + sustracción)

Después de pasar el gate de sustracción causal:

**Para "NO hacer" (lecciones):**
- Formato IMPERATIVO: "NUNCA [hacer X] — [por qué falla] → [qué hacer en su lugar]"
- Solo agregar si la regla es generalizable (no específica a este ticket)

**Para "Intentos fallidos":**
- Formato: "Intenté [X] y falló porque [Y] — usar [Z] en su lugar"
- CRÍTICO: sin esta sección, Claude reintenta caminos muertos y gasta tokens

**Para convenciones o reglas de dominio:**
- Agregar a la sección correspondiente en forma imperativa (SIEMPRE/NUNCA)

**Meta-regla de simplicidad:** Después de actualizar, contar las líneas
de CLAUDE.md. Si supera 100 líneas, aplicar:
- Si borrar una regla no causa errores nuevos → borrarla es una mejora
- Dos reglas que dicen lo mismo → consolidar en una
- Una regla que nunca se activó en ningún ticket de results.tsv → eliminar
- Una regla que referencia archivos borrados o APIs deprecated → eliminar
- Simplificar redacción sin perder protección → siempre vale la pena

Un CLAUDE.md corto y preciso es más efectivo que uno largo y exhaustivo.

## 7. Actualizar agentes (si aplica)

Si el error fue específico de un dominio que tiene agente custom
en `.claude/agents/`, actualizar el agente con la lección.

## 8. Evaluar si hace falta nueva infraestructura

Basado en los patrones de este ticket y los anteriores:

- **¿Se repite el mismo tipo de error 3+ veces en results.tsv/done-tasks.md?**
  → Sugerir crear un agente custom para ese dominio
- **¿Claude declaró "listo" prematuramente en este ticket?**
  → Sugerir instalar el hook Stop si no está instalado
- **¿El spec era ambiguo en puntos que podrían haberse previsto?**
  → Sugerir mejorar el template de specs

NO crear la infraestructura automáticamente — sugerir al usuario
y dejar que decida.

## 9. Registrar en done-tasks.md

Agregar al archivo `done-tasks.md` (crear si no existe):
```
## [fecha] — Ticket [N]: [título]
- Subtareas completadas: [lista]
- Tests: [pasaron/fallaron]
- Lecciones: [resumen de 1 línea]
- Reglas nuevas en CLAUDE.md: [N agregadas, N modificadas, N eliminadas]
- Intentos fallidos registrados: [N]
- Reglas stale eliminadas: [N]
- Observaciones pendientes (no subieron a CLAUDE.md): [lista breve]
- Infraestructura sugerida: [ninguna | agente para X | hook Stop | etc.]
- Tiempo aproximado de contexto usado: [bajo/medio/alto]
```

## 10. Preparar para el siguiente

Reporta:
- Qué se completó
- Qué se cambió en CLAUDE.md (agregados, modificados, eliminados)
- Intentos fallidos registrados (previene reintentos costosos)
- Reglas stale eliminadas (mantiene CLAUDE.md limpio)
- Cualquier deuda técnica detectada
- Infraestructura sugerida (si aplica)
- Recomendación para el siguiente ticket

NO hagas /clear automáticamente — el usuario decide cuándo limpiar contexto.

$ARGUMENTS
