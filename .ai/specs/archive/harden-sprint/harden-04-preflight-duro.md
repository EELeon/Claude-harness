# harden-04 — Preflight como gate determinístico duro

## Objetivo

Extender el preflight con validaciones determinísticas que verifiquen el frontmatter YAML, el gate de descomposición y los campos de iteración, convirtiendo el preflight de gate procedural a barrera estructural imposible de saltear.

## Complejidad: Media

## Dependencias

- Requiere: harden-01, harden-02, harden-03 completados (valida los campos que ellos agregan)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `commands/preflight.md`

### Archivos prohibidos
- `templates/spec-template.md` — ya modificado en harden-01/02/03
- `references/reglas-specs.md` — ya modificado en harden-01/03
- `templates/orchestrator-prompt.md` — se actualiza en harden-05
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- `templates/spec-template.md` — para verificar qué campos del frontmatter deben validarse
- `references/reglas-specs.md` — para verificar tipos y valores válidos de cada campo

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `commands/preflight.md` | Agregar un nuevo "Nivel 0: Frontmatter YAML" como primer nivel de validación (antes del actual Nivel 1). Agregar validaciones de descomposición y de iteración en los niveles existentes. Reorganizar el orden de ejecución para incluir Nivel 0. |

## Archivos a crear

Ninguno.

---

## Subtareas

### Subtarea 1 — Nivel 0: Validación de frontmatter YAML

- **Archivos:** `commands/preflight.md`
- **Pasos:**
  1. Agregar nueva sección `**Nivel 0: Frontmatter YAML (FAIL si falta o inválido)**` ANTES del actual Nivel 1.
  2. Definir las validaciones:
     ```markdown
     **Nivel 0: Frontmatter YAML (FAIL si falta o inválido)**

     El spec DEBE tener un bloque YAML frontmatter válido entre `---` markers.
     Ejecutar PRIMERO — si no hay frontmatter, no continuar con otros niveles.

     Validaciones:
     1. El archivo empieza con `---` en la primera línea (después del H1 si hay)
        o tiene un bloque delimitado por `---` al inicio
     2. El bloque YAML es parseable (no tiene errores de sintaxis)
     3. Campos obligatorios presentes (FAIL si falta alguno):

     | Campo | Tipo | Valores válidos |
     |-------|------|-----------------|
     | id | string | No vacío, formato `[prefix]-[seq]` |
     | title | string | No vacío |
     | goal | string | No vacío, 1-2 frases |
     | complexity | enum | Simple, Media, Alta |
     | execution_mode | enum | Subagente, Sesion_principal |
     | execution_class | enum | read_only, isolated_write, shared_write, repo_wide |
     | allowed_paths | list[str] | Al menos 1 entrada |
     | denied_paths | list[str] | Al menos 1 entrada |
     | closure_criteria | list[str] | Al menos 1 entrada |
     | required_validations | list[str] | Al menos 1 entrada |
     | max_attempts | int | > 0 |

     4. Campos de iteración presentes si complexity != Simple:

     | Campo | Tipo | Requerido si |
     |-------|------|-------------|
     | retry_only_if | list[str] | complexity = Media o Alta |
     | escalate_if | list[str] | complexity = Media o Alta |
     | blocked_if | list[str] | Siempre (puede ser vacío) |
     | discard_if | list[str] | Siempre |

     5. Campos de descomposición presentes si complexity != Simple:

     | Campo | Tipo | Requerido si |
     |-------|------|-------------|
     | decomposition_signals | int | complexity = Media o Alta |
     | decomposition_decision | enum | complexity = Media o Alta. Valores: unico, partido_en_N |

     Si el frontmatter falta completamente → FAIL con "frontmatter YAML no encontrado".
     Si un campo obligatorio falta → FAIL con "campo faltante: [nombre]".
     Si un valor es inválido → FAIL con "valor inválido para [campo]: [valor]".
     ```
- **Tests:**
  ```bash
  grep -n "Nivel 0" commands/preflight.md
  ```
- **Commit:** `"feat(harden-04a): agregar validación de frontmatter YAML al preflight"`

### Subtarea 2 — Validación de descomposición y coherencia

