# SPEC: Pipeline de Captura de Decisiones

## Problema

El harness actual captura **qué** se hizo (specs, results.tsv, done-tasks.md)
pero no **por qué** se tomaron las decisiones. El razonamiento detrás de cada
decisión vive en tres lugares efímeros que se pierden:

1. **Transcript de Cowork** — cuando Edwin y Cowork discuten approaches durante
   la escritura de specs. Después de cerrar la sesión, el contexto muere.
2. **Contexto del subagente** — cuando Claude Code toma decisiones tácticas
   durante la implementación. Solo sobrevive el Heat Shield (3 líneas).
3. **Conversación de auditoría** — cuando se revisa la implementación y se
   detectan discrepancias. Los hallazgos quedan en chat, no en el repo.

### Consecuencias observables

- El siguiente sprint arranca sin saber por qué se eligió un approach sobre otro
- Si un ticket se descarta y se reintenta, el subagente no sabe qué ya se probó
- `/learn` captura lecciones pero no decisiones arquitectónicas
- `/retrospective` detecta patrones pero no puede trazar causas a decisiones específicas
- La auditoría no tiene un formato estructurado para retroalimentar al harness

---

## Diseño

### Principio rector

> Captura sin fricción: el agente ya sabe qué decisiones está tomando.
> Solo hay que darle un formato para registrarlas *en el momento*.

No es documentación narrativa. Es un registro mínimo y estructurado.

### Archivo canónico

```
.ai/decisions/
├── [nombre-batch].decisions.md    # UNO por batch, tres secciones
└── CONSOLIDATED.md                # Vista acumulativa cross-batch
```

**¿Por qué un archivo por batch y no uno global?**
- Los specs se archivan por batch (`.ai/specs/archive/[batch]/`)
- Las decisiones deben seguir el mismo ciclo de vida
- Al archivar, se mueve junto con los specs
- CONSOLIDATED.md es el que sobrevive entre batches (como done-tasks.md)

### Formato de cada entrada

```
### [ID] — [Título corto]
- **Fase:** spec | implementación | auditoría
- **Fecha:** YYYY-MM-DD
- **Decisión:** [Qué se decidió — 1 línea]
- **Motivo:** [Por qué — 1-2 líneas]
- **Alternativas descartadas:** [Qué se consideró y se rechazó]
- **Impacto:** [Qué cambia en el sistema como resultado]
- **Archivos afectados:** [Lista de rutas]
- **Tickets relacionados:** [T-N, T-M]
```

El ID es secuencial dentro del batch: `D-1`, `D-2`, etc.
El campo "Alternativas descartadas" es el más valioso — es lo que más se pierde.

---

## Fase 1: Captura durante escritura de specs (Cowork)

### Punto de integración: Paso 3 del flujo principal

Actualmente, el Paso 3 genera specs iterando sobre cada ticket. Las decisiones
de diseño ocurren *durante* esta iteración — cuando Cowork decide:

- Cómo dividir responsabilidades entre tickets
- Qué approach usar para un ticket complejo
- Qué archivos poner en scope fence y cuáles excluir
- Cómo resolver dependencias entre tickets
- Qué nivel de complejidad asignar y por qué

### Mecanismo: captura inline en el spec + registro en decisions

**Cambio 1 — Nueva sección opcional en spec-template.md:**

```markdown
## Decisiones de diseño (opcional)

<!--
Solo llenar si hubo una decisión no obvia durante la escritura de este spec.
No documentar lo que es evidente del objetivo o del contexto del proyecto.

Criterio: ¿alguien que lea este spec en 3 meses entendería POR QUÉ
se eligió este approach sin tener acceso al transcript de Cowork?
-->

- **D-[N]: [Título]** — [Decisión]. Alternativas: [X descartada porque Y].
```

**Cambio 2 — Nuevo paso 3.1: Consolidar decisiones del batch**

Después de generar todos los specs (Paso 3) y antes del preflight (Paso 3.5),
Cowork ejecuta un paso de consolidación:

1. Extraer todas las `## Decisiones de diseño` de los specs generados
2. Agregar decisiones de nivel batch (no atadas a un ticket específico):
   - Orden de ejecución y sus razones
   - Tickets excluidos del prompt y por qué
   - Dependencias entre tickets y cómo se resuelven
   - Puntos de corte y su justificación
3. Escribir `.ai/decisions/[nombre-batch].decisions.md` con la sección:

```markdown
# Decisiones — [nombre-batch]

## Fase 1: Diseño de specs (Cowork)
Fecha: YYYY-MM-DD

### Decisiones de batch
[Decisiones que aplican al batch completo]

### Decisiones por ticket
[Copiadas de cada spec, con referencia al ticket]
```

**Cambio 3 — Validación en preflight**

Agregar a la capa semántica de `commands/preflight.md`:

```
WARNING: Ticket [N] tiene complejidad Alta pero no tiene sección
"Decisiones de diseño". Considerar documentar el approach elegido.
```

Solo WARNING, nunca FAIL. Las decisiones son opcionales para tickets simples.

### Qué NO capturar en esta fase

- Decisiones triviales ("usé Python porque el proyecto es Python")
- Decisiones ya evidentes del objetivo del ticket
- Contexto que ya está en CLAUDE.md
- Preferencias personales sin impacto técnico

---

## Fase 2: Captura durante y después de implementación (Claude Code)

### Subphase 2a: Captura por subagente (durante ejecución)

**Punto de integración: Heat Shield (retorno del subagente)**

El Heat Shield actual devuelve:
- Resumen (1-3 líneas)
- Hash del commit
- Estado de tests
- Archivos tocados
- Criterios de aceptación (sí/no/parcial)

**Cambio 4 — Agregar campo de decisiones al Heat Shield:**

```
- Decisiones tácticas: [lista de decisiones no previstas en el spec]
```

El subagente reporta decisiones que tomó *fuera de lo que el spec definía*:
- "El spec decía modificar X pero era necesario refactorizar Y primero"
- "Usé approach Z en lugar del sugerido porque [razón]"
- "Agregué test para edge case no contemplado en el spec"
- "El archivo condicional fue necesario porque [condición]"

**Criterio para que el subagente reporte:** ¿hice algo que el spec no decía
explícitamente? Si sí, reportar. Si no, no reportar nada.

**Costo de contexto:** ~100-200 tokens adicionales por subagente. Aceptable
dado que el Heat Shield actual consume ~150-300 tokens.

### Subphase 2b: Captura por `/learn` (post-ticket)

**Punto de integración: Regla 7 (auto-learn por ticket)**

El `/learn` actual ya hace reflexión (paso 1) y cross-reference (paso 2).

**Cambio 5 — Nuevo paso 1.5 en `/learn`: registrar decisiones tácticas**

Después de la reflexión (paso 1) y antes del cross-reference (paso 2):

```markdown
## 1.5. Registrar decisiones de implementación

Si el subagente reportó decisiones tácticas en el Heat Shield:
1. Verificar si la decisión fue correcta (¿los tests pasaron? ¿scope ok?)
2. Si correcta → registrar en .ai/decisions/[batch].decisions.md
3. Si incorrecta (ticket descartado) → NO registrar como decisión,
   registrar como "intento fallido" en done-tasks.md (flujo existente)

Formato de registro:
### D-[N] — [Título corto]
- **Fase:** implementación
- **Fecha:** YYYY-MM-DD
- **Ticket:** T-[N]
- **Decisión:** [Qué decidió el subagente]
- **Motivo:** [Extracto del Heat Shield + contexto del learn]
- **Desviación del spec:** [Qué decía el spec vs qué se hizo]
- **Archivos afectados:** [Del diff]
- **Resultado:** keep | discard (con failure_category)
```

**Solo registrar decisiones de tickets con status `keep`.** Los `discard`
no producen decisiones válidas — producen intentos fallidos (flujo existente).

### Subphase 2c: Consolidación post-sprint

**Punto de integración: "Al terminar todos los tickets" en rules.md**

Actualmente, al terminar todos los tickets el orquestador:
1. Corre suite completa de tests
2. Ejecuta `/learn [batch] completo`
3. Archiva specs y limpia

**Cambio 6 — Nuevo paso entre 2 y 3: reconciliación de decisiones**

```markdown
## Reconciliación de decisiones post-sprint

Antes de archivar:

1. Leer .ai/decisions/[batch].decisions.md completo
2. Para cada decisión de Fase 1 (diseño):
   - ¿Se implementó como se planeó? → marcar "✅ implementada"
   - ¿Se desvió? → marcar "⚠️ desviada" con referencia a la decisión
     de Fase 2 que la reemplazó
   - ¿No se implementó (ticket descartado)? → marcar "❌ no implementada"
3. Generar resumen de reconciliación al final del archivo:

### Reconciliación
- Decisiones de diseño: [N] total
  - Implementadas como se planeó: [N]
  - Desviadas durante implementación: [N]
  - No implementadas (tickets descartados): [N]
- Decisiones tácticas nuevas (no previstas en specs): [N]
```

