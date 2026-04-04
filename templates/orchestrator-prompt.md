# Template para prompt orquestador de sprint

<!--
Este template se llena por el skill code-orchestrator en Cowork.
El resultado es un prompt LEAN que Claude Code lee de disco.

UBICACIÓN DEL ARCHIVO GENERADO:
  .ai/prompts/sprint-[letra].md
Crear la carpeta si no existe: mkdir -p .ai/prompts

El usuario NO copia el prompt manualmente. Cowork le da una línea:
  Lee .ai/prompts/sprint-a.md y ejecutá el Sprint A completo.

PRINCIPIO DE DISEÑO:
El prompt del orquestador debe mantenerse en la zona segura de fidelidad
(~2-3K tokens). Para lograrlo:
- Las reglas de orquestación viven en un archivo separado en disco
  (.ai/rules.md) que el orquestador lee al inicio
- Los specs están en archivos separados (.ai/specs/active/ticket-N.md) que cada
  subagente lee desde su propio contexto fresco
- El prompt solo contiene: instrucción de leer reglas + lista de tickets

VENTAJAS vs prompt monolítico:
- El prompt cabe en la zona de fidelidad total (0-5K tokens)
- Sobrevive /compact sin paraphrase loss (es tan corto que no se parafrasea)
- Los specs se cargan frescos en el contexto de cada subagente (lazy loading)
- Agregar tickets no infla el prompt del orquestador
- Las reglas se pueden actualizar sin regenerar el prompt

ESTRATEGIA DE CONTEXTO (4 capas):
1. SUBAGENTES: Cada ticket corre como subagente → contexto fresco.
   El orquestador solo recibe el resultado resumido (Heat Shield).
2. ESTADO EN DISCO: .ai/runs/results.tsv persiste entre /compact y /clear.
3. COMPACTACIÓN PROACTIVA: Después de 3+ tickets, pedir /compact.
4. PUNTOS DE CORTE: Para sprints largos, pausar y re-pegar prompt.

LIMITACIONES:
- Claude Code NO puede ejecutar /clear ni /compact programáticamente
- Los subagentes no pueden crear sub-subagentes
- Máximo 5 subagentes concurrentes por codebase
-->

