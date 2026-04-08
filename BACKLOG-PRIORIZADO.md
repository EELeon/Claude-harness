# Backlog Priorizado — Code Orchestrator

Consolidación de mejoras extraídas de: análisis del paper HERA (2604.00901v2), auditoría de 926 sesiones de token usage, notas de ideas/bugs, y análisis comparativo del harness actual.

Fecha: 2026-04-07

---

## Prioridad 1 — Alto impacto, esfuerzo bajo-medio

Estas mejoras atacan las brechas más grandes del harness actual y tienen el mejor ratio costo/beneficio.

### 1.1 Result Budgeting formal (presupuesto de salidas)

**Problema:** Hoy el harness deja pasar salidas completas de herramientas al contexto (logs de tests, diffs largos, outputs de bash). Esto contamina el contexto, acelera la compactación y causa deriva.

**Solución:** Definir límites formales por tipo de salida:

- `summary_max_chars`: resúmenes de iteración
- `test_output_max_chars`: resultados de tests
- `diff_excerpt_max_chars`: diffs de código
- `log_preview_max_chars`: logs de ejecución

**Regla:** Si una salida excede el límite → guardarla en `.ai/artifacts/[tipo]/` y retornar solo: resumen, tamaño, ruta del archivo, y primeras N líneas.

**Principio clave (del paper HERA):** "No toda salida merece entrar al contexto." La experience library de HERA funciona precisamente porque filtra y comprime información antes de inyectarla. El harness debe hacer lo mismo con outputs de herramientas.

**Implementación:**
- Nuevo archivo `.ai/output-budgets.md` con los límites por tipo
- Modificar Heat Shield para que aplique truncamiento antes de reportar
- Los artifacts persistidos a disco se referencian por ruta, no por contenido
- El ledger (`results.tsv`) trabaja sobre resúmenes, nunca sobre logs completos

**ROI:** Muy alto. Reduce ruido, mejora reanudación, baja riesgo de deriva.

---

### 1.2 Clases de ejecución / concurrencia formal

**Problema:** El criterio actual de paralelismo ("no compartir archivos") es insuficiente. No captura config compartida, scripts globales, generación de tipos, lockfiles, migraciones, ni efectos laterales.

**Solución:** En cada spec o ticket, un campo obligatorio:

```
execution_class: read_only | isolated_write | shared_write | repo_wide
```

**Reglas de scheduling:**
- `read_only` → paralelo libre
- `isolated_write` → paralelo solo en worktree aislado
- `shared_write` → secuencial estricto
- `repo_wide` → sesión principal, sin batch

**Conexión con HERA:** El paper separa formalmente herramientas read-only y mutating para decidir paralelismo seguro. La misma taxonomía aplica a tickets de código.

**Implementación:**
- Agregar campo `execution_class` al spec template
- Preflight valida que el campo exista y sea coherente con el scope fence
- El orchestrator agrupa tickets por clase antes de generar el plan de ejecución
- Documentar las reglas en `references/concurrency-classes.md`

**ROI:** Muy alto. Habilita más paralelismo seguro y previene colisiones.

---

### 1.3 Optimización de tokens — Configuración inmediata

**Problema documentado:** Una auditoría de 926 sesiones reales reveló que la mayor parte del desperdicio de tokens es corregible por configuración:

- **Tool schema bloat:** Claude Code carga schemas JSON completos de cada MCP tool/skill en cada turno (~14k-20k tokens de overhead). `ENABLE_TOOL_SEARCH: true` cambia a carga on-demand y reduce contexto dramáticamente (ej: 45k → 20k tokens).
- **Cache expiry en pausas:** El cache de prompts de Anthropic tiene TTL de ~5 min. 54%+ de turnos ocurrían tras pausas >5min → re-procesamiento completo sin cache hit. En la auditoría: 12.3M tokens desperdiciados solo por esto.
- **Skills no usadas:** 42 skills cargadas, ~19 apenas usadas. 1,100+ lecturas redundantes donde el mismo archivo se re-leía 3+ veces en una sesión.

**Acciones inmediatas:**
1. Agregar `"ENABLE_TOOL_SEARCH": "true"` a la configuración del harness
2. Documentar en CLAUDE.md la regla: usar `/compact` antes de pausas largas
3. Auditar skills cargadas y deshabilitar las que no se usen
4. Agregar regla al orchestrator: no re-leer archivos ya en contexto

