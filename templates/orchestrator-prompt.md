# Template para prompt orquestador de sprint

<!--
Este template se llena por el skill code-orchestrator en Cowork.
El resultado es un ÚNICO prompt que el usuario pega en Claude Code
para ejecutar un sprint completo de manera autónoma.

ESTRATEGIA DE CONTEXTO:
El orquestador usa una combinación de técnicas para no quedarse sin contexto:

1. SUBAGENTES: Cada ticket corre como subagente → contexto fresco automático.
   El orquestador solo recibe el resultado resumido, no todo el contexto intermedio.

2. ESTADO EN DISCO: El orquestador escribe progreso a results.tsv después de
   cada ticket. Si se corre /compact o /clear, puede retomar leyendo ese archivo.

3. COMPACTACIÓN PROACTIVA: Después de cada ticket, el orquestador evalúa su
   uso de contexto. Si está alto, le pide al usuario correr /compact antes
   de continuar.

4. PUNTOS DE CORTE: Para sprints largos (5+ tickets), el mega-prompt incluye
   puntos de pausa donde el usuario puede hacer /clear y re-pegar el prompt.
   El orquestador retoma desde donde se quedó leyendo results.tsv.

LIMITACIONES:
- Claude Code NO puede ejecutar /clear ni /compact programáticamente
- El orquestador PUEDE detectar que su contexto está lleno y PEDIR al usuario
  que ejecute estos comandos
- Los subagentes no pueden crear sub-subagentes
-->

```markdown
# Sprint [LETRA] — [Nombre temático]

## Instrucciones de orquestación

Ejecuta los tickets de este sprint en orden. Seguí estas reglas estrictamente:

### Regla 1: Cada ticket como subagente
Para cada ticket, lanzá un **subagente general-purpose** con el prompt
indicado abajo. NO implementes tickets directamente en el contexto principal
(excepto correcciones menores post-rollback).

### Regla 2: Verificación y rollback automático
Después de cada subagente:
1. Guardá el hash del commit anterior: `git rev-parse HEAD` (antes del subagente)
2. Verificá que el commit existe: `git log -1 --oneline`
3. Corré los tests del ticket: `[comando de tests]`
4. **Si los tests pasan:** registrá `keep` en `results.tsv` y continuá
5. **Si los tests fallan:** intentá una corrección rápida (máximo 2 intentos).
   Si no se resuelve, hacé rollback: `git reset --hard [hash anterior]`,
   registrá `discard` en `results.tsv`, y continuá con el siguiente ticket.
   NO te quedes trabado intentando arreglar un ticket roto indefinidamente.

### Regla 3: Autonomía total (NEVER STOP)
Una vez que empieces a ejecutar los tickets, NO pares a preguntar
"¿sigo?" o "¿es un buen punto para parar?". El usuario puede estar
durmiendo o lejos de la computadora. Continuá ejecutando tickets
hasta terminar el sprint completo o hasta que el usuario te interrumpa.

Las únicas razones válidas para pausar son:
- Necesitás que el usuario corra `/compact` (Regla 4)
- Llegaste a un punto de corte (Regla 5)
- Un error sistémico impide continuar (ej: el repo está roto)

### Regla 4: Gestión de contexto
Después de cada ticket completado o descartado:
1. Registrá el resultado en `results.tsv` (ver formato abajo)
2. Evaluá tu uso de contexto
3. Si sentís que tu contexto está pesado o llevás 3+ tickets completados,
   decile al usuario: **"Recomiendo correr /compact antes de continuar
   con el siguiente ticket. Tu progreso está guardado en results.tsv."**
4. Después de /compact, retomá leyendo `results.tsv` para saber qué falta

### Regla 5: Punto de corte (sprints largos)
Si este sprint tiene 5+ tickets, hay un **punto de corte** marcado abajo.
Al llegar al punto de corte:
1. Asegurate de que `results.tsv` está actualizado
2. Mostrá resumen de progreso parcial
3. Decile al usuario: **"Llegamos al punto de corte. Recomiendo:
   /clear y luego pegá de nuevo este prompt. Voy a retomar
   automáticamente desde el ticket [N] leyendo results.tsv."**

### Regla 6: Retomar después de /clear
Si al empezar este prompt encontrás que `results.tsv` ya tiene tickets
completados de este sprint, **saltá los tickets ya completados** y
continuá con el siguiente pendiente.

---

## Tickets de este sprint (en orden)

### 1. Ticket [N] — [Título]
- **Spec:** `specs/ticket-[N].md`
- **Complejidad:** [Simple|Media|Alta]
- **Prompt para subagente:**
  ```
  Lee e implementa el spec en `specs/ticket-[N].md`.

  Contexto del proyecto: [1-2 líneas del CLAUDE.md relevantes]

  Pasos:
  [Pasos copiados del spec]

  Tests: [comando exacto]
  Commit: "[tipo]: [descripción]"

  NO hagas: [restricciones del spec]
  ```

### 2. Ticket [N] — [Título]
- **Spec:** `specs/ticket-[N].md`
- **Complejidad:** [Simple|Media|Alta]
- **Prompt para subagente:**
  ```
  [Prompt autocontenido]
  ```

<!-- Para sprints de 5+ tickets, insertar aquí: -->
<!-- ### --- PUNTO DE CORTE --- -->
<!-- Antes de continuar, ejecutá la Regla 5 de arriba. -->

### 3. Ticket [N] — [Título]
...

<!-- Repetir para cada ticket del sprint -->

---

## Formato de results.tsv

Crear `results.tsv` al inicio del sprint (si no existe) con este header.
Usar tabs como separador (NO comas — rompen en descripciones).

```
ticket	commit	tests	status	description
```

Columnas:
1. **ticket** — número de ticket (ej: T-3)
2. **commit** — hash corto de 7 chars (ej: a1b2c3d). "0000000" para crashes
3. **tests** — passed / failed / crash
4. **status** — keep / discard / crash
5. **description** — qué se intentó hacer (1 línea)

Ejemplo:
```
ticket	commit	tests	status	description
T-1	a1b2c3d	passed	keep	block por nivel con tabla y capa DXF
T-5	b2c3d4e	passed	keep	capas eléctricas oficiales por frente físico
T-6	c3d4e5f	failed	discard	block pineado — tests de cuantificación fallaron
T-6	d4e5f6g	passed	keep	block pineado — fix: separar conteo de pineado
```

Nota: un ticket puede aparecer más de una vez si se descartó y reintentó.

---

## Al terminar todos los tickets

1. Corré la suite completa de tests: `[comando]`
2. Si hay fallos, corregí
3. Asegurate de que `results.tsv` está completo
4. Ejecutá `/learn sprint-[LETRA] completo` para:
   - Cross-referenciar lecciones contra CLAUDE.md existente (sin duplicar)
   - Agregar solo reglas nuevas que la experiencia real justifique
   - Evaluar si hace falta infraestructura adicional (agentes, hooks)
   - Registrar resumen del sprint en done-tasks.md
5. Mostrá resumen final:
   - Tickets: [N] keep / [N] discard / [N] crash
   - Cambios en CLAUDE.md (agregados, modificados, eliminados)
   - Infraestructura sugerida por /learn (si aplica)
   - Deuda técnica detectada
   - Estado de tests
   - Recomendación para el siguiente sprint
```

