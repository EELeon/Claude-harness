# hardening-05 — Paso de lint obligatorio pre-commit

## Objetivo

Agregar paso de lint (ruff check + ruff format) al spec template y al prompt del subagente en el orchestrator-prompt, para que todo subagente corra lint antes de hacer commit. Esto previene el patrón recurrente de CI fallando por F401/I001/F841 después de cada sprint.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `.ai/rules-v3.md` — instancia vieja
- `references/recovery-matrix.md` — fuera de alcance

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar paso de lint antes del commit en la sección de subtareas |
| `templates/orchestrator-prompt.md` | Agregar instrucción de lint al prompt del subagente |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/spec-template.md`. En la sección "### [Opción A: Implementación directa — sin subdivisión]", modificar los pasos para insertar lint antes del commit. El bloque actual:

```
**Pasos:**
1. [Paso concreto con archivo y función]
2. [Paso concreto]
3. Correr tests: `[comando exacto]`
4. Commit: `"[tipo]: [descripción]"`
```

Debe quedar:

```
**Pasos:**
1. [Paso concreto con archivo y función]
2. [Paso concreto]
3. Correr tests: `[comando exacto]`
4. Lint pre-commit: `ruff check [archivos_tocados] --fix && ruff format [archivos_tocados]`
5. Commit: `"[tipo]: [descripción]"`
```

2. En la misma sección "### [Opción B: Con subtareas]", agregar el paso de lint en cada subtarea template. Después de `- **Tests:** \`[comando]\`` agregar:
   `- **Lint:** \`ruff check [archivos] --fix && ruff format [archivos]\``

3. Leer `templates/orchestrator-prompt.md`. Localizar el prompt del subagente (el bloque que empieza con "> Lee e implementa el spec en..."). Agregar al final del prompt, antes de "NO devuelvas logs completos":

```
Antes de hacer commit, corré `ruff check [archivos_que_tocaste] --fix && ruff format [archivos_que_tocaste]` para asegurar que el código pasa lint. Si ruff no está disponible en el proyecto, saltá este paso silenciosamente.
```

4. Commit: `"feat(hardening-05): lint obligatorio pre-commit en spec template y orchestrator prompt"`

---

## Tests que deben pasar

```bash
grep "ruff check" templates/spec-template.md
# Debe retornar al menos 2 líneas (opción A y opción B)

grep "ruff check" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea (prompt del subagente)

grep "ruff format" templates/spec-template.md
# Debe retornar al menos 1 línea
```

- [ ] `grep_spec_ruff`: El spec template menciona `ruff check` y `ruff format`
- [ ] `grep_prompt_ruff`: El orchestrator prompt menciona `ruff check` en el subagent prompt

## Criterios de aceptación

- [ ] El spec template tiene paso de lint antes del commit en Opción A
- [ ] El spec template tiene paso de lint en el template de subtareas (Opción B)
- [ ] El orchestrator prompt incluye instrucción de lint en el prompt del subagente
- [ ] El paso de lint incluye `--fix` para auto-corregir
- [ ] Hay fallback graceful si ruff no existe ("saltá este paso")

## NO hacer

- NUNCA asumir que ruff está disponible en todos los proyectos — siempre incluir fallback
- NUNCA modificar contenido que no sea el paso de lint y el prompt del subagente
- NUNCA agregar ruff como dependencia del harness