**ROI:** Altísimo. Ahorro inmediato sin cambios de arquitectura.

---

### 1.4 Recovery Matrix — Matriz de recuperación de errores

**Problema:** El harness es fuerte en rollback por scope/tests/completitud, pero débil en recovery operacional de sesión: contexto pesado, subagente tangencial, CI que falla post-PR, sesión cortada.

**Solución:** Crear `.ai/recovery-matrix.md` con casos y acciones estándar:

| Situación | Acción |
|---|---|
| Contexto pesado (>80% capacidad) | `shrink` → microcompact + /compact |
| Subagente se fue por tangente | `rollback` → revert commit + re-spec |
| Test suite tarda demasiado | `split` → separar tests lentos, marcar como known-slow |
| Comando no disponible | `retry` con fallback documentado |
| CI falla post-PR | `escalate` → sesión principal con diagnóstico |
| Sesión se cortó | `continue` → leer `.ai/runs/results.tsv` + retomar |
| Spec ambiguo | `split ticket` → dividir + re-spec con usuario |
| Output demasiado grande | `archive artifact` → truncar + persistir a disco |
| Batch con colisión inesperada | `rollback` + reclasificar execution_class |

**Implementación:**
- Documento estático consultable por orchestrator y subagentes
- Integrar con Heat Shield: si detecta una situación, sugerir la acción del matrix
- `/learn` registra nuevos patterns de recovery cuando aparecen

**ROI:** Alto. Reduce dependencia de intuición en sesiones largas.

---

## Prioridad 2 — Alto impacto, esfuerzo medio

### 2.1 Política de compactación de 3 niveles

**Problema:** Hoy la compactación depende del usuario ejecutando `/compact` o `/clear` manualmente. No hay política automatizada.

**Solución — 3 niveles progresivos:**

**Nivel 1 — Microcompact (automático, continuo):**
- Sustituir repeticiones de outputs ya vistos por referencias a artifact path
- Colapsar resultados de tests idénticos en una sola línea
- Reemplazar diffs repetidos por "sin cambios desde iteración N"

**Nivel 2 — Snip (semi-automático, entre tickets):**
- Mantener solo cola protegida: ticket actual, 2 últimos resultados, reglas activas, spec actual
- Todo lo demás se persiste a `.ai/artifacts/` y se referencia

**Nivel 3 — Reset resumible (manual, entre bloques de trabajo):**
- Cierre de iteración con escritura de snapshot mínimo a disco
- `/clear` completo
- Retomar leyendo snapshot + `results.tsv`

**Conexión con HERA:** El paper propone jerarquía "barato primero, caro después" para optimizar tokens. La experience library de HERA hace exactamente esto: comprime experiencia en insights compactos de alta utilidad.

**Implementación:**
- Documentar política en `.ai/compaction-policy.md`
- Microcompact: reglas en el prompt del orchestrator
- Snip: checkpoint automático al terminar cada ticket
- Reset: instrucciones claras en el prompt para cuándo y cómo

**ROI:** Alto. Extiende sesiones útiles y reduce costo.

---

### 2.2 Task Locks en disco para batch/auditoría

**Problema:** El harness usa filesystem como bus de comunicación. Si más de un proceso toca el mismo artifact sin protocolo, hay riesgo de race conditions. Esto se vuelve crítico con más batch y recursive audit.

**Solución:** Directorio `.ai/locks/` con archivos JSON mínimos:

```json
{
  "task_id": "AUTH-03",
  "owner": "batch-worker-2",
  "lease_expires_at": "2026-04-07T12:34:56Z",
  "status": "in_progress"
}
```

**Reglas:**
- No tomar tarea si hay lock válido (no expirado)
- Renovar lease periódicamente
- Si expira, otro agente puede reclamar
- Artifacts por iteración/ticket siempre en rutas únicas (`[batch]/[ticket]/`)

**ROI:** Medio-alto. Esencial si se escala batch y recursive audit.

---

### 2.3 Experience Library — Biblioteca de experiencia acumulada

**Concepto del paper HERA:** El componente más poderoso de HERA es la Experience Library: una memoria estructurada que acumula insights de ejecuciones exitosas y fallidas, con estructura Profile–Insight–Utility (tipo de query, insight en lenguaje natural, tasa de éxito empírica).

