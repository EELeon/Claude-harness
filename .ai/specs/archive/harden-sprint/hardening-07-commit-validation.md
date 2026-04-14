# hardening-07 — Validación de commit post-subagente

## Objetivo

Agregar paso "2d (Commit)" a la Regla 2 en `templates/orchestrator-prompt.md` que valida que el subagente realmente produjo un commit. Si el subagente reporta "keep" pero no hay commit nuevo, marcar como FAIL. También agregar situación #11 "Subagente sin commit" a `references/recovery-matrix.md`.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`
- `references/recovery-matrix.md`

### Archivos prohibidos
- `.ai/rules-v3.md` — instancia vieja
- `templates/spec-template.md` — fuera de alcance

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar paso 2d a Regla 2 |
| `references/recovery-matrix.md` | Agregar situación #11 |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md` y localizar la Regla 2 ("Verificación y rollback automático").

2. Después del paso 3 ("Verificá que el commit existe: `git log -1 --oneline`"), agregar:

```
3b. **Validación de commit (Regla 2d):**
   Comparar el hash actual (`git rev-parse HEAD`) con el hash guardado antes del subagente.
   - Si son iguales → el subagente NO hizo commit. Marcar como `discard` con
     `failure_category=no_commit`. NO intentar rescatar cambios uncommitted manualmente
     — el subagente falló en cumplir el contrato de commit atómico.
   - Si son diferentes → el subagente hizo commit. Continuar con Regla 2b (scope).
   
   **Evidencia:** En sprints observados, subagentes que reportan "completado" sin commit
   requieren rescate manual costoso (leer diffs, commitear a mano, verificar scope).
   Es más eficiente descartar y re-ejecutar.
```

3. En el "**Orden completo de verificación post-subagente:**", cambiar:
   
**Antes:** `Regla 2b (scope) → Regla 2 paso 4 (tests) → Regla 2c (completitud)`
**Después:** `Regla 2d (commit) → Regla 2b (scope) → Regla 2 paso 5 (tests) → Regla 2c (completitud)`

4. Leer `references/recovery-matrix.md`. Agregar fila #11 a la tabla de situaciones:

```
| 11 | Subagente sin commit | Hash pre/post subagente idénticos | `discard` | Registrar no_commit, re-ejecutar subagente |
```

5. Agregar detalle después de la sección "### 10." (si ya existe por hardening-04, sino después de la #9):

```markdown
### 11. Subagente sin commit — `discard`

**Señales de detección:**
- `git rev-parse HEAD` antes y después del subagente son idénticos
- El subagente reporta "completado" pero no hay commit nuevo
- Hay cambios uncommitted en el working directory

**Pasos exactos:**
1. Registrar `discard` con `failure_category=no_commit` en results.tsv
2. Descartar cualquier cambio uncommitted: `git checkout -- .` y `git clean -fd`
3. Re-ejecutar el subagente con el mismo spec (cuenta como iteración 2)
4. Si falla de nuevo → registrar como `discard` definitivo y continuar

**Ejemplo concreto:** El subagente de F-4 termina sin commit. Git status muestra
archivos modificados. En vez de commitear manualmente (riesgo de scope violation),
descartar y re-ejecutar. Si el spec es correcto, el subagente debería poder
completar en un segundo intento.
```

6. Agregar a la tabla de categorías de fallo en el orchestrator-prompt.md, después de `spec_ambiguity`:

```
| `no_commit` | Orquestador (Regla 2d) | Después de validación de commit | Hash pre/post subagente idénticos — subagente no completó commit atómico |
```

7. Commit: `"feat(hardening-07): validación de commit post-subagente — Regla 2d"`

---

## Tests que deben pasar

```bash
grep "Regla 2d\|2d.*Commit\|Validación de commit" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "no_commit" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea (categoría de fallo)

grep "Subagente sin commit" references/recovery-matrix.md
# Debe retornar al menos 1 línea
```

- [ ] `grep_2d`: La Regla 2d existe en el orchestrator prompt
- [ ] `grep_no_commit`: La categoría `no_commit` está documentada
- [ ] `grep_recovery`: La situación #11 existe en recovery matrix

## Criterios de aceptación

- [ ] La Regla 2 tiene paso 2d que compara hashes pre/post subagente
- [ ] Si no hay commit, se marca `discard` con `failure_category=no_commit`
- [ ] La instrucción es NO rescatar manualmente — descartar y re-ejecutar
- [ ] La recovery matrix tiene situación #11 con pasos de recuperación
- [ ] El orden de verificación incluye 2d antes de 2b

## NO hacer

- NUNCA rescatar cambios uncommitted de un subagente manualmente — descartar y re-ejecutar
- NUNCA cambiar el contenido de las Reglas 2b o 2c (solo agregar 2d)
