# Ticket 7 — Experience Library (biblioteca de experiencia acumulada)

## Objetivo

Crear la infraestructura para una biblioteca de experiencia que acumule insights de ejecuciones exitosas y fallidas, con operaciones formales de consolidación (ADD/MERGE/PRUNE/KEEP). Esto evoluciona `done-tasks.md` y `/learn` de un registro narrativo a un sistema de conocimiento consultable que mejora las decisiones del orquestador entre sprints.

## Complejidad: Media

## Dependencias

- Requiere: T-4 completado (Recovery Matrix — la experience library categoriza patrones que la matrix ya documenta como situaciones)
- Requiere: `/learn` funcional (ya instalado en bootstrap)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/experience-library.md`
- `.claude/commands/learn.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `.claude/settings.json` — configuración de hooks
- `templates/spec-template.md` — fuera de scope
- `references/recovery-matrix.md` — creado por T-4, no modificar (solo referenciar)

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/experience-library.md` | Documento de referencia con diseño de la library: estructura, operaciones, formato de insights, y ciclo de vida |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `.claude/commands/learn.md` | Agregar paso de alimentar la experience library después de registrar en done-tasks.md |
| `templates/orchestrator-prompt.md` | Agregar paso de consultar la experience library al inicio de cada sprint (antes de ejecutar tickets) |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/experience-library.md` con:

   **Estructura de la library:**
   ```
   .ai/experience/
   ├── orchestration.md      # Insights sobre orquestación (orden, paralelismo, compactación)
   ├── implementation.md     # Insights sobre implementación (patrones de código, errores comunes)
   ├── testing.md            # Insights sobre testing (qué tests fallan, por qué)
   └── recovery.md           # Insights sobre recovery (complementa recovery-matrix.md)
   ```

   **Formato de cada insight:**
   ```markdown
   ### [ID]: [Título descriptivo]
   - **Perfil:** [Tipo de ticket/situación donde aplica]
   - **Insight:** [Qué se aprendió — 1-2 líneas]
   - **Utilidad:** [N/M aplicaciones exitosas] (ej: 5/6 = aplicado 5 de 6 veces con éxito)
   - **Acción:** [Qué hacer cuando se detecta este perfil]
   - **Origen:** [batch, ticket, fecha]
   - **Última actualización:** [fecha]
   ```

   **Operaciones de consolidación (inspiradas en HERA):**
   - **ADD**: Insertar insight nuevo que no existe ni es similar a ninguno existente
   - **MERGE**: Combinar insights semánticamente similares en uno más general. Sumar contadores de utilidad
   - **PRUNE**: Eliminar insights con utilidad <30% después de 5+ aplicaciones, o que contradicen insights más recientes
   - **KEEP**: Sin cambios (el insight sigue siendo válido y útil)

   **Ciclo de vida:**
   - `/learn` por ticket → evalúa si hay insight nuevo → ADD o MERGE
   - `/learn` de sprint completo → consolida → MERGE + PRUNE
   - `/retrospective` → auditoría profunda → PRUNE agresivo + pattern detection
   - El orquestador consulta la library al inicio de sprint → selecciona insights relevantes por perfil de tickets

   **Criterios para cada operación:**
   - ADD: el insight pasó el test de sustracción causal ("¿qué error ocurriría sin este insight?") Y no duplica uno existente
   - MERGE: dos insights aplican al mismo perfil y la combinación es más general sin perder precisión
   - PRUNE: utilidad <30% (falló más veces de las que ayudó) O referencia archivos/APIs que ya no existen O contradice insight más reciente con mayor utilidad
   - KEEP: nada de lo anterior aplica

2. Leer `.claude/commands/learn.md` y agregar un **Paso 9.5** (después de "9. Registrar en .ai/done-tasks.md" y antes de "10. Preparar para el siguiente"):
   ```markdown
   ## 9.5. Alimentar Experience Library

   Para cada lección significativa de este ticket:
   1. Leer los archivos relevantes en `.ai/experience/`
   2. Evaluar si la lección es un insight nuevo (ADD), refuerza uno existente (MERGE), o invalida uno (PRUNE)
   3. Aplicar la operación según `references/experience-library.md`
   4. Si es ADD: crear con utilidad inicial 1/1
   5. Si es MERGE: incrementar el contador de utilidad
   6. Reportar: "Experience library: [N] ADD, [N] MERGE, [N] PRUNE"

   Solo alimentar insights que pasaron el test de sustracción causal del Paso 3.
   Insights menores (1 ocurrencia, sin rollback) van solo a done-tasks.md, NO a la library.
   ```

3. Leer `templates/orchestrator-prompt.md` y agregar al inicio de la ejecución (después de "Setup inicial"):
   ```markdown
   ## Consulta de experiencia previa
   Antes de ejecutar el primer ticket, leé los archivos en `.ai/experience/` (si existen).
   Buscá insights cuyo **Perfil** coincida con los tickets de este sprint.
   Si encontrás insights relevantes, tenelos en cuenta al verificar resultados de subagentes.
   NO dejes que la experience library modifique los specs — los specs son la fuente de verdad.
   ```

4. Verificar consistencia entre los 3 archivos modificados
5. Commit: `"feat(T-7): agregar experience library con operaciones ADD/MERGE/PRUNE/KEEP"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/experience-library.md && echo "PASS" || echo "FAIL"
# Verificar que define las 4 operaciones
grep -c "ADD\|MERGE\|PRUNE\|KEEP" references/experience-library.md | xargs test 4 -le && echo "PASS" || echo "FAIL"
# Verificar que learn.md tiene paso de experience library
grep -q "Experience Library\|experience" .claude/commands/learn.md && echo "PASS" || echo "FAIL"
# Verificar que orchestrator-prompt referencia experience
grep -q "experience" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/experience-library.md` existe y no está vacío
- [ ] `test_operations_defined`: El archivo define las 4 operaciones (ADD, MERGE, PRUNE, KEEP)
- [ ] `test_learn_integration`: `.claude/commands/learn.md` incluye paso de alimentar la library
- [ ] `test_prompt_consultation`: `templates/orchestrator-prompt.md` incluye paso de consultar la library

## Criterios de aceptación

- [ ] Existe `references/experience-library.md` con estructura de la library, formato de insights, y 4 operaciones
- [ ] La estructura de carpetas `.ai/experience/` está definida con categorías claras
- [ ] Cada operación tiene criterios concretos de cuándo aplicarla
- [ ] `.claude/commands/learn.md` alimenta la library como paso post-ticket
- [ ] `templates/orchestrator-prompt.md` consulta la library al inicio de sprint
- [ ] El documento respeta la jerarquía: done-tasks.md es registro narrativo, experience library es conocimiento destilado

## NO hacer

- NUNCA crear los directorios `.ai/experience/` ni archivos iniciales — se crean con el primer `/learn` que genere un insight
- NUNCA permitir que la experience library sobrescriba specs — los specs son la fuente de verdad de cada ticket
- NUNCA poner insights triviales en la library — el test de sustracción causal es obligatorio
- NUNCA duplicar el contenido de `references/recovery-matrix.md` en la library — referenciarla
- NUNCA hacer la consulta de experiencia obligatoria para sprints — es "si existen archivos en .ai/experience/"

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