**Adaptación al harness:** Evolucionar `done-tasks.md` y `/learn` hacia una library formal:

```markdown
## Insight: Tests de integración fallan cuando se modifica schema de DB
- Perfil: tickets que tocan modelos/migraciones
- Utilidad: 0.85 (aplicado 6/7 veces con éxito)
- Acción: siempre correr migration test suite completa, no solo unit tests
- Origen: sprint BATCH-2024-12, ticket DB-07
```

**Operaciones (inspiradas en HERA):**
- **ADD**: insertar insights nuevos y distintos
- **MERGE**: combinar insights semánticamente similares
- **PRUNE**: eliminar insights de baja utilidad o contradictorios
- **KEEP**: sin cambios

**Implementación:**
- Nuevo directorio `.ai/experience/` con un archivo por dominio/categoría
- `/learn` alimenta la library después de cada ticket
- `/retrospective` consolida y poda la library periódicamente
- El orchestrator consulta la library al generar specs (como "prior" de experiencia)

**ROI:** Alto. Acumula conocimiento entre sprints, reduce errores repetidos.

---

### 2.4 Decision Capture Pipeline (ya spec-eado)

**Estado:** Ya existe `SPEC-decision-capture-pipeline.md` en el repo con diseño completo de 3 fases.

**Resumen rápido:**
- Fase 1: Sección "Design decisions" en cada spec + consolidación por batch
- Fase 2: Heat Shield reporta desviaciones tácticas, `/learn` las registra
- Fase 3: Auditor valida/cuestiona decisiones, feedback a CLAUDE.md

**Archivos a generar:**
- `.ai/decisions/[batch].decisions.md`
- `.ai/decisions/CONSOLIDATED.md`
- `.ai/KNOWN_FALSE_CLOSURES.md`

**Siguiente paso:** Implementar Prioridad 1 del spec (MVP: specs + Heat Shield + /learn). Esfuerzo: bajo.

**ROI:** Alto. Preserva el "por qué" de decisiones que hoy se pierden en transcripts efímeros.

---

## Prioridad 3 — Impacto medio, esfuerzo medio

### 3.1 Role-Aware Prompt Evolution (inspirado en HERA RoPE)

**Concepto HERA:** Cada agente tiene un prompt que evoluciona por dos ejes: reglas operacionales (correcciones inmediatas) y principios de comportamiento (estrategias a largo plazo). Los prompts se consolidan periódicamente para mantenerse compactos.

**Adaptación al harness:**
- Hoy `/learn` ya enriquece CLAUDE.md, pero de forma incremental y sin consolidación
- Agregar un paso de consolidación periódica: fusionar reglas redundantes, podar las de baja utilidad, mantener CLAUDE.md ≤100 líneas
- Separar explícitamente reglas operacionales (correcciones de errores recientes) de principios de comportamiento (patrones validados por múltiples sprints)
- El orchestrator aplica esto: reglas operacionales van al prompt lean, principios van a CLAUDE.md

**ROI:** Medio. Mejora calidad del prompt sin cambiar arquitectura.

---

### 3.2 Perfiles de permiso configurables

**Tres niveles:**
- **conservative**: no auto-merge, no delete, confirmación en cada paso crítico
- **standard**: comportamiento actual del harness
- **aggressive**: auto-merge si tests pasan, cleanup automático, más paralelismo

**Implementación:** Campo `permission_profile` en el execution plan, con reglas por perfil documentadas.

**ROI:** Medio. Útil para diferentes contextos (prod vs. experimental).

---

### 3.3 Estructura docs/project_notes/ en .ai

**Idea de las notas:** Agregar subdirectorio para conocimiento no-efímero del proyecto:

```
.ai/docs/project_notes/
├── bugs.md          # Bugs conocidos no resueltos
├── decisions.md     # Se fusiona con Decision Capture Pipeline
├── key_facts.md     # Hechos clave del proyecto (constraints, dependencias externas)
└── issues.md        # Issues abiertos no cubiertos por specs
```

**ROI:** Medio. Complementa la experience library con conocimiento estático del proyecto.

---

## Prioridad 4 — Mejoras futuras / exploración

