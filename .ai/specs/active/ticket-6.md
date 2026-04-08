# Ticket 6 — Task Locks en disco para batch y auditoría

## Objetivo

Implementar un sistema liviano de locks basado en archivos JSON para evitar que múltiples subagentes o procesos de auditoría colisionen al trabajar sobre los mismos artifacts. Esto es prerequisito para escalar batch paralelo y recursive audit de forma segura.

## Complejidad: Media

## Dependencias

- Requiere: T-2 completado (Clases de ejecución — los locks usan execution_class para decidir nivel de protección)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/task-locks.md`
- `templates/orchestrator-prompt.md`
- `templates/spec-template.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `.claude/settings.json` — configuración de hooks
- `references/concurrency-classes.md` — creado por T-2, no modificar (solo referenciar)
- `references/compaction-policy.md` — lo crea T-5

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/task-locks.md` | Documento de referencia con protocolo de locks: estructura JSON, reglas de lease, y flujo de adquisición/liberación |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar regla de locks en la sección de batch (/batch — Regla 9) y en notas de auditoría recursiva |
| `templates/spec-template.md` | Agregar sección opcional de lock requirements al template |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/task-locks.md` con:

   **Estructura de un lock:**
   ```json
   {
     "task_id": "T-3",
     "owner": "subagent-batch-2",
     "acquired_at": "2026-04-07T12:30:00Z",
     "lease_expires_at": "2026-04-07T12:45:00Z",
     "status": "in_progress",
     "files_locked": ["src/auth/login.ts", "tests/auth.test.ts"]
   }
   ```

   **Ubicación:** `.ai/locks/[task_id].lock.json`

   **Reglas de protocolo:**
   - NUNCA tomar una tarea si existe un lock válido (no expirado)
   - Lease default: 15 minutos (configurable por complejidad: Simple=10min, Media=15min, Alta=30min)
   - Renovar lease: escribir nueva timestamp antes de que expire
   - Si un lock expira, cualquier otro agente puede reclamar la tarea (borrar el lock viejo y crear uno nuevo)
   - Al completar: borrar el lock inmediatamente
   - Al fallar (rollback): borrar el lock y registrar en results.tsv

   **Flujo de adquisición:**
   1. Verificar si existe `.ai/locks/[task_id].lock.json`
   2. Si existe y no expiró → esperar o saltar al siguiente ticket
   3. Si no existe o expiró → crear lock con lease
   4. Implementar ticket
   5. Borrar lock

   **Integración con execution_class (de T-2, ver `references/concurrency-classes.md`):**
   - `read_only` → no requiere lock
   - `isolated_write` → lock solo sobre sus archivos específicos
   - `shared_write` → lock mutex global (solo un agente a la vez)
   - `repo_wide` → no usa locks (corre en sesión principal exclusiva)

   **Limpieza:**
   - `.ai/locks/` se borra al final de cada sprint (en la limpieza post-ejecución)
   - Los locks son artifacts temporales, no se commitean

2. Leer `templates/orchestrator-prompt.md` y modificar:
   - En **Regla 9 (/batch)**: agregar paso de adquisición de lock antes de lanzar cada subagente del batch, y liberación después
   - En la sección de notas sobre auditoría recursiva (si existe): agregar referencia a locks para evitar colisiones entre auditor y spec writer

3. Leer `templates/spec-template.md` y agregar sección opcional después de "Clase de ejecución":
   ```markdown
   ## Lock requirements (opcional — solo para batch/audit)
   <!-- Solo llenar si el ticket puede correr en paralelo con otros -->
   - Archivos que requieren lock exclusivo: [lista]
   - Lease estimado: [Simple=10min | Media=15min | Alta=30min]
   ```

4. Verificar consistencia entre los 3 archivos
5. Commit: `"feat(T-6): agregar sistema de task locks en disco para batch y auditoría"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/task-locks.md && echo "PASS" || echo "FAIL"
# Verificar que tiene la estructura JSON de ejemplo
grep -q "task_id" references/task-locks.md && echo "PASS" || echo "FAIL"
# Verificar que orchestrator-prompt menciona locks
grep -q "lock" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
# Verificar que spec-template tiene sección de locks
grep -qi "lock" templates/spec-template.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/task-locks.md` existe y no está vacío
- [ ] `test_json_structure`: El archivo incluye ejemplo de estructura JSON de un lock
- [ ] `test_prompt_integration`: `templates/orchestrator-prompt.md` menciona locks en contexto de batch
- [ ] `test_template_section`: `templates/spec-template.md` incluye sección de lock requirements

## Criterios de aceptación

- [ ] Existe `references/task-locks.md` con protocolo completo de locks
- [ ] El protocolo define: estructura JSON, ubicación, reglas de lease, flujo de adquisición/liberación
- [ ] La integración con execution_class está documentada (qué clase necesita qué tipo de lock)
- [ ] `templates/orchestrator-prompt.md` incluye paso de lock en Regla 9 (batch)
- [ ] `templates/spec-template.md` incluye sección opcional de lock requirements
- [ ] El documento especifica que `.ai/locks/` es temporal y se limpia post-sprint

## NO hacer

- NUNCA implementar locks como código ejecutable — son archivos JSON que los agentes leen/escriben
- NUNCA hacer que los locks sean obligatorios para ejecución secuencial — solo aplican a batch y audit paralelo
- NUNCA commitear locks al repo — son artifacts temporales de runtime
- NUNCA crear subdirectorios dentro de `.ai/locks/` — todos los locks van flat en esa carpeta
- NUNCA bloquear la ejecución si no se puede adquirir un lock — registrar warning y saltar al siguiente ticket

---

## Checklist de autocontención

- [x] ¿Tiene scope fence (archivos permitidos + prohibidos)?
- [x] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [x] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [x] ¿Tiene comando exacto de tests?
- [x] ¿Tiene commit message definido?
- [x] ¿Tiene criterios de aceptación observables?
- [x] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [x] ¿Tiene ≤10 restricciones totales?
- [x] ¿No depende de contexto que solo existe en la conversación?
