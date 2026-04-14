# Ticket 12 — Métricas de ejecución en results.tsv (cherry-pick de P4)

## Objetivo

Extender el formato de `results.tsv` con columnas de métricas operacionales (tokens estimados, iteraciones, duración, scope warnings) para que `/retrospective` pueda detectar patrones de ineficiencia cuantitativamente. Hoy results.tsv solo registra pass/fail — este ticket agrega el "cuánto costó".

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna (el formato de results.tsv es independiente)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`
- `.claude/commands/retrospective.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `.claude/commands/learn.md` — fuera de scope
- `templates/spec-template.md` — fuera de scope
- `.ai/runs/results.tsv` — no existe en este momento (es temporal de sprint)

### Archivos condicionales
- `.claude/commands/status.md` — solo si se necesita mostrar las nuevas columnas en /status

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Extender el formato de results.tsv con 4 columnas nuevas |
| `.claude/commands/retrospective.md` | Agregar análisis de las nuevas métricas al protocolo de retrospectiva |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Leer `templates/orchestrator-prompt.md` y encontrar la sección "Formato de .ai/runs/results.tsv". Extender el header de:
   ```
   ticket	commit	tests	status	failure_category	description
   ```
   A:
   ```
   ticket	commit	tests	status	failure_category	iterations	scope_warnings	complexity	description
   ```

   **Nuevas columnas:**
   - `iterations`: número de intentos para completar el ticket (1 = primera vez, 2 = un retry, etc.)
   - `scope_warnings`: número de archivos tocados fuera de allowlist (0 = limpio)
   - `complexity`: complejidad del spec (Simple/Media/Alta) — para correlacionar con iteraciones

   Actualizar la documentación de columnas en la misma sección. Agregar ejemplo:
   ```
   T-1	a1b2c3d	passed	keep	none	1	0	Simple	result budgeting formal
   T-5	c3d4e5f	failed	discard	test_failure	2	1	Media	compactación — falló en primer intento
   ```

2. Leer `templates/orchestrator-prompt.md` y actualizar todas las referencias a results.tsv para que incluyan las nuevas columnas al registrar (Regla 2, Regla 4, sección "Al terminar").

3. Leer `.claude/commands/retrospective.md` y agregar sección de análisis de métricas:
   ```markdown
   ## Análisis de métricas operacionales

   Si `.ai/runs/results.tsv` (o los archivados en `.ai/specs/archive/*/`) tienen columnas de métricas:

   1. **Iteraciones por complejidad:** ¿Los tickets Media/Alta necesitan más intentos? ¿Hay un umbral donde la complejidad predice fallos?
   2. **Scope warnings:** ¿Hay tickets que consistentemente tocan archivos fuera de scope? Esto sugiere scope fences demasiado estrictos o specs mal definidos.
   3. **Ratio keep/discard por complejidad:** ¿Los tickets Alta fallan más? ¿Deberían subdividirse más agresivamente?
   4. **Tendencias entre sprints:** ¿Las iteraciones promedio bajan con el tiempo? (señal de que /learn y experience library están funcionando)

   Reportar hallazgos como insights candidatos para la experience library.
   ```

4. Verificar que el nuevo formato es backward-compatible: si un results.tsv viejo no tiene las columnas nuevas, /retrospective y /status deben funcionar sin error (las columnas faltantes se tratan como vacías).

5. Commit: `"feat(T-12): extender results.tsv con métricas de iteraciones, scope warnings, y complejidad"`

## Tests que deben pasar

```bash
# Verificar que orchestrator-prompt tiene las columnas nuevas
grep -q "iterations" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
grep -q "scope_warnings" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
# Verificar que retrospective tiene análisis de métricas
grep -qi "métricas\|metrics\|iterations" .claude/commands/retrospective.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_iterations_column`: `templates/orchestrator-prompt.md` define columna `iterations`
- [ ] `test_scope_warnings_column`: `templates/orchestrator-prompt.md` define columna `scope_warnings`
- [ ] `test_retrospective_analysis`: `.claude/commands/retrospective.md` incluye análisis de métricas

## Criterios de aceptación

- [ ] El formato de results.tsv tiene 3 columnas nuevas: iterations, scope_warnings, complexity
- [ ] Todas las reglas que registran en results.tsv actualizadas para incluir las nuevas columnas
- [ ] `.claude/commands/retrospective.md` analiza las métricas con 4 tipos de análisis
- [ ] El formato es backward-compatible (columnas faltantes no causan errores)
- [ ] Hay un ejemplo concreto del nuevo formato en la documentación

## NO hacer

- NUNCA cambiar el separador de tabs a comas — results.tsv usa tabs estrictamente
- NUNCA eliminar columnas existentes — solo agregar nuevas al final
- NUNCA agregar columnas que requieran cálculos complejos — las métricas deben ser observables directamente por el orquestador
- NUNCA crear un archivo de métricas separado — todo va en results.tsv para mantener una sola fuente de verdad

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