### 4.1 Topology Mutation (concepto HERA)

**Concepto:** Cuando trayectorias fallan consistentemente, mutar la topología de agentes: reemplazar agente fallido por alternativa, agregar agentes adicionales, cambiar secuencia.

**Aplicación potencial:** Si un subagente falla 3+ veces en el mismo tipo de ticket, el orchestrator podría ajustar el prompt, cambiar la estrategia de ejecución, o escalar a sesión principal.

**Estado:** Exploratorio. El harness actual no tiene suficiente metadata para implementar esto bien. Prerequisito: experience library funcionando.

---

### 4.2 Métricas de topología (Graph Metrics del paper)

**Concepto HERA:** Medir eficiencia por agente, self-loops (redundancia), ciclos, y diámetro de la cadena de ejecución.

**Adaptación:** Agregar métricas al `results.tsv`:
- Tokens consumidos por ticket
- Número de iteraciones por ticket
- Ratio de rollbacks/éxitos
- Tiempo de ejecución

**Uso:** `/retrospective` consume estas métricas para detectar patrones de ineficiencia.

---

### 4.3 Semantic Advantage scoring (concepto HERA)

**Concepto:** En vez de evaluar ejecuciones con métricas escalares, comparar grupos de trayectorias exitosas vs. fallidas y extraer "ventajas semánticas" — razones en lenguaje natural de por qué unas funcionaron y otras no.

**Aplicación:** Enriquecer `/retrospective` para que no solo detecte patrones sino que articule *por qué* ciertos enfoques funcionan mejor.

---

## Lo que NO implementar (decisiones explícitas)

Estas ideas del paper HERA o del análisis son valiosas en teoría pero no dan retorno para el estado actual del harness:

1. **Reescribir como async generator runtime** — El harness es un plugin de orquestación, no un runtime LLM. Reconstruir el motor no da retorno inmediato.

2. **Sistema de permisos multinivel enterprise/project/user/session** — Sobreingeniería para el caso de uso actual. El guard destructivo + hooks ya cubre el 80% del riesgo.

3. **Retry stack tipo Anthropic** — No se controla el runtime interno de Claude Code. Replicar su capa de retries desde el harness sería inversión perdida.

4. **UI sofisticada** — Primero sacar valor de mejor ledger, artifacts y dashboards simples antes de construir UI compleja.

5. **GRPO completo (Group Relative Policy Optimization)** — El sampling de topologías del paper es elegante pero requiere volumen de ejecuciones que el harness no tiene hoy.

---

## Resumen ejecutivo

| # | Mejora | ROI | Esfuerzo | Prerequisitos |
|---|---|---|---|---|
| 1.1 | Result Budgeting | Muy alto | Bajo | Ninguno |
| 1.2 | Clases de ejecución | Muy alto | Bajo | Ninguno |
| 1.3 | Optimización de tokens | Altísimo | Mínimo | Ninguno |
| 1.4 | Recovery Matrix | Alto | Bajo | Ninguno |
| 2.1 | Compactación 3 niveles | Alto | Medio | 1.1 |
| 2.2 | Task Locks | Medio-alto | Medio | 1.2 |
| 2.3 | Experience Library | Alto | Medio | 1.4, `/learn` actual |
| 2.4 | Decision Capture | Alto | Bajo (MVP) | Spec existente |
| 3.1 | Prompt Evolution | Medio | Medio | 2.3 |
| 3.2 | Perfiles de permiso | Medio | Bajo | Ninguno |
| 3.3 | project_notes/ | Medio | Bajo | Ninguno |
| 4.1 | Topology Mutation | Bajo (hoy) | Alto | 2.3 |
| 4.2 | Graph Metrics | Bajo (hoy) | Medio | 2.3 |
| 4.3 | Semantic Advantage | Bajo (hoy) | Alto | 2.3, 4.2 |

---

## Fuentes

- Paper: "Experience as a Compass: Multi-agent RAG with Evolving Orchestration and Agent Prompts" (Li & Ramakrishnan, Virginia Tech, 2026) — arXiv:2604.00901v2
- Auditoría de 926 sesiones de Claude Code — análisis de token waste
- Notas propias de ideas, bugs y mejoras
- Análisis comparativo harness vs. paper HERA
- Repo Superpowers: https://github.com/obra/superpowers
