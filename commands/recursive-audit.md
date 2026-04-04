# /recursive-audit — Loop recursivo de auditoría contra meta

Ejecuta el loop de auditoría recursiva contra el meta del proyecto. $ARGUMENTS

<!--
Este comando implementa el ciclo: audit → analyze → plan → spec → implement → repeat
hasta que no queden gaps abiertos o se alcance un criterio de parada.

PREREQUISITOS:
- .ai/meta.md debe existir y pasar /validate-meta
- El repo debe tener CLAUDE.md y la infraestructura del orquestador instalada

MODELO DE CONTEXTO:
El loop usa 3 subagentes secuenciales (no coexisten en memoria).
Cada uno lee del disco y escribe al disco. El bus de comunicación es el filesystem.

  Subagente 1: AUDITOR (Explore) ← el más pesado (~60-100K tokens)
    Lee: meta.md + código fuente
    Escribe: .ai/audit/iteration-N/raw-gaps.md

  Subagente 2: ANALISTA+PLANIFICADOR (Plan) ← liviano (~35K tokens)
    Lee: raw-gaps.md + results.tsv + done-tasks.md
    Escribe: .ai/audit/iteration-N/plan.md

  Subagente 3: SPEC WRITER (General-purpose) ← moderado (~40-70K tokens)
    Lee: plan.md + meta.md
    Escribe: .ai/specs/active/ticket-N.md (uno por gap)

Después de los 3 subagentes, el ORCHESTRATOR EXISTENTE implementa los specs.
Al terminar la implementación, el loop vuelve al paso 1 (auditor).

CUÁNDO ESCALAR A 4 SUBAGENTES:
Si el meta tiene 30+ capacidades Y el codebase tiene 100+ archivos sustantivos,
un solo auditor puede necesitar 150K+ tokens. En ese caso, si audit_split = "by_domain",
se lanzan 2 auditores en paralelo, cada uno cubriendo dominios distintos del meta.
-->

## Instrucciones

### Paso 0 — Validación previa

1. Verificar que `.ai/meta.md` existe. Si no → FAIL: "Falta .ai/meta.md. Usá el skill code-orchestrator para definirlo o crealo manualmente siguiendo templates/meta-template.md."
2. Ejecutar la lógica de `/validate-meta`. Si FAIL → parar y reportar errores.
3. Leer los parámetros del loop de `.ai/meta.md` sección `## Parámetros del loop recursivo`:
   - `max_iterations`
   - `coverage_threshold`
   - `diminishing_returns`
   - `priority_cutoff`
   - `audit_split`
4. Crear carpeta de auditoría: `mkdir -p .ai/audit`

### Paso 1 — AUDITOR (Subagente Explore)

Lanzar un subagente **Explore** (read-only) con este prompt:

> Sos un auditor de completitud. Tu trabajo es comparar el estado actual del código contra el meta del proyecto y encontrar gaps.
>
> **Lee estos archivos:**
> 1. `.ai/meta.md` — el documento meta con las capacidades requeridas
> 2. `CLAUDE.md` — contexto del proyecto
>
> **Para cada capacidad del meta** (filtrar por priority_cutoff = [valor]):
> 1. Lee el criterio verificable
> 2. Explorá el código usando Glob, Grep, y Read para determinar si la capacidad está implementada
> 3. Clasificá cada capacidad:
>
> | Estado | Criterio |
> |--------|----------|
> | **IMPLEMENTADA** | El criterio verificable se cumple — encontraste evidencia concreta en el código |
> | **PARCIAL** | Hay implementación pero no cumple completamente el criterio |
> | **AUSENTE** | No hay evidencia de implementación |
> | **NO VERIFICABLE** | El criterio no se puede evaluar con herramientas read-only |
>
> **Para restricciones transversales:**
> Verificar cada restricción contra el código existente. Buscar violaciones activas.
>
> **Escribí el resultado en** `.ai/audit/iteration-[N]/raw-gaps.md` con este formato:
>
> ```markdown
> # Auditoría — Iteración [N]
>
> Fecha: [fecha]
> Meta: .ai/meta.md
> Priority cutoff: [valor]
>
> ## Resumen
> - Capacidades auditadas: [N]
> - Implementadas: [N]
> - Parciales: [N]
> - Ausentes: [N]
> - No verificables: [N]
> - Cobertura: [%] (implementadas / auditadas)
>
> ## Capacidades implementadas
> | ID | Capacidad | Evidencia |
> |----|-----------|-----------|
> | [ID] | [nombre] | [archivo/función/test que lo demuestra] |
>
> ## Gaps encontrados
> | ID | Capacidad | Estado | Evidencia / Razón |
> |----|-----------|--------|-------------------|
> | [ID] | [nombre] | PARCIAL/AUSENTE | [Qué falta o qué se encontró incompleto] |
>
> ## Violaciones de restricciones transversales
> | ID | Restricción | Archivo | Violación |
> |----|-------------|---------|-----------|
> | [ID] | [nombre] | [archivo] | [Qué viola y cómo] |
>
> ## No verificables
> | ID | Capacidad | Razón |
> |----|-----------|-------|
> | [ID] | [nombre] | [Por qué no se pudo verificar] |
> ```
>
> IMPORTANTE: Sé riguroso. "No encontré evidencia" = AUSENTE, no "probablemente está".
> Cada clasificación debe tener evidencia concreta (ruta de archivo, nombre de función, output de grep).

**Si audit_split = "by_domain":** Lanzar 2 auditores en paralelo.
Dividir los dominios del meta en dos mitades equilibradas (por cantidad de capacidades).
Auditor 1 escribe `raw-gaps-1.md`, Auditor 2 escribe `raw-gaps-2.md`.
Después, concatenar ambos en `raw-gaps.md` antes de pasar al paso 2.

**Heat Shield del auditor:**
El orquestador recibe solo:
- Fase: AUDIT
- Gaps encontrados: [N]
- Cobertura: [%]
- Archivo: .ai/audit/iteration-[N]/raw-gaps.md
- Status: OK / FAIL

### Paso 2 — Evaluar criterios de parada

Leer `.ai/audit/iteration-[N]/raw-gaps.md` y evaluar:

| Criterio | Condición | Resultado |
|----------|-----------|-----------|
| Sin gaps | Gaps encontrados = 0 | → **FIN ✓** — reportar cobertura total |
| Max iterations | Iteración actual ≥ max_iterations | → **FIN** — reportar gaps restantes |
| Coverage threshold | Cobertura ≥ coverage_threshold% | → **FIN** — reportar gaps menores restantes |
| Diminishing returns | Gaps cerrados en esta iteración < diminishing_returns | → **FIN** — reportar que el progreso es insuficiente |

Si ningún criterio de parada se cumple → continuar al paso 3.

**Nota sobre diminishing returns:** En la primera iteración no aplica (no hay iteración
anterior para comparar). A partir de la iteración 2, comparar gaps de iteración N
contra gaps de iteración N-1. Si la diferencia < diminishing_returns → parar.

### Paso 3 — ANALISTA+PLANIFICADOR (Subagente Plan)

Lanzar un subagente **Plan** (read-only) con este prompt:

> Sos un analista y planificador. Tu trabajo es tomar los gaps crudos de la auditoría
> y producir un plan de implementación priorizado.
>
> **Lee estos archivos:**
> 1. `.ai/audit/iteration-[N]/raw-gaps.md` — gaps de la auditoría
> 2. `.ai/runs/results.tsv` — resultados de implementaciones anteriores (si existe)
> 3. `.ai/done-tasks.md` — lecciones aprendidas (si existe)
> 4. `.ai/meta.md` — para contexto de prioridades y dependencias
>
> **Análisis:**
> 1. **Deduplicar**: Si un gap aparece en múltiples formas, consolidar
> 2. **Filtrar**: Eliminar gaps que ya se intentaron implementar y fallaron
>    (buscar en results.tsv con status=discard + same description)
> 3. **Priorizar**: Ordenar por prioridad del meta (Alta > Media > Baja),
>    luego por dependencias técnicas, luego por dominio compartido
> 4. **Estimar complejidad**: Para cada gap, estimar Simple/Media/Alta
>    basándote en el código existente y el alcance del cambio
> 5. **Detectar dependencias**: Si gap A requiere gap B implementado primero, marcarlo
> 6. **Agrupar**: Gaps del mismo dominio que tocan archivos similares van juntos
>
> **Escribí el resultado en** `.ai/audit/iteration-[N]/plan.md`:
>
> ```markdown
> # Plan de implementación — Iteración [N]
>
> Gaps a cerrar: [N] (de [M] encontrados, [K] filtrados)
>
> ## Orden de ejecución
>
> | # | Gap ID | Capacidad | Complejidad | Dependencias | Dominio |
> |---|--------|-----------|-------------|-------------|---------|
> | 1 | [ID] | [nombre] | [S/M/A] | [ninguna/ID] | [dominio] |
>
> ## Gaps filtrados (no implementar)
>
> | Gap ID | Razón de filtrado |
> |--------|-------------------|
> | [ID] | [Ya se intentó y falló por X / duplicado de Y] |
>
> ## Notas para el spec writer
> - [Observaciones sobre el código existente que ayudan a escribir specs]
> - [Archivos clave que los specs deben referenciar]
> - [Patrones del codebase que los specs deben seguir]
> ```

**Heat Shield del analista+planificador:**
- Fase: PLAN
- Gaps a implementar: [N]
- Gaps filtrados: [N]
- Archivo: .ai/audit/iteration-[N]/plan.md
- Status: OK / FAIL

**Si gaps a implementar = 0 después de filtrar:** → **FIN** — todos los gaps
restantes fueron ya intentados o son duplicados. Reportar al usuario.

### Paso 4 — SPEC WRITER (Subagente General-purpose)

Lanzar un subagente **general-purpose** (write) con este prompt:

> Sos un escritor de specs para el orquestador de Claude Code.
> Tu trabajo es convertir gaps de auditoría en specs implementables.
>
> **Lee estos archivos:**
> 1. `.ai/audit/iteration-[N]/plan.md` — plan priorizado de gaps
> 2. `.ai/meta.md` — meta del proyecto (para criterios verificables)
> 3. `CLAUDE.md` — contexto del proyecto
>
> **Para cada gap en el plan**, generá un spec en `.ai/specs/active/` siguiendo
> EXACTAMENTE la estructura de la plantilla de specs del orquestador:
>
> - **Objetivo**: derivado de la capacidad del meta
> - **Scope fence**: inferido del código existente (Glob/Grep para encontrar archivos relevantes)
> - **Tests**: derivados del criterio verificable del meta
> - **Criterios de aceptación**: mapeados directamente del criterio verificable del meta
> - **Archivo naming**: `ticket-[ID-del-gap].md` (ej: `ticket-AUTH-03.md`)
>
> IMPORTANTE: Cada spec debe ser AUTOCONTENIDO (ver checklist de autocontención en la plantilla).
> El subagente que lo implemente NO tiene acceso al meta ni al plan — solo al spec.
>
> Después de escribir todos los specs, ejecutá la lógica de preflight
> (validación de commands/preflight.md) sobre los specs generados.
> Si alguno tiene FAIL, corregilo antes de terminar.

**Heat Shield del spec writer:**
- Fase: SPECS
- Specs generados: [N]
- Preflight: [PASS/FAIL]
- Archivos: .ai/specs/active/ticket-[ID].md × N
- Status: OK / FAIL

### Paso 5 — IMPLEMENTACIÓN (Orchestrator existente)

Con los specs generados en `.ai/specs/active/`, ejecutar el pipeline
estándar del orquestador:

1. Generar `.ai/rules.md` (si no existe) con las reglas de orquestación
2. Para cada spec: lanzar subagente → verificar (scope + tests + completitud) → registrar
3. `/learn` después de cada ticket kept
4. Registrar todo en `.ai/runs/results.tsv`

**NO crear PR al terminar este paso.** El loop puede tener más iteraciones.
**NO archivar specs todavía.** Se archivan al finalizar todo el loop.

### Paso 6 — Preparar siguiente iteración

1. Archivar artifacts de auditoría: ya están en `.ai/audit/iteration-[N]/`
2. Mover specs implementados a archivo temporal:
   ```bash
   mkdir -p .ai/specs/archive/audit-iteration-[N]
   mv .ai/specs/active/* .ai/specs/archive/audit-iteration-[N]/
   ```
3. Limpiar results.tsv para la siguiente iteración (guardar copia):
   ```bash
   cp .ai/runs/results.tsv .ai/audit/iteration-[N]/results.tsv
   rm -f .ai/runs/results.tsv
   ```
4. Incrementar iteración y **volver al Paso 1**

### Paso 7 — Finalización del loop

Cuando un criterio de parada se cumple (Paso 2):

1. Generar reporte final:
   ```bash
   mkdir -p .ai/audit
   ```
   Escribir `.ai/audit/summary.md`:

   ```markdown
   # Auditoría recursiva — Resumen final

   Meta: .ai/meta.md
   Iteraciones ejecutadas: [N]
   Razón de parada: [sin gaps / max iterations / coverage threshold / diminishing returns]

   ## Progreso por iteración

   | Iteración | Gaps encontrados | Gaps cerrados | Cobertura |
   |-----------|-----------------|---------------|-----------|
   | 1 | [N] | [N] | [%] |
   | 2 | [N] | [N] | [%] |

   ## Cobertura final

   Capacidades del meta: [N]
   Implementadas: [N] ([%])
   Parciales: [N]
   Ausentes: [N]
   No verificables: [N]

   ## Gaps abiertos (si quedan)

   | ID | Capacidad | Razón de no cierre |
   |----|-----------|-------------------|
   | [ID] | [nombre] | [max iterations / filtrado / implementación fallida] |

   ## Violaciones de restricciones pendientes

   | ID | Restricción | Archivo | Estado |
   |----|-------------|---------|--------|
   ```

2. Archivar todo:
   ```bash
   mkdir -p .ai/specs/archive/recursive-audit-[fecha]
   # Los specs de cada iteración ya están en archive/audit-iteration-N/
   ```

3. Limpiar temporales:
   ```bash
   rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv
   ```

4. Ejecutar `/learn recursive-audit [fecha] completo`

5. **Ahora sí:** crear el PR con el resumen de la auditoría

6. Mostrar al usuario:
   - Cobertura final vs meta
   - Gaps que quedaron abiertos (si hay)
   - Capacidades que el meta no cubre pero el código tiene (bonus)
   - Recomendación: ¿el meta necesita actualizarse?

## Gestión de contexto del loop

El loop puede ser largo (3+ iteraciones × 3 subagentes + implementación).
Gestión de contexto:

- **Después de cada iteración completa:** ofrecer `/compact`
- **Si el contexto está pesado:** sugerir `/clear` y re-ejecutar `/recursive-audit`
  El comando detecta iteraciones previas en `.ai/audit/iteration-*/` y continúa
  desde la siguiente iteración (lee el último raw-gaps.md para saber el estado)
- **Estado en disco:** Todo el estado del loop está en `.ai/audit/` — sobrevive
  `/compact` y `/clear`

## Resumir después de /clear

Si al ejecutar `/recursive-audit` ya existen carpetas `.ai/audit/iteration-*/`:
1. Encontrar la última iteración completada (tiene raw-gaps.md + plan.md + results.tsv)
2. Leer el raw-gaps.md de la última iteración para saber cobertura actual
3. Continuar desde la siguiente iteración
4. Reportar: "Retomando auditoría recursiva desde iteración [N+1]. Iteraciones previas: [resumen]"

$ARGUMENTS
