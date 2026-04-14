# harden-02 — Gate de descomposición obligatorio

## Objetivo

Forzar un análisis de descomposición antes de escribir specs de complejidad Media o Alta, con señales medibles que obliguen a partir tickets amplios en sub-tickets independientes.

## Complejidad: Simple

## Dependencias

- Requiere: harden-01 completado (ambos modifican spec-template.md)
- Bloquea: harden-03, harden-04

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`
- `references/subagent-sizing.md`

### Archivos prohibidos
- `commands/preflight.md` — se actualiza en harden-04
- `references/reglas-specs.md` — ya se modificó en harden-01
- `.ai/*` — archivos de estado del orquestador

---

## Archivos de lectura (dependencias implícitas)

- Ninguna

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar sección `## Análisis de descomposición` con checklist de 6 señales medibles, ANTES de la sección `## Subtareas`. Agregar campo `decomposition_decision` al frontmatter YAML. |
| `references/subagent-sizing.md` | Agregar sección inicial `## Cuándo partir un ticket en sub-tickets` ANTES de la sección existente `## Cuándo dividir un ticket en subtareas con subagentes`. Distinguir claramente: sub-tickets (specs independientes) vs subtareas (divisiones dentro de un spec). |

## Archivos a crear

Ninguno.

---

## Subtareas

### Implementación directa — sin subdivisión

**Pasos:**
1. En `templates/spec-template.md`, agregar al frontmatter YAML (después de `max_attempts`):
   ```yaml
   decomposition_signals: 0  # Número de señales activas (0-6)
   decomposition_decision: "unico | partido_en_N"
   ```
2. En `templates/spec-template.md`, agregar la sección `## Análisis de descomposición` ANTES de `## Subtareas`, con este contenido:
   ```markdown
   ## Análisis de descomposición

   <!-- OBLIGATORIO para tickets de complejidad Media o Alta.
        Responder ANTES de escribir el resto del spec.
        Para tickets Simple, escribir "N/A — ticket Simple" y continuar. -->

   Señales de complejidad evaluadas:
   - [ ] Objetivo tiene múltiples responsabilidades conectadas con "y": [sí/no — si sí, cuáles]
   - [ ] Más de 8 archivos en scope fence (allowed_paths): [sí/no — count: N]
   - [ ] Más de 4 criterios de aceptación que verifican cosas independientes: [sí/no — count: N]
   - [ ] Subtareas no comparten archivos entre sí (señal de tickets independientes disfrazados): [sí/no]
   - [ ] Toca más de 2 módulos/directorios distintos del repo: [sí/no — cuáles]
   - [ ] Complejidad Alta + más de 3 subtareas: [sí/no]

   Señales activas: [N]/6

   <!-- REGLA DE DECISIÓN:
        - Si ≥ 2 señales activas → OBLIGATORIO partir en sub-tickets
        - Si < 2 señales activas → puede mantenerse como ticket único
        - Si dice "unico" con ≥ 2 señales → FAIL en preflight -->

   Decisión: [unico | partido_en_N]
   Justificación: [Por qué se mantiene junto / cómo se partió]
   ```
3. En `references/subagent-sizing.md`, agregar al inicio (después del heading H1 y antes de `## Contexto técnico`) una nueva sección:
   ```markdown
   ## Cuándo partir un TICKET en sub-tickets (antes de escribir el spec)

   IMPORTANTE: Esta decisión ocurre ANTES de escribir el spec.
   Es diferente de dividir un ticket en subtareas (que ocurre DENTRO del spec).

   | Concepto | Qué es | Cuándo decidir |
   |----------|--------|---------------|
   | Sub-tickets | Specs independientes, cada uno con su propio scope fence, auditoría y commit | ANTES de escribir el spec |
   | Subtareas | Divisiones de trabajo dentro de UN spec, comparten scope fence | DENTRO del spec ya escrito |

   Un tema debe partirse en sub-tickets cuando dispara 2+ señales de complejidad
   (ver sección "Análisis de descomposición" en spec-template.md).

   Señales de complejidad:
   1. Objetivo con múltiples responsabilidades ("implementar X Y migrar Z")
   2. Más de 8 archivos en scope
   3. Más de 4 criterios de aceptación independientes
   4. Subtareas sin archivos compartidos
   5. Más de 2 módulos/directorios afectados
   6. Complejidad Alta + más de 3 subtareas

   La opción default es PARTIR. Mantener junto requiere justificación explícita
   y menos de 2 señales activas.
   ```
4. Verificar que la distinción sub-tickets vs subtareas queda clara y no contradice las reglas existentes de sizing.

**Tests:** No aplica (repo 100% markdown). Validación manual:
```bash
# Verificar que la sección existe en el template
grep -n "Análisis de descomposición" templates/spec-template.md
grep -n "decomposition" templates/spec-template.md
```

- [ ] `seccion_existe`: La sección "Análisis de descomposición" está en spec-template.md
- [ ] `frontmatter_campos`: Los campos `decomposition_signals` y `decomposition_decision` están en el frontmatter
- [ ] `sizing_actualizado`: subagent-sizing.md tiene la nueva sección de sub-tickets

## Criterios de aceptación

- [ ] `templates/spec-template.md` tiene la sección `## Análisis de descomposición` con las 6 señales como checklist
- [ ] El frontmatter tiene campos `decomposition_signals` y `decomposition_decision`
- [ ] `references/subagent-sizing.md` tiene sección `## Cuándo partir un TICKET en sub-tickets` al inicio
- [ ] La distinción sub-tickets vs subtareas está documentada explícitamente con tabla comparativa
- [ ] La regla de decisión es clara: ≥2 señales = OBLIGATORIO partir

## NO hacer

- NUNCA mezclar la lógica de sub-tickets con la lógica de subtareas — son decisiones en momentos diferentes del flujo
- NUNCA hacer la descomposición opcional para tickets Media/Alta — es obligatoria
- NUNCA permitir "considerar" como verbo — la decisión es binaria: "unico" o "partido_en_N"

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

**Commit:** `"feat(harden-02): agregar gate de descomposición obligatorio al spec-template"`