---

## Notas para el skill (NO incluir en el prompt generado)

### Cómo llenar este template

Para cada ticket del sprint:
1. Leer `specs/ticket-[N].md`
2. Ir a la sección "Prompt para el mega-prompt orquestador" del spec
3. Copiar ese bloque como base del prompt del subagente
4. Verificar que el prompt sea autocontenido:
   - ¿Tiene rutas exactas de archivos? Si no, agregarlas del spec
   - ¿Tiene pasos concretos? Si no, condensar de la sección de subtareas
   - ¿Tiene comando de tests? Si no, copiarlo de la sección de tests
   - ¿Tiene restricciones? Si no, copiarlas de la sección NO hacer
5. Agregar 1-2 líneas de contexto del CLAUDE.md relevantes al dominio

### Tipo de subagente a usar

Todos los tickets del mega-prompt usan subagentes **general-purpose**
porque necesitan leer, escribir, editar archivos y correr tests.

Los tipos Explore y Plan son para investigación previa — si un ticket
necesita exploración, esa fase va DENTRO del prompt del subagente
general-purpose como primer paso (ej: "1. Investigá la estructura
actual de X buscando en src/...")

### Regla del prompt autocontenido

Cada prompt de subagente debe funcionar SIN leer nada más que los
archivos del repo. El subagente NO tiene acceso a:
- La conversación de Cowork
- Los otros tickets del sprint
- El contexto del agente principal

Por eso cada prompt incluye las líneas relevantes del CLAUDE.md
y las restricciones específicas del ticket.

### Dónde poner el punto de corte

- En sprints de 5-6 tickets: después del ticket 3
- En sprints de 7+ tickets: después del ticket 3 y después del ticket 6
- Nunca cortar entre dos tickets con dependencia directa

### Cuándo sacar un ticket del mega-prompt

Si un ticket es de complejidad Alta Y tiene 4+ subtareas que
individualmente tocan 5+ archivos cada una:
- Sacarlo del mega-prompt
- Ejecutarlo como ticket independiente en el contexto principal
  (para que pueda usar subagentes internos)
- Marcar esto en el plan de ejecución con la nota "Ejecutar aparte"

### Estimación de contexto por ticket (heurística)

| Complejidad | Contexto del subagente | Contexto del orquestador |
|-------------|----------------------|------------------------|
| Simple | ~20k tokens | ~3k tokens (prompt + resultado) |
| Media | ~50k tokens | ~5k tokens |
| Alta | ~100k tokens | ~8k tokens |

Con un contexto de ~200k tokens para el orquestador:
- Puede manejar ~8-10 tickets simples antes de necesitar /compact
- ~5-6 tickets medios
- ~3-4 tickets altos
- Los puntos de corte se calibran con estas heurísticas