**Cambio 7 — Actualizar archivado**

Al archivar, mover el archivo de decisiones junto con los specs:

```bash
# Agregar a los comandos de limpieza existentes
mv .ai/decisions/[nombre-batch].decisions.md .ai/specs/archive/[nombre-batch]/
```

Y consolidar en CONSOLIDATED.md:

```bash
# Append al archivo consolidado (permanente)
cat .ai/decisions/[nombre-batch].decisions.md >> .ai/decisions/CONSOLIDATED.md
```

---

## Fase 3: Captura durante auditoría

### Contexto

La auditoría actualmente vive en `.ai/standards/` y se ejecuta externamente
(ChatGPT u otro agente). No tiene un formato estructurado para retroalimentar
al harness.

### Punto de integración: post-PR, pre-merge

La auditoría ocurre después de crear el PR y antes de mergearlo.

**Cambio 8 — Formato de hallazgos de auditoría**

El auditor (sea ChatGPT, otro agente, o un humano) escribe sus hallazgos
en un formato que el harness pueda consumir:

```markdown
## Fase 3: Auditoría
Fecha: YYYY-MM-DD
Auditor: [ChatGPT | humano | otro]

### Decisiones validadas
[Lista de D-N que la auditoría confirma como correctas]

### Decisiones cuestionadas
### A-[N] — [Título]
- **Decisión original:** D-[N] — [referencia]
- **Problema encontrado:** [Qué detectó la auditoría]
- **Severidad:** baja | media | alta | crítica
- **Recomendación:** [Qué hacer — revertir, ajustar, documentar como deuda]
- **Archivos afectados:** [Lista]

### Falsos cierres detectados
[Tickets que pasaron todas las reglas pero la auditoría encontró problemas]

### Decisiones faltantes
[Cosas que se hicieron sin decisión documentada — señal de captura insuficiente]
```

**Cambio 9 — Feedback loop: de auditoría a CLAUDE.md y specs**

Los hallazgos de auditoría alimentan tres destinos:

| Hallazgo | Destino | Mecanismo |
|----------|---------|-----------|
| Decisión correcta validada | Ninguno | Solo se marca ✅ en decisions |
| Decisión cuestionada (severa) | CLAUDE.md | Nueva regla vía `/learn` |
| Decisión cuestionada (menor) | done-tasks.md | Observación pendiente |
| Falso cierre | KNOWN_FALSE_CLOSURES.md | Nuevo archivo canónico |
| Patrón de spec ambiguo | spec-template.md | Mejora al template |

**Cambio 10 — Nuevo archivo canónico: KNOWN_FALSE_CLOSURES.md**

```markdown
# Falsos cierres conocidos

Tickets que pasaron scope audit + tests + criterios de aceptación
pero la auditoría detectó problemas no cubiertos por las validaciones.

| Batch | Ticket | Problema | Detectado por | Estado |
|-------|--------|----------|---------------|--------|
| [batch] | T-[N] | [descripción] | auditoría | abierto/resuelto |
```

Ubicación: `.ai/KNOWN_FALSE_CLOSURES.md` (permanente, como done-tasks.md).

Este archivo es input para el preflight de futuros batches — si un ticket
toca archivos asociados a un falso cierre abierto, el preflight emite WARNING.

---

## Mapa de archivos actualizado

```
repo-target/.ai/
├── decisions/
│   ├── [batch-actual].decisions.md   # Decisiones del batch en curso
│   └── CONSOLIDATED.md               # Historial acumulativo
├── KNOWN_FALSE_CLOSURES.md           # Falsos cierres detectados por auditoría
├── specs/
│   ├── active/
│   │   └── ticket-N.md              # Ahora con sección "Decisiones de diseño"
│   └── archive/
│       └── [batch-pasado]/
│           ├── ticket-N.md
│           └── [batch].decisions.md  # Archivado junto con specs
├── runs/
│   └── results.tsv                   # Sin cambios
├── prompts/
│   └── [batch].md                    # Sin cambios
├── rules.md                          # Cambios menores (Heat Shield)
├── plan.md                           # Sin cambios
├── done-tasks.md                     # Sin cambios (complementario)
└── standards/                        # Sin cambios
```

