# hardening-08 — results.tsv exclusivo del orquestador

## Objetivo

Agregar restricción explícita en la Regla 4 del orchestrator-prompt, en el prompt del subagente, y en el spec template: subagentes NUNCA escriben en `.ai/`. Esto previene que subagentes paralelos corrompan results.tsv o archivos de estado.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`
- `templates/spec-template.md`

### Archivos prohibidos
- `.ai/rules-v3.md` — instancia vieja
- `.ai/runs/results.tsv` — datos, no template

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar restricción en Regla 4 y en prompt del subagente |
| `templates/spec-template.md` | Agregar `.ai/` a la sección de archivos prohibidos como ejemplo estándar |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md`.

2. En la Regla 4 ("Gestión de contexto"), agregar al inicio (antes de "Después de cada ticket completado"):

```
**Propiedad exclusiva:** Los archivos en `.ai/runs/`, `.ai/plan.md`, y `.ai/rules.md`
son EXCLUSIVOS del orquestador. Los subagentes NUNCA deben escribir en estos archivos.
Si un subagente modifica archivos en `.ai/`, revertir esos archivos específicos con
`git checkout HEAD -- .ai/` antes de aceptar el commit.
```

3. En el prompt del subagente (el bloque "> Lee e implementa el spec en..."), agregar antes de "NO devuelvas logs completos":

```
NUNCA modifiques archivos en el directorio .ai/ (results.tsv, plan.md, rules.md, etc.) — estos son propiedad exclusiva del orquestador.
```

4. Leer `templates/spec-template.md`. En la sección "### Archivos prohibidos", agregar un ejemplo estándar que siempre debería estar:

Después de la línea `- \`ruta/config_produccion.py\` — [razón: configuración compartida]`, agregar:

```
- `.ai/*` — [razón: archivos de estado del orquestador — NUNCA tocar desde subagente]
```

5. Commit: `"feat(hardening-08): results.tsv y .ai/ exclusivos del orquestador"`

---

## Tests que deben pasar

```bash
grep "Propiedad exclusiva\|EXCLUSIVOS del orquestador" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "NUNCA modifiques archivos en.*\.ai" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea (en el prompt del subagente)

grep "\.ai/\*.*orquestador" templates/spec-template.md
# Debe retornar al menos 1 línea
```

- [ ] `grep_exclusive`: La Regla 4 declara propiedad exclusiva de `.ai/`
- [ ] `grep_subagent_ban`: El prompt del subagente prohíbe tocar `.ai/`
- [ ] `grep_spec_template`: El spec template lista `.ai/*` como prohibido por default

## Criterios de aceptación

- [ ] La Regla 4 tiene párrafo de propiedad exclusiva de `.ai/`
- [ ] El prompt del subagente prohíbe explícitamente tocar `.ai/`
- [ ] El spec template incluye `.ai/*` como ejemplo de archivo prohibido estándar
- [ ] La instrucción es revertir (no rollback total) si el subagente toca `.ai/`

## NO hacer

- NUNCA bloquear completamente a subagentes de LEER `.ai/` — solo de ESCRIBIR
- NUNCA cambiar el formato del spec template más allá de agregar el ejemplo
