# Ticket 8 — Decision Capture Pipeline MVP (Fase 1)

## Objetivo

Implementar la Fase 1 (MVP) del pipeline de captura de decisiones: agregar una sección opcional "Decisiones de diseño" al template de specs, integrar la captura de desviaciones tácticas en Heat Shield, y conectar `/learn` para registrar decisiones en `.ai/decisions/`. El diseño completo ya existe en `SPEC-decision-capture-pipeline.md` — este ticket implementa solo el MVP (Prioridad 1 del spec).

## Complejidad: Media

## Dependencias

- Requiere: T-1 completado (Result Budgeting — Heat Shield ya modificado, este ticket agrega campo de decisiones)
- Requiere: `/learn` funcional (ya instalado)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `templates/orchestrator-prompt.md`
- `.claude/commands/learn.md`
- `references/decision-capture.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `SPEC-decision-capture-pipeline.md` — es el spec de diseño original, NO modificar
- `.claude/settings.json` — configuración de hooks
- `references/experience-library.md` — lo crea T-7

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/decision-capture.md` | Resumen operativo del pipeline de captura de decisiones (extraído del SPEC original, solo lo necesario para el MVP) |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar sección opcional "Decisiones de diseño" con formato estructurado |
| `templates/orchestrator-prompt.md` | Agregar campo "decisiones" al patrón Heat Shield para que subagentes reporten desviaciones tácticas |
| `.claude/commands/learn.md` | Agregar paso de consolidar decisiones en `.ai/decisions/[batch].decisions.md` |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Leer `SPEC-decision-capture-pipeline.md` para contexto completo del diseño (es referencia, NO se modifica).

2. Crear `references/decision-capture.md` con:
   - Resumen del problema: las decisiones se pierden en 3 lugares efímeros
   - Formato de una entrada de decisión:
     ```
     ### [D-N] — [Título]
     - **Fase:** spec | implementación | auditoría
     - **Decisión:** [Qué se decidió — 1 línea]
     - **Motivo:** [Por qué]
     - **Alternativas descartadas:** [Lo más valioso — qué se consideró y rechazó]
     - **Tickets relacionados:** [T-N]
     ```
   - Ubicación de archivos: `.ai/decisions/[batch].decisions.md` (por batch, se archiva junto con specs)
   - Referencia al SPEC completo para fases futuras: `SPEC-decision-capture-pipeline.md`

3. Leer `templates/spec-template.md` y agregar sección OPCIONAL después de "## NO hacer" y antes de "## Checklist de autocontención":
   ```markdown
   ## Decisiones de diseño (opcional)
   <!-- Registrar aquí las decisiones significativas tomadas al escribir este spec.
        Solo llenar si hubo alternativas consideradas y descartadas.
        Esta sección NO se valida en preflight — es puramente informativa. -->
   
   ### D-1 — [Título de la decisión]
   - **Decisión:** [Qué se decidió]
   - **Motivo:** [Por qué]
   - **Alternativas descartadas:** [Qué se consideró y se rechazó, y por qué]
   ```

4. Leer `templates/orchestrator-prompt.md` y en la sección "Patrón Heat Shield (retorno de subagentes)", agregar un campo opcional al final de la lista:
   ```
   - Desviaciones tácticas (si hubo): [decisiones que el subagente tomó que no estaban en el spec, máximo 2 líneas]
   ```

5. Leer `.claude/commands/learn.md` y agregar un **Paso 8.5** (después de "8. Evaluar si hace falta nueva infraestructura" y antes de "9. Registrar en .ai/done-tasks.md"):
   ```markdown
   ## 8.5. Registrar decisiones

   Si durante este ticket hubo decisiones significativas (cambios de approach, desviaciones del spec, alternativas evaluadas):
   1. Crear o actualizar `.ai/decisions/[nombre-batch].decisions.md`
   2. Agregar cada decisión con el formato de `references/decision-capture.md`
   3. Si el spec tenía sección "Decisiones de diseño", incluir esas también
   4. Si el subagente reportó desviaciones tácticas en Heat Shield, registrarlas como decisiones de fase "implementación"
   
   Si no hubo decisiones significativas, saltar este paso.
   ```

6. Verificar que el formato de decisión es idéntico en los 3 archivos que lo mencionan
7. Commit: `"feat(T-8): implementar MVP del pipeline de captura de decisiones"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/decision-capture.md && echo "PASS" || echo "FAIL"
# Verificar que spec-template tiene sección de decisiones
grep -qi "decisiones de diseño\|design decisions" templates/spec-template.md && echo "PASS" || echo "FAIL"
# Verificar que orchestrator-prompt tiene campo de desviaciones
grep -qi "desviaciones\|deviations\|decisiones" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
# Verificar que learn.md tiene paso de registrar decisiones
grep -qi "decisiones\|decisions" .claude/commands/learn.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/decision-capture.md` existe y no está vacío
- [ ] `test_spec_template_section`: `templates/spec-template.md` incluye sección "Decisiones de diseño"
- [ ] `test_heat_shield_field`: `templates/orchestrator-prompt.md` incluye campo de desviaciones tácticas
- [ ] `test_learn_step`: `.claude/commands/learn.md` incluye paso de registrar decisiones

## Criterios de aceptación

- [ ] Existe `references/decision-capture.md` con formato de entrada y ubicación de archivos
- [ ] `templates/spec-template.md` tiene sección opcional "Decisiones de diseño" con formato
- [ ] El patrón Heat Shield en `templates/orchestrator-prompt.md` incluye campo de desviaciones tácticas
- [ ] `.claude/commands/learn.md` registra decisiones en `.ai/decisions/[batch].decisions.md`
- [ ] La sección en spec-template es OPCIONAL (no se valida en preflight)
- [ ] El formato de decisión es consistente en todos los archivos que lo mencionan

## NO hacer

- NUNCA implementar Fase 2 ni Fase 3 del spec original — solo Fase 1 (MVP)
- NUNCA crear `.ai/decisions/CONSOLIDATED.md` — eso es Fase 2
- NUNCA crear `.ai/KNOWN_FALSE_CLOSURES.md` — eso es Fase 3
- NUNCA hacer que la sección "Decisiones de diseño" sea obligatoria en preflight — debe ser opcional
- NUNCA modificar `SPEC-decision-capture-pipeline.md` — es referencia de diseño, no implementación

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
