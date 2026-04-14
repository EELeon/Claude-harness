# harden-03 — Política de iteración y escalamiento

## Objetivo

Agregar campos de control de iteración al contrato del ticket (frontmatter) y documentar la política de escalamiento para que el orquestador tenga criterios duros para cortar loops, escalar o descartar.

## Complejidad: Simple

## Dependencias

- Requiere: harden-02 completado (ambos modifican spec-template.md)
- Bloquea: harden-04

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `references/reglas-specs.md`

### Archivos prohibidos
- `commands/preflight.md` — se actualiza en harden-04
- `templates/orchestrator-prompt.md` — se actualiza en harden-05
- `references/permission-profiles.md` — ya tiene max_fix_attempts, no duplicar
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- `references/permission-profiles.md` — leer para entender qué campos de iteración ya existen a nivel de perfil (max_fix_attempts) y no duplicarlos

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar campos de iteración al frontmatter YAML. Agregar sección `## Política de iteración` después de `## Análisis de descomposición` con documentación expandida de cada campo. |
| `references/reglas-specs.md` | Agregar sección `## Campos de iteración` documentando valores default por complejidad y la relación con permission-profiles.md. |

## Archivos a crear

Ninguno.

---

## Subtareas

### Implementación directa — sin subdivisión

**Pasos:**
1. Leer `references/permission-profiles.md` para entender qué campos de iteración ya existen a nivel de perfil. Nota: `max_fix_attempts` ya existe en los perfiles. El campo `max_attempts` del frontmatter es por ticket y SOBREESCRIBE el default del perfil si está presente.
2. En `templates/spec-template.md`, verificar que el frontmatter (agregado por harden-01) ya tiene `max_attempts`. Si ya existe, no duplicar. Agregar los campos adicionales de escalamiento:
   ```yaml
   # Campos de iteración (agregar al frontmatter existente)
   max_attempts: 3  # Default: Simple=2, Media=3, Alta=4
   retry_only_if:
     - "tests fallan por causa identificable"
     - "scope violation en archivo no-denylist"
   escalate_if:
     - "el mismo test falla 2 veces seguidas con fix diferente"
     - "subagente reporta ambigüedad en el spec"
   blocked_if:
     - "dependencia no resuelta"
     - "archivo requerido no existe en el repo"
   discard_if:
     - "max_attempts alcanzado sin tests passing"
     - "scope violation en archivo denylist"
   ```
3. En `templates/spec-template.md`, agregar sección `## Política de iteración` después de `## Análisis de descomposición` y antes de `## Subtareas`:
   ```markdown
   ## Política de iteración

   <!-- Los campos de iteración están en el frontmatter.
        Esta sección documenta las condiciones específicas de este ticket.
        El orquestador usa el frontmatter para decisiones automáticas. -->

   - **Reintentar solo si:** [condiciones específicas de este ticket]
   - **Escalar si:** [cuándo pedir intervención humana]
   - **Bloquear si:** [precondiciones que impiden ejecución]
   - **Descartar si:** [cuándo abandonar el ticket]
   ```
4. En `references/reglas-specs.md`, agregar sección `## Campos de iteración`:
   ```markdown
   ## Campos de iteración

   Cada spec define en su frontmatter los límites de reintento y escalamiento.
   Estos campos son usados por el orquestador para tomar decisiones automáticas.

   | Campo | Tipo | Default por complejidad | Propósito |
   |-------|------|------------------------|-----------|
   | max_attempts | int | Simple=2, Media=3, Alta=4 | Intentos totales antes de descartar |
   | retry_only_if | list[str] | ["tests fallan por causa identificable"] | Condiciones para reintentar |
   | escalate_if | list[str] | ["mismo error 2+ veces"] | Cuándo pedir intervención |
   | blocked_if | list[str] | ["dependencia no resuelta"] | Precondiciones faltantes |
   | discard_if | list[str] | ["max_attempts alcanzado"] | Cuándo abandonar |

   **Relación con permission-profiles.md:**
   Los perfiles de permisos definen `max_fix_attempts` como default global.
   El campo `max_attempts` del frontmatter sobreescribe el default del perfil
   si está presente. El perfil es el floor; el spec puede ser más estricto.
   ```
5. Verificar que no hay contradicciones con los perfiles de permisos existentes.

**Tests:** No aplica (repo 100% markdown). Validación manual:
```bash
grep -n "max_attempts\|retry_only_if\|escalate_if\|blocked_if\|discard_if" templates/spec-template.md
```

- [ ] `campos_iteracion`: Los 5 campos de iteración están en el frontmatter del template
- [ ] `seccion_documentada`: La sección "Política de iteración" está en el template
- [ ] `reglas_actualizadas`: reglas-specs.md documenta los defaults por complejidad

## Criterios de aceptación

- [ ] El frontmatter de `templates/spec-template.md` tiene los 5 campos de iteración con valores default
- [ ] La sección `## Política de iteración` está en el template con formato de bullets expandibles
- [ ] `references/reglas-specs.md` tiene tabla de campos con defaults por complejidad
- [ ] La relación con `permission-profiles.md` está documentada (spec sobreescribe perfil)

## NO hacer

- NUNCA duplicar `max_fix_attempts` de permission-profiles — el campo del spec es `max_attempts` y sobreescribe
- NUNCA dejar campos de iteración sin defaults — cada campo debe tener un default razonable
- NUNCA usar condiciones vagas como "si parece que no funciona" — cada condición debe ser verificable

## Checklist de autocontención

- [x] Tiene scope fence (archivos permitidos + prohibidos)
- [x] Tiene dependencias de lectura listadas
- [x] Tiene rutas EXACTAS de archivos a modificar/crear
- [x] Tiene pasos concretos (no "investigar" o "explorar")
- [x] Tiene comando exacto de tests
- [x] Tiene commit message definido (abajo)
- [x] Tiene criterios de aceptación observables
- [x] Tiene restricciones claras en forma imperativa
- [x] Tiene ≤10 restricciones totales
- [x] No depende de contexto que solo existe en la conversación

**Commit:** `"feat(harden-03): agregar política de iteración y escalamiento al contrato de ticket"`