- **Depende de:** Subtarea 1
- **Archivos:** `commands/preflight.md`
- **Pasos:**
  1. Agregar un nuevo nivel `**Nivel 5: Validación de descomposición (FAIL si incoherente)**` después del actual Nivel 4.
  2. Definir las validaciones:
     ```markdown
     **Nivel 5: Validación de descomposición (FAIL si incoherente)**

     Solo para specs con complexity = Media o Alta.
     Para specs Simple, saltar este nivel.

     Validaciones:
     1. La sección `## Análisis de descomposición` existe y no está vacía
     2. El campo `decomposition_signals` del frontmatter coincide con el
        conteo de señales marcadas como "sí" en la sección
     3. Coherencia señales → decisión:
        - Si decomposition_signals ≥ 2 Y decomposition_decision = "unico" → FAIL
          con "ticket con ≥2 señales de complejidad debe partirse en sub-tickets"
        - Si decomposition_signals < 2 Y decomposition_decision = "unico" → OK
        - Si decomposition_decision = "partido_en_N" → OK (ya se partió)
     4. Verificación cruzada de señales contra datos del spec:
        - Señal "más de 8 archivos": contar allowed_paths del frontmatter.
          Si count > 8 y señal marcada "no" → WARN "posible señal no detectada"
        - Señal "más de 4 criterios independientes": contar closure_criteria.
          Si count > 4 y señal marcada "no" → WARN
        - Señal "más de 2 módulos": contar directorios únicos en allowed_paths.
          Si count > 2 y señal marcada "no" → WARN
     ```
  3. Agregar al formato de salida una línea para el Nivel 5:
     ```
     ### Descomposición
     ✅ Señales: 1/6 activas, decisión "unico" coherente
     ❌ Señales: 3/6 activas, decisión "unico" INCOHERENTE — debe partirse
     ```
  4. Actualizar la sección "Orden de ejecución" para incluir Nivel 0 y Nivel 5:
     ```
     0. Nivel 0 (frontmatter) — si falla, no continuar
     1. Nivel 1 (headings)
     2. Nivel 2 (no vacío)
     3. Nivel 3 (formato)
     4. Nivel 4 (cruces numéricos)
     5. Nivel 5 (descomposición) — solo para Media/Alta
     6. Validaciones semánticas
     ```
- **Tests:**
  ```bash
  grep -n "Nivel 5\|descomposición\|decomposition" commands/preflight.md
  ```
- **Commit:** `"feat(harden-04b): agregar validación de descomposición y coherencia al preflight"`

---

## Tests que deben pasar

```bash
# Verificar estructura completa del preflight actualizado
grep -c "Nivel" commands/preflight.md
# Debería ser >= 6 (Nivel 0-5)
```

- [ ] `nivel_0_existe`: Nivel 0 (frontmatter YAML) está definido con tabla de campos
- [ ] `nivel_5_existe`: Nivel 5 (descomposición) está definido con regla de coherencia
- [ ] `orden_actualizado`: La sección "Orden de ejecución" incluye niveles 0-5 + semántico

## Criterios de aceptación

- [ ] `commands/preflight.md` tiene Nivel 0 con validación de los 10+ campos obligatorios del frontmatter
- [ ] Nivel 0 falla si el frontmatter no existe o tiene campos faltantes
- [ ] Nivel 5 falla si `decomposition_signals ≥ 2` y `decomposition_decision = "unico"`
- [ ] Nivel 5 emite WARN si los datos del spec contradicen las señales declaradas
- [ ] El orden de ejecución es: 0 → 1 → 2 → 3 → 4 → 5 → semántico
- [ ] Si Nivel 0 falla, no se ejecutan los demás niveles

## NO hacer

- NUNCA eliminar las validaciones existentes de Nivel 1-4 — este ticket AGREGA niveles, no reemplaza
- NUNCA hacer el Nivel 5 opcional para tickets Media/Alta — es obligatorio
- NUNCA validar campos de descomposición para tickets Simple — no aplica
- NUNCA cambiar la severidad de validaciones existentes sin justificación

## Checklist de autocontención

- [x] Tiene scope fence (archivos permitidos + prohibidos)
- [x] Tiene dependencias de lectura listadas
- [x] Tiene rutas EXACTAS de archivos a modificar/crear
- [x] Tiene pasos concretos (no "investigar" o "explorar")
- [x] Tiene comando exacto de tests
- [x] Tiene commit message definido
- [x] Tiene criterios de aceptación observables
- [x] Tiene restricciones claras en forma imperativa
- [x] Tiene ≤10 restricciones totales
- [x] No depende de contexto que solo existe en la conversación

**Commit final:** `"feat(harden-04): preflight determinístico con validación de frontmatter y descomposición"`