```markdown
# Sprint [LETRA] — [Nombre temático]

## Setup inicial
1. Creá la rama del sprint: `git checkout -b sprint-[letra]-[nombre]`
2. Lee las reglas de orquestación en `.ai/rules.md` y seguílas estrictamente.

## Tickets de este sprint (en orden)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | T-[N] — [Título] | `.ai/specs/active/ticket-[N].md` | [Simple/Media/Alta] |
| 2 | T-[N] — [Título] | `.ai/specs/active/ticket-[N].md` | [Simple/Media/Alta] |
| 3 | T-[N] — [Título] | `.ai/specs/active/ticket-[N].md` | [Simple/Media/Alta] |

<!-- Para sprints de 5+ tickets, insertar aquí: -->
<!-- ### --- PUNTO DE CORTE --- -->
<!-- Antes de continuar, ejecutá la Regla 5 de .ai/rules.md -->

| 4 | T-[N] — [Título] | `.ai/specs/active/ticket-[N].md` | [Simple/Media/Alta] |

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/ticket-[N].md`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, corré los tests, y commiteá. Devolvé: resumen (1-3 líneas), hash del commit, estado de tests (passed/failed), lista de archivos tocados, y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NO devuelvas logs completos ni output de tests.
2. Después del subagente, aplicá Reglas 2 + 2b + 2c (scope → tests → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn sprint-[LETRA] completo`
2. Creá el PR: `gh pr create --title "Sprint [LETRA]: [Nombre temático]" --body "$(cat .ai/runs/results.tsv)"`
```

---

## Archivo complementario: .ai/rules.md

<!--
Este archivo se genera junto con el prompt y se commitea al repo.
El orquestador lo lee al inicio de la ejecución.
Separar las reglas del prompt permite:
- Prompt ultra-lean (~1K tokens)
- Reglas detalladas sin inflar el prompt
- Actualizar reglas sin regenerar prompts
-->

```markdown
# Reglas de orquestación

Estas reglas gobiernan la ejecución autónoma de un sprint.
Seguílas estrictamente en el orden indicado.

## Regla 1: Cada ticket como subagente
Para cada ticket, lanzá un **subagente general-purpose** con el prompt
indicado en el prompt del sprint. El subagente lee el spec de disco.
NO implementes tickets directamente en el contexto principal
(excepto correcciones menores post-rollback).

## Regla 2: Verificación y rollback automático
**Nota:** Si el guard destructivo (PreToolUse) está instalado, NO bloquea
`git reset --hard` porque el rollback es intencional acá. El guard protege
contra usos accidentales; esta regla lo usa de forma controlada.

Después de cada subagente:
1. Guardá el hash del commit anterior: `git rev-parse HEAD` (antes del subagente)
2. Verificá que el commit existe: `git log -1 --oneline`
3. **Auditoría de scope** (ver Regla 2b abajo)
4. Corré los tests del ticket (el comando está en el spec)
5. **Si scope OK + tests pasan:** ejecutá Regla 2c (auditoría de completitud).
   Si completitud OK → registrá `keep` en `.ai/runs/results.tsv` y continuá.
6. **Si scope violation (archivos prohibidos tocados):** rollback inmediato:
   `git reset --hard [hash anterior]`, registrá `discard` con
   `failure_category=scope_violation` en `.ai/runs/results.tsv`, continuá
7. **Si los tests fallan:** intentá una corrección rápida (máximo 2 intentos).
   Si no se resuelve, hacé rollback: `git reset --hard [hash anterior]`,
   registrá `discard` con `failure_category=test_failure`, y continuá.
   NO te quedes trabado intentando arreglar un ticket roto indefinidamente.

## Regla 2b: Auditoría de scope por diff
Después de cada subagente, antes de correr tests:
1. Corré `git diff --name-only [hash anterior]..HEAD` para ver archivos tocados
2. Leé la sección "Scope fence" del spec del ticket
3. Clasificá cada archivo tocado:

| Archivo tocado | En allowlist | En denylist | Resultado |
|----------------|-------------|-------------|-----------|
| Está en permitidos | ✅ | — | OK |
| Está en prohibidos | — | ✅ | **BLOQUEANTE → rollback** |
| Está en condicionales | ✅ condicional | — | Verificar condición (ver abajo) |
| No está en ninguna lista | — | — | **WARNING** — registrar pero no bloquear |

- Si hay archivo en denylist → rollback automático, registrar `scope_violation`
- Si hay archivo fuera de toda lista → registrar warning en description de .ai/runs/results.tsv
  pero NO bloquear (el subagente puede haber tocado un test auxiliar legítimamente)
- Si faltan archivos de la allowlist → warning, no bloqueo
  (una buena implementación puede requerir tocar menos archivos)

**Archivos condicionales — verificación de condición:**
El spec define cada archivo condicional con formato:
`ruta/archivo.py` — solo si [condición en texto libre]

Para verificar si la condición se cumplió:
1. Leé el diff del archivo condicional (`git diff [hash]..HEAD -- [ruta]`)
2. Comparé el cambio contra la condición del spec
3. Clasificá:

| Situación | Resultado |
|-----------|-----------|
| El diff coincide con la condición (ej: "agregar helper" y el diff agrega una función) | OK |
| El diff NO coincide con la condición (ej: "agregar helper" pero refactorizó lógica existente) | **WARNING** — registrar "condicional fuera de condición" |
| El archivo condicional fue tocado pero la condición es ambigua | **WARNING** — registrar para revisión |

Los condicionales NUNCA bloquean. Son warnings para revisión.
Para que un condicional bloquee, debe estar en la denylist, no en condicionales.

## Regla 2c: Auditoría de completitud (criterios de aceptación)
Después de que scope (2b) y tests (2) pasen, verificar criterios de aceptación:

1. Leé la sección `## Criterios de aceptación` del spec del ticket
2. Para CADA criterio, verificá si se cumplió usando esta tabla:

| Tipo de criterio | Cómo verificar | Ejemplo |
|-----------------|----------------|---------|
| Archivo existe | `ls [ruta]` | "El archivo `config.json` existe en `/src`" |
| Función/clase existe | `grep -r "[nombre]" [archivo]` | "La clase `BlockManager` está definida en `block.py`" |
| Comportamiento | Comando de test específico o output | "El endpoint devuelve 200" |
| Integración | Evidencia en el diff o tests | "El módulo importa y usa `shared_utils`" |
| Negación | Verificar ausencia | "No hay console.log en código de producción" |

3. Clasificá el resultado:

| Criterios cumplidos | Resultado |
|--------------------|-----------|
| Todos | → `keep` con `failure_category=none` |
| ≥80% pero faltan menores | → `keep` con warning en description |
| <80% o falta alguno crítico | → `discard` con `failure_category=incomplete` |

**Qué es "criterio crítico":** cualquier criterio que, si no se cumple,
significa que el objetivo del ticket NO se logró. En duda, tratarlo como crítico.

4. Si `incomplete`: intentá una corrección rápida (máximo 1 intento).
   Si no se resuelve, rollback y registrar `incomplete` en .ai/runs/results.tsv.

**Orden completo de verificación post-subagente:**
Regla 2b (scope) → Regla 2 paso 4 (tests) → Regla 2c (completitud)
Si cualquier paso falla, NO ejecutar los siguientes. Registrar la
failure_category del PRIMER paso que falló.

## Regla 3: Autonomía total (NEVER STOP)
Una vez que empieces a ejecutar los tickets, NO pares a preguntar
"¿sigo?" o "¿es un buen punto para parar?". El usuario puede estar
durmiendo o lejos de la computadora. Continuá ejecutando tickets
hasta terminar el sprint completo o hasta que el usuario te interrumpa.

Las únicas razones válidas para pausar son:
- Necesitás que el usuario corra `/compact` (Regla 4)
- Llegaste a un punto de corte (Regla 5)
- Un error sistémico impide continuar (ej: el repo está roto)

## Regla 4: Gestión de contexto
Después de cada ticket completado o descartado:
1. Registrá el resultado en `.ai/runs/results.tsv` (ver formato abajo)
2. Evaluá tu uso de contexto
3. Si sentís que tu contexto está pesado o llevás 3+ tickets completados,
   decile al usuario: **"Recomiendo correr /compact antes de continuar
   con el siguiente ticket. Tu progreso está guardado en .ai/runs/results.tsv."**
4. Después de /compact, retomá leyendo `.ai/runs/results.tsv` para saber qué falta

**AVISO (paraphrase loss):** Cuando se comprime el contexto, las
instrucciones detalladas se parafrasean y pierden precisión. Por eso:
- Las reglas están en este archivo (releélo si tenés dudas)
- El estado está en .ai/runs/results.tsv (sobrevive cualquier compresión)
- Los specs están en disco (el subagente los lee frescos)
- NUNCA depender de "lo que recuerdo de tickets anteriores"

## Regla 5: Punto de corte (sprints largos)
Si el sprint tiene 5+ tickets, hay un **punto de corte** marcado en
el prompt del sprint. Al llegar:
1. Asegurate de que `.ai/runs/results.tsv` está actualizado
2. Mostrá resumen de progreso parcial
3. Decile al usuario: **"Llegamos al punto de corte. Recomiendo:
   /clear y luego pegá de nuevo el prompt del sprint. Voy a retomar
   automáticamente desde el ticket [N] leyendo .ai/runs/results.tsv."**

## Regla 6: Retomar después de /clear
Si al empezar encontrás que `.ai/runs/results.tsv` ya tiene tickets
completados de este sprint, **saltá los tickets ya completados** y
continuá con el siguiente pendiente.

## Patrón Heat Shield (retorno de subagentes)
El subagente devuelve SOLO:
- Resumen de qué se hizo (1-3 líneas)
- Hash del commit
- Estado de tests (passed/failed + nombre del test fallido si aplica)
- Archivos tocados
- Estado de criterios de aceptación (sí/no/parcial por cada uno)

NO devuelve logs completos, contenido de archivos, ni output de tests.
Esto protege tu contexto de acumular información innecesaria.

**Uso del reporte de criterios:** El orquestador usa este reporte en
Regla 2c para verificar completitud. Si el subagente reporta "parcial"
o "no" en algún criterio, el orquestador verifica independientemente
antes de decidir keep/discard.

## Regla 7: Auto-learn por ticket
Después de cada ticket con status `keep`, ejecutá `/learn ticket-[N] [título]`
ANTES de pasar al siguiente ticket. Esto captura lecciones en caliente.

El `/learn` de sprint al final (paso "Al terminar todos los tickets")
sigue existiendo para síntesis y consolidación del sprint completo.
Son dos niveles complementarios:
- `/learn` por ticket = captura en caliente, reglas específicas
- `/learn` de sprint = síntesis, consolidación, sugerencia de infraestructura

Para tickets con status `discard`, NO correr /learn (no hay lección útil
de una implementación que se descartó por completo).

## Formato de .ai/runs/results.tsv

Crear `.ai/runs/results.tsv` al inicio del sprint (si no existe) con este header.
Usar tabs como separador (NO comas).

```
ticket	commit	tests	status	failure_category	description
```

Columnas:
1. **ticket** — número de ticket (ej: T-3)
2. **commit** — hash corto de 7 chars. "0000000" para crashes
3. **tests** — passed / failed / crash
4. **status** — keep / discard / crash
5. **failure_category** — categoría del fallo (ver tabla). "none" si keep
6. **description** — qué se intentó hacer (1 línea)

Categorías de fallo:
| Categoría | Quién la detecta | Cuándo se escribe | Criterio operativo |
|-----------|-----------------|-------------------|-------------------|
| `none` | Orquestador | Después de Regla 2c | Todo OK: scope limpio + tests pasan + aceptación cumplida |
| `scope_violation` | Orquestador (Regla 2b) | Después del diff audit | `git diff --name-only` muestra archivos en la denylist del spec |
| `test_failure` | Orquestador (Regla 2) | Después de 2 intentos fallidos | El comando de tests del spec devuelve exit code ≠ 0 tras 2 correcciones |
| `incomplete` | Orquestador (Regla 2c) | Después de auditoría de completitud | ≥1 criterio de aceptación del spec NO cumplido (ver Regla 2c) |
| `rationalization` | Hook Stop → Orquestador | Cuando el hook bloquea | El hook Stop devuelve exit code 2 (bloqueo). Si no hay hook instalado, el orquestador detecta: subagente reporta "completado" pero el diff tiene 0 archivos tocados, o los archivos tocados no coinciden con ningún paso del spec |
| `spec_ambiguity` | Orquestador | Después de resultado anómalo | El subagente devuelve resultado que NO corresponde al objetivo del spec (ej: implementó algo diferente a lo pedido), O el subagente reporta que tuvo que "interpretar" o "asumir" algo no definido en el spec |

## Al terminar todos los tickets

1. Corré la suite completa de tests
2. Si hay fallos, corregí
3. Asegurate de que `.ai/runs/results.tsv` está completo
4. Ejecutá `/learn sprint-[LETRA] completo`
5. **Limpieza de artefactos de sprint:**
   Archivá los specs y borrá los artefactos temporales.
   **Ejecutá estos comandos exactos (no omitir mkdir -p):**
   ```bash
   # Crear carpeta de archivo si no existe
   mkdir -p .ai/specs/archive/sprint-[LETRA]
   # Mover specs al archivo
   mv .ai/specs/active/* .ai/specs/archive/sprint-[LETRA]/
   # Borrar artefactos temporales
   rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv
   # Commit de limpieza
   git add -A && git commit -m "chore: archivar specs y limpiar sprint [LETRA]"
   ```
   **NO borrar:** `.ai/done-tasks.md` (acumulativo entre sprints),
   `.ai/prompts/*` (historial permanente), `.ai/standards/`,
   `CLAUDE.md`, ni nada en `.claude/`.
6. Mostrá resumen final:
   - Tickets: [N] keep / [N] discard / [N] crash
   - Cambios en CLAUDE.md
   - Infraestructura sugerida por /learn
   - Estado de tests
   - Recomendación para el siguiente sprint
```

---

## Notas para el skill (NO incluir en los archivos generados)

### Cómo generar el prompt del sprint

1. Crear la carpeta: `mkdir -p .ai/prompts`
2. Listar los tickets del sprint en orden de ejecución
3. Para cada ticket: solo número, título, ruta del spec, y complejidad
4. El prompt del subagente es genérico — apunta al spec en disco
5. Si hay 5+ tickets: insertar punto de corte después del ticket 3
   (o después del 3 y 6 si hay 7+)
6. Nunca cortar entre tickets con dependencia directa
7. Guardar como `.ai/prompts/sprint-[letra].md`
8. Entregar al usuario la línea de ejecución:
   `Lee .ai/prompts/sprint-[letra].md y ejecutá el Sprint [LETRA] completo.`

### Cómo generar .ai/rules.md

1. Copiar el bloque de arriba
2. Personalizar el comando de tests si el proyecto lo requiere
3. Commitear al repo junto con los specs

### Cuándo sacar un ticket del prompt del sprint

Si un ticket es de complejidad Alta Y tiene 4+ subtareas que
individualmente tocan 5+ archivos cada una:
- Sacarlo del prompt del sprint
- Ejecutarlo como ticket independiente en el contexto principal
  (para que pueda usar subagentes internos)
- Marcar esto en el plan de ejecución con la nota "Ejecutar aparte"

### Estimación de contexto por ticket (heurística)

| Complejidad | Contexto del subagente | Contexto del orquestador |
|-------------|----------------------|------------------------|
| Simple | ~20k tokens | ~2k tokens (prompt + resultado Heat Shield) |
| Media | ~50k tokens | ~3k tokens |
| Alta | ~100k tokens | ~5k tokens |

Con un contexto de ~200k tokens para el orquestador:
- Puede manejar ~10-12 tickets simples antes de necesitar /compact
- ~6-8 tickets medios
- ~4-5 tickets altos
- Los puntos de corte se calibran con estas heurísticas

Nota: las estimaciones del orquestador son menores que antes porque
el prompt es lean y los subagentes retornan solo Heat Shield.
