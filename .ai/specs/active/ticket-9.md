# Ticket 9 — Role-Aware Prompt Evolution (consolidación de CLAUDE.md)

## Objetivo

Formalizar un protocolo de consolidación periódica de CLAUDE.md que separe reglas operacionales (correcciones de errores recientes) de principios de comportamiento (patrones validados por múltiples sprints), y defina cuándo y cómo fusionar, podar, y promover reglas. Esto evoluciona `/learn` de un mecanismo incremental a uno que también consolida.

## Complejidad: Media

## Dependencias

- Requiere: T-7 completado (Experience Library — la consolidación consulta la library para validar qué reglas tienen utilidad demostrada)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/prompt-evolution.md`
- `.claude/commands/learn.md`
- `templates/claudemd-template.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn, no directamente
- `templates/orchestrator-prompt.md` — fuera de scope para este ticket
- `.claude/settings.json` — configuración de hooks
- `references/experience-library.md` — creado por T-7, solo referenciar

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/prompt-evolution.md` | Protocolo de consolidación con separación operacional/principios, criterios de promoción, y ciclo de vida de reglas |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `.claude/commands/learn.md` | Agregar paso de consolidación periódica después del paso de sustracción causal |
| `templates/claudemd-template.md` | Agregar marcadores de categoría (operacional vs principio) en las secciones de reglas |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/prompt-evolution.md` con:

   **Dos categorías de reglas:**
   - **Reglas operacionales** (`[OP]`): correcciones inmediatas derivadas de errores recientes. Tienen fecha de creación y contador de activaciones. Son candidatas a promoción o eliminación después de 3 sprints.
   - **Principios de comportamiento** (`[BP]`): estrategias validadas por múltiples sprints (≥2 activaciones exitosas). Son permanentes salvo que la experience library demuestre utilidad <50%.

   **Ciclo de vida de una regla:**
   ```
   Error detectado → /learn crea regla [OP] con fecha y 1 activación
   → Siguiente sprint: si se activa de nuevo → incrementar contador
   → 2+ activaciones exitosas → promover a [BP] (quitar fecha, mantener principio)
   → 3 sprints sin activarse → candidata a eliminación
   → Experience library muestra utilidad <50% → eliminar
   ```

   **Protocolo de consolidación (cuándo ejecutar):**
   - **Mini-consolidación**: al final de cada sprint completo (en `/learn [batch] completo`)
     - Fusionar reglas [OP] redundantes
     - Promover [OP] con 2+ activaciones a [BP]
     - Eliminar [OP] con 0 activaciones en 3+ sprints
   - **Consolidación profunda**: cada 3 sprints o cuando CLAUDE.md supere 90 líneas
     - Todo lo anterior +
     - Cross-reference con experience library: eliminar reglas con utilidad <50%
     - Verificar que cada regla pasa el test de sustracción causal
     - Simplificar redacción sin perder protección
     - Target: volver a ≤80 líneas

   **Criterios de promoción [OP] → [BP]:**
   - ≥2 activaciones exitosas en sprints diferentes
   - La regla previene un error que no es obvio por pre-training
   - La regla no contradice ningún [BP] existente

   **Criterios de eliminación:**
   - 0 activaciones en ≥3 sprints consecutivos
   - Experience library muestra utilidad <30% después de 5+ aplicaciones
   - Referencia archivos/APIs que ya no existen
   - Redundante con otra regla de mayor utilidad

2. Leer `.claude/commands/learn.md` y modificar el **Paso 6** (Actualizar CLAUDE.md) para agregar categorización:
   - Cuando se agrega una regla nueva, marcarla como `[OP]` con fecha: `[OP 2026-04-07]`
   - Al final del paso 6, agregar sub-paso:
     ```
     **Consolidación (solo en /learn de sprint completo):**
     Si este es el /learn final de un sprint (argumento contiene "completo"):
     1. Revisar todas las reglas [OP] en CLAUDE.md
     2. Consultar `.ai/experience/` para validar utilidad
     3. Promover, fusionar, o eliminar según `references/prompt-evolution.md`
     4. Reportar: "Consolidación: [N] promovidas, [N] fusionadas, [N] eliminadas"
     ```

3. Leer `templates/claudemd-template.md` y agregar comentario HTML en las secciones de reglas:
   ```html
   <!-- Categorías de reglas:
     [OP YYYY-MM-DD] = Regla operacional (corrección reciente). Caduca si no se activa en 3 sprints.
     [BP] = Principio de comportamiento (validado por 2+ sprints). Permanente salvo prueba en contra.
     Sin marcador = regla original del proyecto (pre-evolución). Tratar como [BP].
   -->
   ```

4. Verificar consistencia entre los 3 archivos
5. Commit: `"feat(T-9): agregar protocolo de prompt evolution con separación operacional/principios"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/prompt-evolution.md && echo "PASS" || echo "FAIL"
# Verificar que define las dos categorías
grep -q "\[OP\]" references/prompt-evolution.md && grep -q "\[BP\]" references/prompt-evolution.md && echo "PASS" || echo "FAIL"
# Verificar que learn.md menciona consolidación
grep -qi "consolidación\|consolidacion\|prompt.evolution" .claude/commands/learn.md && echo "PASS" || echo "FAIL"
# Verificar que claudemd-template tiene marcadores
grep -q "\[OP\]\|\[BP\]" templates/claudemd-template.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/prompt-evolution.md` existe y no está vacío
- [ ] `test_categories_defined`: El archivo define las categorías [OP] y [BP]
- [ ] `test_learn_consolidation`: `.claude/commands/learn.md` incluye paso de consolidación
- [ ] `test_template_markers`: `templates/claudemd-template.md` incluye marcadores de categoría

## Criterios de aceptación

- [ ] Existe `references/prompt-evolution.md` con protocolo completo
- [ ] Define ciclo de vida de regla: creación → activación → promoción/eliminación
- [ ] Define dos tipos de consolidación (mini y profunda) con triggers
- [ ] `.claude/commands/learn.md` categoriza reglas nuevas como [OP] y consolida en /learn de sprint
- [ ] `templates/claudemd-template.md` documenta las categorías [OP] y [BP]
- [ ] La consolidación referencia la experience library para validar utilidad

## NO hacer

- NUNCA modificar CLAUDE.md directamente — este ticket define el protocolo, /learn lo aplica
- NUNCA eliminar reglas existentes de CLAUDE.md — solo definir el mecanismo para que /learn las elimine
- NUNCA hacer la categorización retroactiva obligatoria — reglas sin marcador se tratan como [BP]
- NUNCA crear un comando separado de consolidación — se integra en /learn existente

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
