# Ticket 1 — Result Budgeting formal (presupuesto de salidas)

## Objetivo

Definir límites formales por tipo de salida de herramientas para que outputs grandes se persistan a disco y solo un preview corto entre al contexto del orquestador. Esto reduce contaminación de contexto, mejora reanudación y previene deriva.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/output-budgets.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `templates/spec-template.md` — lo toca T-2
- `.claude/settings.json` — configuración de hooks, fuera de scope
- `templates/claudemd-template.md` — template para repos target, no para este repo

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/output-budgets.md` | Documento de referencia con límites por tipo de salida, reglas de truncamiento, y estructura de artifacts en disco |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar referencia al result budgeting en la sección del patrón Heat Shield — que el subagente aplique truncamiento según los límites definidos |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/output-budgets.md` con:
   - Tabla de límites por tipo: `summary_max_chars: 500`, `test_output_max_chars: 1000`, `diff_excerpt_max_chars: 2000`, `log_preview_max_chars: 500`
   - Regla: si una salida excede el límite → guardarla en `.ai/artifacts/[tipo]/` y retornar solo: resumen (≤3 líneas), tamaño original, ruta del archivo, y primeras N líneas
   - Estructura de carpetas para artifacts: `.ai/artifacts/test-outputs/`, `.ai/artifacts/diffs/`, `.ai/artifacts/logs/`
   - Principio: "No toda salida merece entrar al contexto"
   - Ejemplo concreto de antes/después para un output de tests largo
2. Leer `templates/orchestrator-prompt.md` y en la sección "Patrón Heat Shield (retorno de subagentes)", agregar después del último punto:
   - Una referencia a `references/output-budgets.md` para que el orquestador aplique truncamiento
   - La regla: "Si un output excede los límites de `references/output-budgets.md`, persistir a `.ai/artifacts/` y retornar solo preview + ruta"
3. Verificar que el documento creado es consistente internamente (los límites mencionados en output-budgets.md coinciden con lo referenciado en orchestrator-prompt.md)
4. Commit: `"feat(T-1): agregar result budgeting formal con límites por tipo de salida"`

## Tests que deben pasar

```bash
# Verificar que el archivo existe y tiene contenido
test -s references/output-budgets.md && echo "PASS" || echo "FAIL"
# Verificar que orchestrator-prompt.md referencia output-budgets
grep -q "output-budgets" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_file_exists`: El archivo `references/output-budgets.md` existe y no está vacío
- [ ] `test_reference_in_prompt`: `templates/orchestrator-prompt.md` contiene referencia a `references/output-budgets.md`
- [ ] `test_limits_defined`: El archivo define al menos 4 tipos de límites con valores numéricos

## Criterios de aceptación

- [ ] Existe `references/output-budgets.md` con tabla de límites por tipo de salida
- [ ] Cada límite tiene un valor numérico concreto (no rangos vagos)
- [ ] El documento incluye la regla de truncamiento (qué hacer cuando se excede)
- [ ] El documento incluye estructura de carpetas para artifacts
- [ ] `templates/orchestrator-prompt.md` referencia el nuevo documento en la sección Heat Shield

## NO hacer

- NUNCA inventar tipos de salida que no existan en el flujo actual del orquestador — usar solo los que ya produce (test output, diffs, logs, resúmenes)
- NUNCA modificar la lógica existente del Heat Shield — solo agregar la referencia al budgeting
- NUNCA poner los límites en CLAUDE.md — van en su propio documento de referencia
- NUNCA crear los directorios `.ai/artifacts/` — se crean bajo demanda cuando haya outputs reales

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
