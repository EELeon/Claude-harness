# Ticket 5 — Política de compactación de 3 niveles

## Objetivo

Definir una política documentada de compactación progresiva (microcompact → snip → reset resumible) que automatice la gestión de contexto del orquestador. Hoy depende del usuario ejecutando `/compact` o `/clear` manualmente; este ticket formaliza cuándo y cómo compactar en cada nivel.

## Complejidad: Media

## Dependencias

- Requiere: T-1 completado (Result Budgeting — la compactación nivel 1 referencia los artifacts persistidos a disco)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/compaction-policy.md`
- `templates/orchestrator-prompt.md`
- `.ai/rules.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `templates/spec-template.md` — fuera de scope
- `.claude/settings.json` — configuración de hooks
- `references/output-budgets.md` — creado por T-1, no modificar

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/compaction-policy.md` | Documento de referencia con los 3 niveles de compactación, triggers, acciones, y ejemplos |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Integrar la política de compactación en la Regla 4 (Gestión de contexto) y en la sección de puntos de corte |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/compaction-policy.md` con 3 niveles:

   **Nivel 1 — Microcompact (automático, continuo):**
   - Trigger: después de cada interacción con subagente
   - Acciones:
     - Sustituir outputs repetidos por referencias a artifact path (ver `references/output-budgets.md`)
     - Colapsar resultados de tests idénticos en una sola línea: "Tests: N passed (sin cambios desde iteración anterior)"
     - Reemplazar diffs repetidos por "sin cambios desde iteración N"
     - Usar solo Heat Shield (resumen ≤4 líneas) en vez de output completo
   - Responsable: el prompt del orquestador (regla embedded)

   **Nivel 2 — Snip (semi-automático, entre tickets):**
   - Trigger: al completar un ticket (después de registrar en results.tsv)
   - Acciones:
     - Mantener en contexto solo cola protegida: spec del ticket actual, últimos 2 resultados de results.tsv, reglas activas (.ai/rules.md), CLAUDE.md
     - Todo output previo → ya persistido a disco por Heat Shield
     - Sugerir `/compact` si el contexto acumulado supera ~3 tickets
   - Responsable: Regla 4 del orquestador

   **Nivel 3 — Reset resumible (manual, entre bloques de trabajo):**
   - Trigger: punto de corte marcado en plan, o contexto pesado (>80% estimado)
   - Acciones:
     - Escribir snapshot mínimo a disco: ticket actual + progreso + siguiente pendiente
     - Ejecutar `/clear`
     - Al retomar: leer `.ai/runs/results.tsv` + `.ai/plan.md` + spec del siguiente ticket
   - Responsable: el usuario (con guía del orquestador)
   - Incluir instrucciones exactas de qué pegar en Claude Code después del /clear

   Para cada nivel incluir: trigger, acciones exactas, responsable, ejemplo concreto de antes/después.

2. Leer `templates/orchestrator-prompt.md` y modificar:
   - En la **Regla 4 (Gestión de contexto)**: reescribir para incorporar los 3 niveles. Nivel 1 se aplica automáticamente. Nivel 2 se sugiere después de cada ticket. Nivel 3 se activa en puntos de corte.
   - En la sección de **Puntos de corte**: agregar referencia a Nivel 3 de la política
   - Agregar referencia: "Para detalles completos de la política, ver `references/compaction-policy.md`"

3. Verificar consistencia entre el documento de referencia y lo que dice orchestrator-prompt.md
4. Commit: `"feat(T-5): agregar política de compactación de 3 niveles"`

## Tests que deben pasar

```bash
# Verificar que el archivo existe y tiene contenido sustancial
test -s references/compaction-policy.md && echo "PASS" || echo "FAIL"
# Verificar que tiene los 3 niveles
grep -c "Nivel" references/compaction-policy.md | xargs test 3 -le && echo "PASS" || echo "FAIL"
# Verificar referencia en orchestrator-prompt
grep -q "compaction-policy" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_file_exists`: El archivo `references/compaction-policy.md` existe y no está vacío
- [ ] `test_three_levels`: El archivo define exactamente 3 niveles (Microcompact, Snip, Reset)
- [ ] `test_reference_in_prompt`: `templates/orchestrator-prompt.md` referencia la política de compactación

## Criterios de aceptación

- [ ] Existe `references/compaction-policy.md` con 3 niveles claramente diferenciados
- [ ] Cada nivel tiene: trigger, acciones exactas, responsable, y ejemplo
- [ ] El Nivel 1 referencia `references/output-budgets.md` de T-1
- [ ] El Nivel 3 incluye instrucciones exactas de retomar después de `/clear`
- [ ] `templates/orchestrator-prompt.md` Regla 4 integra los 3 niveles
- [ ] La política es consistente con el patrón Heat Shield existente

## NO hacer

- NUNCA crear un runtime automático de compactación — esto es una política documentada, no código ejecutable
- NUNCA eliminar la Regla 4 existente en orchestrator-prompt.md — refactorizarla para incorporar los 3 niveles
- NUNCA contradecir la recomendación existente de `/compact` después de 3+ tickets — integrarla como Nivel 2
- NUNCA hacer que Nivel 1 dependa de contar tokens exactos — usar heurísticas simples (repetición de outputs, tickets completados)

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
