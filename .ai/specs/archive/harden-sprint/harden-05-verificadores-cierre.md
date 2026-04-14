# harden-05 — Verificadores determinísticos de cierre

## Objetivo

Agregar checks mecánicos post-ejecución al flujo de auditoría en el orchestrator-prompt, de modo que el cierre de un ticket dependa de verificaciones objetivas (archivos existen, diff no vacío, paths dentro de allowlist) en vez del discurso del agente.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna (modifica archivo independiente de T1-T4)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `templates/spec-template.md` — ya modificado en harden-01/02/03
- `commands/preflight.md` — ya modificado en harden-04
- `references/reglas-specs.md` — ya modificado en harden-01/03
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- Ninguna

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar nueva `## Regla 2e: Verificadores determinísticos de cierre` después de la Regla 2c existente. Integrar con el flujo de verificación post-subagente. |

## Archivos a crear

Ninguno.

---

## Subtareas

### Implementación directa — sin subdivisión

**Pasos:**
1. En `templates/orchestrator-prompt.md`, dentro del bloque de código markdown de `.ai/rules.md`, agregar la nueva regla DESPUÉS de `## Regla 2c` y ANTES de `## Regla 3`:
   ```markdown
   ## Regla 2e: Verificadores determinísticos de cierre
   Antes de declarar `keep`, ejecutar estos checks mecánicos.
   Cada check es binario (pasa/falla) y NO requiere interpretación del LLM.

   **Checks obligatorios (FAIL si alguno falla):**

   | # | Check | Comando | Criterio de fallo |
   |---|-------|---------|-------------------|
   | 1 | Commit existe | `git rev-parse HEAD` vs hash anterior | Hashes iguales → FAIL (ya cubierto por 2d, pero verificar) |
   | 2 | Diff no vacío | `git diff --stat [hash anterior]..HEAD` | 0 archivos tocados → FAIL |
   | 3 | Archivos tocados ⊆ allowed_paths | `git diff --name-only [hash]..HEAD` vs frontmatter.allowed_paths | Archivo fuera de allowed_paths → ya cubierto por 2b |
   | 4 | Artefactos requeridos existen | Para cada archivo en frontmatter.allowed_paths que sea "a crear": `ls [ruta]` | Archivo faltante → FAIL |
   | 5 | Tests requeridos corrieron | Exit code del comando de tests del spec | Exit code ≠ 0 → ya cubierto por Regla 2 |
   | 6 | Criterios de aceptación cubiertos | Para cada criterio en frontmatter.closure_criteria: verificar con el tipo correspondiente (ver tabla en Regla 2c) | <80% → FAIL |

   **Checks de coherencia (WARN):**

   | # | Check | Cómo verificar | Resultado |
   |---|-------|---------------|-----------|
   | 7 | Spec pedía código + docs → ambos presentes | Clasificar archivos tocados por extensión (.py, .md, etc.) | WARN si falta una categoría esperada |
   | 8 | max_attempts no excedido | Contar intentos en results.tsv para este ticket | WARN si attempts = max_attempts (límite alcanzado) |
   | 9 | Desviaciones tácticas mínimas | Contar líneas de "desviaciones tácticas" en Heat Shield | WARN si > 2 líneas |

   **Orden de ejecución completo post-subagente (actualizado):**
   ```
   Regla 2d (commit) → Regla 2b (scope) → Regla 2 paso 5 (tests)
   → Regla 2c (completitud semántica) → Regla 2e (verificadores determinísticos)
   → keep/discard
   ```

   Si Regla 2e falla en checks obligatorios (1-6): `discard` con
   `failure_category=verification_failed`.
   Si solo falla en checks de coherencia (7-9): `keep` con warnings
   registrados en la columna description de results.tsv.
   ```
2. Actualizar la sección existente "Orden completo de verificación post-subagente" en Regla 2c para incluir Regla 2e al final de la cadena.
3. Agregar `verification_failed` a la tabla de categorías de fallo:
   ```
   | `verification_failed` | Orquestador (Regla 2e) | Después de verificadores | Check determinístico falla: artefacto faltante, diff vacío cuando debía haber cambios, o coherencia de tipos de archivos |
   ```
4. Verificar que la nueva regla no contradice las reglas 2b y 2c existentes — Regla 2e complementa, no duplica. Los checks que ya cubren 2b y 2d se mencionan como "ya cubierto por" para evitar doble verificación.

**Tests:** No aplica (repo 100% markdown). Validación manual:
```bash
grep -n "Regla 2e\|verificadores determinísticos\|verification_failed" templates/orchestrator-prompt.md
```

- [ ] `regla_2e_existe`: La Regla 2e está definida con tabla de checks obligatorios
- [ ] `categoria_fallo`: `verification_failed` está en la tabla de categorías
- [ ] `orden_actualizado`: El orden post-subagente incluye 2d → 2b → 2 → 2c → 2e

## Criterios de aceptación

- [ ] `templates/orchestrator-prompt.md` tiene `## Regla 2e` con 9 checks definidos (6 obligatorios + 3 coherencia)
- [ ] La categoría `verification_failed` está agregada a la tabla de failure categories
- [ ] El orden de verificación post-subagente incluye Regla 2e como último paso antes de keep/discard
- [ ] Los checks que ya cubren 2b/2d están marcados explícitamente como "ya cubierto por" para evitar duplicación

## NO hacer

- NUNCA duplicar verificaciones que ya hacen Regla 2b (scope) o 2d (commit) — referenciar, no repetir
- NUNCA hacer los checks de coherencia (7-9) bloqueantes — son WARN, no FAIL
- NUNCA agregar checks que requieran interpretación semántica del LLM — todos deben ser mecánicos/binarios

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

**Commit:** `"feat(harden-05): agregar verificadores determinísticos de cierre al flujo de auditoría"`