### Temporales vs permanentes (actualizado)

**Temporales** (se archivan al terminar):
`.ai/specs/active/*`, `.ai/rules.md`, `.ai/plan.md`, `.ai/runs/results.tsv`,
`.ai/decisions/[batch].decisions.md` (se mueve al archive)

**Permanentes** (sobreviven entre batches):
`.ai/decisions/CONSOLIDATED.md`, `.ai/KNOWN_FALSE_CLOSURES.md`,
`.ai/done-tasks.md`, `.ai/prompts/*`, `.ai/specs/archive/*`,
`.ai/standards/`, `CLAUDE.md`, `.claude/`

---

## Flujo completo con decisiones integradas

```
┌─────────────────────────────────────────────────────────────────┐
│                    COWORK (Fase 1: Specs)                        │
│                                                                  │
│  Paso 1  Inventario                                              │
│  Paso 2  Orden + Puntos de corte ──► decisiones de batch         │
│  Paso 3  Generar specs ──► decisiones por ticket (inline)        │
│  ★ 3.1   Consolidar decisiones ──► [batch].decisions.md          │
│  Paso 3.5 Preflight (+ warning si Alta sin decisiones)           │
│  Paso 4  Prompt + Reglas (Heat Shield actualizado)               │
│  Paso 5  Artefactos de soporte                                   │
│  Paso 6  Revisión con usuario                                    │
│                                                                  │
│  Output: .ai/decisions/[batch].decisions.md (Fase 1 completa)    │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│               CLAUDE CODE (Fase 2: Implementación)               │
│                                                                  │
│  Por cada ticket:                                                │
│    Subagente ejecuta ──► decisiones tácticas en Heat Shield      │
│    Reglas 2/2b/2c ──► verificación                               │
│    ★ /learn (paso 1.5) ──► registra decisiones en [batch].md     │
│    Regla 4 ──► results.tsv (sin cambios)                         │
│                                                                  │
│  Al terminar todos:                                              │
│    /learn final                                                  │
│    ★ Reconciliación ──► marca decisiones Fase 1 como             │
│      implementadas/desviadas/no implementadas                    │
│    Archivado ──► decisions se mueve a archive + CONSOLIDATED     │
│    PR                                                            │
│                                                                  │
│  Output: [batch].decisions.md (Fases 1+2, reconciliado)          │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AUDITORÍA (Fase 3: Validación)                   │
│                                                                  │
│  Auditor revisa PR + decisions                                   │
│    ──► Valida/cuestiona decisiones                               │
│    ──► Detecta falsos cierres                                    │
│    ──► Identifica decisiones faltantes                           │
│                                                                  │
│  ★ Feedback loop:                                                │
│    Hallazgos severos ──► CLAUDE.md (vía /learn)                  │
│    Falsos cierres ──► KNOWN_FALSE_CLOSURES.md                    │
│    Patrones de ambigüedad ──► mejora spec-template.md            │
│    Todo ──► append a [batch].decisions.md Fase 3                 │
│                                                                  │
│  Output: [batch].decisions.md (completo, tres fases)             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Costo y tradeoffs

### Tokens adicionales por fase

| Fase | Dónde | Tokens estimados | Justificación |
|------|-------|-----------------|---------------|
| 1 (specs) | Cowork | ~200-500 por ticket con decisiones | Solo tickets no triviales |
| 2a (Heat Shield) | Subagente → Orquestador | ~100-200 por ticket | Solo si hay desviación |
| 2b (/learn) | Claude Code | ~300-500 por ticket con decisiones | Integrado en /learn existente |
| 2c (reconciliación) | Claude Code | ~500-1000 total por batch | Una sola vez al final |
| 3 (auditoría) | Externo | 0 tokens del harness | Lo escribe el auditor |

**Total estimado:** ~1500-3000 tokens adicionales por batch de 6-8 tickets.
Es <2% del contexto del orquestador. Aceptable.

### Lo que se gana

- Trazabilidad completa: de la decisión de diseño al commit al hallazgo de auditoría
- Prevención de reintentos: el siguiente batch sabe qué approaches ya se probaron
- Retroalimentación estructurada: la auditoría alimenta directamente el harness
- Reconciliación: saber qué se planeó vs qué se hizo vs qué está bien

### Lo que no cambia

- El flujo principal de 6 pasos (se agrega 3.1, no se modifica ningún paso existente)
- El formato de results.tsv
- El formato de done-tasks.md
- La estructura de specs (sección nueva es opcional)
- Los comandos existentes (/learn, /retrospective, /preflight, /status)

### Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Captura excesiva (documentar todo) | Criterio explícito: solo decisiones no obvias |
| Subagente inventa decisiones para llenar el campo | Campo es opcional; solo reportar si hizo algo fuera del spec |
| Overhead en /learn (ya es largo) | Paso 1.5 es condicional: solo si hay decisiones tácticas |
| CONSOLIDATED.md crece indefinidamente | Mismo ciclo de limpieza que done-tasks.md en /retrospective |
| Auditor no sigue el formato | Template con campos obligatorios; preflight puede validar |

---

## Plan de implementación

### Prioridad 1 — Mínimo viable (captura funciona)

| # | Cambio | Archivo del harness a modificar | Esfuerzo |
|---|--------|---------------------------------|----------|
| 1 | Sección "Decisiones de diseño" en specs | `templates/spec-template.md` | Bajo |
| 2 | Paso 3.1 en flujo principal | `references/flujo-principal.md` | Bajo |
| 3 | Campo de decisiones en Heat Shield | `templates/orchestrator-prompt.md` (sección Heat Shield) | Bajo |
| 4 | Paso 1.5 en /learn | `commands/learn.md` | Medio |
| 5 | Crear carpeta .ai/decisions/ en bootstrap | `references/bootstrap.md` | Bajo |

### Prioridad 2 — Reconciliación y archivado

| # | Cambio | Archivo del harness a modificar | Esfuerzo |
|---|--------|---------------------------------|----------|
| 6 | Reconciliación post-sprint | `templates/orchestrator-prompt.md` (sección "Al terminar") | Medio |
| 7 | Archivado de decisions junto con specs | `references/entrega-sprint.md` + `templates/orchestrator-prompt.md` | Bajo |
| 8 | Warning en preflight para tickets Alta sin decisiones | `commands/preflight.md` | Bajo |

### Prioridad 3 — Auditoría y feedback loop

| # | Cambio | Archivo del harness a modificar | Esfuerzo |
|---|--------|---------------------------------|----------|
| 9 | Template de hallazgos de auditoría | Nuevo archivo: `templates/audit-findings-template.md` | Medio |
| 10 | KNOWN_FALSE_CLOSURES.md | Nuevo archivo canónico (template) | Bajo |
| 11 | Preflight: warning si ticket toca archivos de falso cierre abierto | `commands/preflight.md` | Medio |
| 12 | /retrospective consume decisions | `commands/retrospective.md` | Medio |

### Prioridad 4 — Consolidación y vista histórica

| # | Cambio | Archivo del harness a modificar | Esfuerzo |
|---|--------|---------------------------------|----------|
| 13 | CONSOLIDATED.md auto-append | `templates/orchestrator-prompt.md` (limpieza) | Bajo |
| 14 | Nuevo comando /decisions (consultar historial) | Nuevo: `commands/decisions.md` | Medio |

---

## Relación con archivos existentes

| Archivo existente | Relación con decisions | ¿Se modifica? |
|-------------------|----------------------|---------------|
| `results.tsv` | Decisions referencia tickets por ID que están en results | No |
| `done-tasks.md` | Complementario: done-tasks = qué pasó, decisions = por qué | No |
| `CLAUDE.md` | Destino de decisiones que se convierten en reglas permanentes | No (flujo existente vía /learn) |
| `spec-template.md` | Nueva sección opcional | Sí (Prioridad 1) |
| `flujo-principal.md` | Nuevo paso 3.1 | Sí (Prioridad 1) |
| `orchestrator-prompt.md` | Heat Shield ampliado + reconciliación + archivado | Sí (Prioridad 1 y 2) |
| `learn.md` | Nuevo paso 1.5 | Sí (Prioridad 1) |
| `preflight.md` | Warning para tickets complejos sin decisiones + falsos cierres | Sí (Prioridad 2 y 3) |
| `retrospective.md` | Consume CONSOLIDATED.md para análisis | Sí (Prioridad 3) |
| `bootstrap.md` | Crear .ai/decisions/ en setup inicial | Sí (Prioridad 1) |
| `entrega-sprint.md` | Actualizar mapa de archivos y reglas de archivado | Sí (Prioridad 2) |
