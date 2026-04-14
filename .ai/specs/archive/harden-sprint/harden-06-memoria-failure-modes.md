# harden-06 — Memoria estructurada de failure modes

## Objetivo

Crear una taxonomía estructurada de failure modes y patrones de falso cierre que `/learn` pueda actualizar y que el auditor pueda consultar antes de verificar cierre de tickets.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `commands/learn.md`
- `references/failure-modes-taxonomy.md`

### Archivos prohibidos
- `templates/spec-template.md` — ya modificado en harden-01/02/03
- `commands/preflight.md` — ya modificado en harden-04
- `templates/orchestrator-prompt.md` — ya modificado en harden-05
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- Ninguna

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `commands/learn.md` | Agregar paso de clasificación de failure mode al flujo de /learn. Cuando el ticket tiene status `discard`, /learn debe clasificar el fallo según la taxonomía y agregarlo al archivo de failure modes del proyecto. |

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/failure-modes-taxonomy.md` | Documento de referencia con la taxonomía de failure modes, patrones de falso cierre, y formato del archivo `.ai/failure-modes.md` que se genera en proyectos target. |

---

## Subtareas

### Implementación directa — sin subdivisión

**Pasos:**
1. Crear `references/failure-modes-taxonomy.md` con este contenido:
   ```markdown
   # Taxonomía de failure modes

   ## Propósito

   Este documento define las categorías de fallo reconocidas por el harness
   y el formato en que se registran en proyectos target.

   ## Categorías de fallo

   ### Fallos de ejecución
   | Código | Nombre | Descripción | Señal típica |
   |--------|--------|-------------|-------------|
   | EXEC-01 | no_commit | Subagente no hizo commit atómico | Hash pre/post idénticos |
   | EXEC-02 | scope_violation | Tocó archivos en denylist | diff --name-only vs denied_paths |
   | EXEC-03 | test_failure | Tests fallan después de 2 intentos | Exit code ≠ 0 persistente |
   | EXEC-04 | crash | Error sistémico impide ejecución | Subagente no devuelve resultado |

   ### Fallos de cierre (falso cierre)
   | Código | Nombre | Descripción | Señal típica |
   |--------|--------|-------------|-------------|
   | CLOSE-01 | incomplete | Criterios de aceptación no cumplidos | <80% criterios verificados |
   | CLOSE-02 | rationalization | Subagente declara victoria sin evidencia | diff vacío o no coincide con spec |
   | CLOSE-03 | spec_ambiguity | Spec ambiguo causó implementación incorrecta | Resultado no corresponde a objetivo |
   | CLOSE-04 | verification_failed | Checks determinísticos de cierre fallan | Artefacto faltante, tipo incorrecto |

   ### Fallos de spec (prevenibles en preflight)
   | Código | Nombre | Descripción | Señal típica |
   |--------|--------|-------------|-------------|
   | SPEC-01 | scope_too_broad | Ticket debía partirse | ≥2 señales de descomposición activas |
   | SPEC-02 | missing_context | Spec no autocontenido | Subagente tuvo que explorar |
   | SPEC-03 | vague_criteria | Criterios no verificables | Auditor no puede confirmar cierre |

   ## Patrones de falso cierre conocidos

   Estos patrones se inyectan en el prompt del auditor como checklist.

   1. **"Todo funciona" sin tests** — subagente reporta éxito pero no corrió tests
   2. **Commit parcial** — commit existe pero no incluye todos los archivos del spec
   3. **Scope creep disfrazado** — tocó archivos fuera de allowlist "porque era necesario"
   4. **Doc sin código** — ticket pedía implementación + docs, solo entregó docs
   5. **Refactor en vez de feature** — mejoró código existente sin implementar lo pedido

   ## Formato del archivo de failure modes en proyecto target

   El orquestador genera `.ai/failure-modes.md` en el proyecto target.
   `/learn` lo actualiza cuando un ticket tiene status `discard`.

   ```
   # Failure Modes — [nombre-proyecto]

   ## Registro de fallos

   | Fecha | Ticket | Código | Categoría | Descripción | Acción preventiva |
   |-------|--------|--------|-----------|-------------|------------------|
   | 2026-04-14 | T-5 | EXEC-03 | test_failure | Tests de integración fallan por DB no mockeada | Agregar setup de DB al spec |

   ## Patrones recurrentes

   <!-- Se actualiza cuando el mismo código aparece 3+ veces -->

   | Patrón | Frecuencia | Última vez | Acción sistémica |
   |--------|-----------|------------|-----------------|
   | EXEC-03 en tickets con DB | 4 veces | 2026-04-14 | Agregar "verificar setup de DB" al preflight |
   ```
   ```
2. En `commands/learn.md`, agregar un paso de clasificación de failure mode. Leer el archivo actual primero para entender la estructura, luego agregar DESPUÉS del paso de registro de lecciones:
   ```markdown
   ## Clasificación de failure mode (solo para tickets discard)

   Si el ticket tiene status `discard` en `.ai/runs/results.tsv`:

   1. Leer `failure_category` del results.tsv
   2. Mapear a código de taxonomía:
      - `no_commit` → EXEC-01
      - `scope_violation` → EXEC-02
      - `test_failure` → EXEC-03
      - `crash` → EXEC-04
      - `incomplete` → CLOSE-01
      - `rationalization` → CLOSE-02
      - `spec_ambiguity` → CLOSE-03
      - `verification_failed` → CLOSE-04
   3. Si existe `.ai/failure-modes.md`:
      - Agregar fila al registro
      - Contar ocurrencias del mismo código
      - Si el código aparece 3+ veces → agregar a "Patrones recurrentes"
        y sugerir acción sistémica
   4. Si no existe `.ai/failure-modes.md`:
      - Crearlo con el header y la primera fila

   Este paso es automático — no requiere input del usuario.
   ```
3. Verificar que la taxonomía es coherente con las failure_categories existentes en el orchestrator-prompt.

**Tests:** No aplica (repo 100% markdown). Validación manual:
```bash
# Verificar que el archivo de taxonomía existe y tiene las categorías
ls references/failure-modes-taxonomy.md
grep -c "EXEC-\|CLOSE-\|SPEC-" references/failure-modes-taxonomy.md
# Debería ser >= 10
```

- [ ] `taxonomia_existe`: `references/failure-modes-taxonomy.md` existe con 3 categorías principales
- [ ] `learn_actualizado`: `commands/learn.md` tiene paso de clasificación de failure mode
- [ ] `codigos_coherentes`: Los códigos mapean 1:1 con failure_categories del orchestrator-prompt

## Criterios de aceptación

- [ ] `references/failure-modes-taxonomy.md` existe con las 3 categorías (ejecución, cierre, spec) y 10+ códigos
- [ ] Los 5 patrones de falso cierre están documentados como checklist inyectable
- [ ] `commands/learn.md` tiene paso automático de clasificación para tickets `discard`
- [ ] El formato del `.ai/failure-modes.md` target está definido con tabla de registro y patrones recurrentes
- [ ] El mapeo failure_category → código de taxonomía es completo (cubre todas las categorías existentes)

## NO hacer

- NUNCA agregar categorías de fallo que no correspondan a failure_categories existentes en el orchestrator-prompt
- NUNCA hacer la clasificación opcional — si el ticket es `discard`, se clasifica siempre
- NUNCA registrar fallos de tickets `keep` en failure-modes — solo `discard`

## Checklist de autocontención

- [x] Tiene scope fence (archivos permitidos + prohibidos)
- [x] Tiene dependencias de lectura listadas (Ninguna)
- [x] Tiene rutas EXACTAS de archivos a modificar/crear
- [x] Tiene pasos concretos (no "investigar" o "explorar")
- [x] Tiene comando exacto de tests
- [x] Tiene commit message definido (abajo)
- [x] Tiene criterios de aceptación observables
- [x] Tiene restricciones claras en forma imperativa
- [x] Tiene ≤10 restricciones totales
- [x] No depende de contexto que solo existe en la conversación

**Commit:** `"feat(harden-06): crear taxonomía de failure modes y conectar con /learn"`
