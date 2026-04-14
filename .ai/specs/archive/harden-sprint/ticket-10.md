# Ticket 10 — Perfiles de permiso configurables

## Objetivo

Definir 3 perfiles de permiso (conservative, standard, aggressive) que configuren el nivel de autonomía del orquestador durante la ejecución. Esto permite usar el mismo harness para contextos de alto riesgo (producción) y de exploración (prototipos) sin modificar la infraestructura.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/permission-profiles.md`
- `templates/execution-plan-template.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `.claude/settings.json` — no modificar hooks por perfil
- `templates/spec-template.md` — fuera de scope
- `.claude/commands/learn.md` — fuera de scope

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/permission-profiles.md` | Documento con los 3 perfiles, sus reglas, y guía de selección |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/execution-plan-template.md` | Agregar campo `permission_profile` con las 3 opciones |
| `templates/orchestrator-prompt.md` | Agregar referencia a perfiles en la sección de setup inicial |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/permission-profiles.md` con:

   **3 perfiles:**

   | Aspecto | conservative | standard | aggressive |
   |---------|-------------|----------|------------|
   | Auto-merge si tests pasan | No — siempre pedir revisión | No | Sí |
   | Rollback en scope warning | Sí — tratar warnings como errors | No — solo en violations | No — ignorar warnings |
   | Max intentos de fix por ticket | 1 | 2 | 3 |
   | /simplify obligatorio | Sí (todos los tickets) | Solo Media/Alta | No |
   | Cleanup automático post-sprint | No — usuario confirma | Sí | Sí + borrar branches |
   | Batch paralelo | No — siempre secuencial | Sí (si batch-eligible) | Sí + más agresivo en eligibilidad |
   | Anti-racionalización hook | Obligatorio | Recomendado | Opcional |
   | Punto de corte | Cada 2 tickets | Cada 3-4 tickets | Cada 5-6 tickets |

   **Guía de selección:**
   - `conservative`: producción, repos con CI estricto, primera ejecución en un repo nuevo
   - `standard`: desarrollo activo, repos conocidos, sprints regulares
   - `aggressive`: prototipos, refactorings masivos, repos experimentales

   **Cómo funciona:** El orquestador lee el perfil del plan de ejecución al inicio y ajusta su comportamiento según la tabla. No requiere cambios en hooks ni settings — es puramente lógica del prompt.

2. Leer `templates/execution-plan-template.md` y agregar después de "Rama: `[nombre-rama]`":
   ```markdown
   Perfil de permiso: `[conservative | standard | aggressive]`
   <!-- Ver references/permission-profiles.md para detalles de cada perfil -->
   ```

3. Leer `templates/orchestrator-prompt.md` y agregar en "Setup inicial" (después de leer rules.md):
   ```markdown
   3. Lee el perfil de permiso en `.ai/plan.md`. Ajustá tu comportamiento según `references/permission-profiles.md`.
      Si no hay perfil definido, usá `standard` como default.
   ```

4. Verificar consistencia entre los 3 archivos
5. Commit: `"feat(T-10): agregar perfiles de permiso configurables (conservative/standard/aggressive)"`

## Tests que deben pasar

```bash
# Verificar que el archivo existe
test -s references/permission-profiles.md && echo "PASS" || echo "FAIL"
# Verificar que define los 3 perfiles
grep -c "conservative\|standard\|aggressive" references/permission-profiles.md | xargs test 3 -le && echo "PASS" || echo "FAIL"
# Verificar que execution-plan-template tiene campo
grep -qi "perfil de permiso\|permission_profile" templates/execution-plan-template.md && echo "PASS" || echo "FAIL"
# Verificar referencia en orchestrator-prompt
grep -qi "perfil\|permission" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_reference_exists`: El archivo `references/permission-profiles.md` existe
- [ ] `test_three_profiles`: Define los 3 perfiles con diferencias claras
- [ ] `test_plan_template_field`: `templates/execution-plan-template.md` incluye campo de perfil
- [ ] `test_prompt_reference`: `templates/orchestrator-prompt.md` referencia los perfiles

## Criterios de aceptación

- [ ] Existe `references/permission-profiles.md` con tabla comparativa de 3 perfiles
- [ ] Cada perfil tiene al menos 6 aspectos configurables con valores concretos
- [ ] Incluye guía de selección con ejemplos de cuándo usar cada uno
- [ ] `templates/execution-plan-template.md` tiene campo `Perfil de permiso`
- [ ] `templates/orchestrator-prompt.md` lee y aplica el perfil al inicio
- [ ] El default es `standard` si no se especifica

## NO hacer

- NUNCA crear archivos de configuración separados por perfil — todo vive en un solo documento de referencia
- NUNCA modificar hooks o settings.json por perfil — los perfiles son lógica del prompt, no infraestructura
- NUNCA hacer que los perfiles cambien el formato de specs o results.tsv — solo cambian el comportamiento del orquestador

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
