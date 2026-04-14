# [sprint-prefix]-[seq] — [Título descriptivo]

<!-- Naming convention: ver references/spec-naming.md
     Formato del archivo: [sprint-prefix]-[seq]-[slug].md
     Ejemplo: hardening-01-cherrypick-safe.md -->

---
id: "[sprint-prefix]-[seq]"
title: "[Título descriptivo]"
goal: "[1-2 frases — mismo contenido que ## Objetivo]"
complexity: Simple | Media | Alta
execution_mode: Subagente | Sesion_principal
execution_class: read_only | isolated_write | shared_write | repo_wide
allowed_paths:
  - "ruta/exacta/archivo.py"
denied_paths:
  - "ruta/config_produccion.py"
dependencies:
  requires: [] | ["harden-01"]
  blocks: [] | ["harden-02"]
closure_criteria:
  - "Criterio observable y verificable"
required_validations:
  - "comando o check específico"
max_attempts: 3
decomposition_signals: 0  # Número de señales activas (0-6)
decomposition_decision: "unico | partido_en_N"
---

<!-- El frontmatter es la fuente de verdad para validación automática.
     Las secciones markdown expanden el detalle para el subagente ejecutor. -->

## Objetivo

[1-2 frases. Qué cambia en el sistema después de implementar este ticket.]

## Dependencias

- Requiere: [Ticket X completado | Ninguna]
- Bloquea: [Ticket Y | Ninguno]

<!--
DEPENDENCIAS FUERTES — Patrón Interface-First:
Si este ticket depende de otro que AÚN NO está implementado, definir
un contrato explícito (interfaz, tipo, stub) que ambos tickets respeten.
Esto permite desarrollo paralelo sin bloqueo.
Ejemplo: Si Ticket B consume una API de Ticket A, definir el schema
de request/response como stub antes de implementar cualquiera.
-->

## Lock requirements (opcional — solo para batch/audit)

<!--
Solo llenar si el ticket puede correr en paralelo con otros.
Ver references/task-locks.md para el protocolo completo de locks.
-->
- Archivos que requieren lock exclusivo: [lista]
- Lease estimado: [Simple=10min | Media=15min | Alta=30min]

---

## Scope fence (alcance permitido)

<!--
SCOPE FENCE — La restricción más importante para precisión.
El subagente SOLO puede tocar archivos dentro del alcance.
Si toca algo fuera, el orquestador marca scope_violation.

Sin esta sección, Claude Code tiende a "arreglar" cosas fuera del
alcance del ticket, causando efectos colaterales no deseados.
-->

### Archivos permitidos
<!-- Lista EXHAUSTIVA de archivos que este ticket puede modificar o crear -->
- `ruta/exacta/archivo.py`
- `ruta/exacta/nuevo.py`
- `tests/test_modulo.py`

### Archivos prohibidos
<!-- Archivos que NUNCA deben tocarse, aunque parezca útil -->
- `ruta/config_produccion.py` — [razón: configuración compartida]
- `ruta/otro_modulo.py` — [razón: fuera del alcance de este ticket]
- `.ai/*` — [razón: archivos de estado del orquestador — NUNCA tocar desde subagente]

### Archivos condicionales (opcional)
<!--
Archivos que pueden tocarse SOLO si se cumple una condición específica.
La condición debe describir un CAMBIO OBSERVABLE en el diff:
  ✅ Bueno: "solo si se agrega una función nueva" (verificable en diff)
  ✅ Bueno: "solo si se necesita un import nuevo" (verificable en diff)
  ❌ Malo: "solo si es necesario" (no verificable)
  ❌ Malo: "solo si tiene sentido" (subjetivo)
-->
- `ruta/shared_utils.py` — solo si se agrega una función helper nueva

---

## Archivos de lectura (dependencias implícitas)

<!--
Archivos que este ticket LEE pero NO modifica.
Listar aquí permite al orquestador detectar dependencias ocultas:
si Ticket A lee `events.py` y Ticket B lo modifica, A no debería
correr en paralelo con B (aunque sus scope fences de ESCRITURA no se solapen).

Solo listar archivos que otros tickets del sprint podrían modificar.
No listar archivos estables como CLAUDE.md o librerías externas.

Si no hay dependencias de lectura relevantes, escribir "Ninguna".
-->

- `ruta/archivo_que_lee.py` — [qué dato lee de este archivo]
- Ninguna

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `ruta/exacta/archivo.py` | [Qué agregar/cambiar/eliminar] |

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `ruta/exacta/nuevo.py` | [Qué contiene y por qué] |

---

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

---

## Subtareas

<!--
Regla de división (ver references/subagent-sizing.md):
- ≤3 archivos y ≤3 pasos → NO dividir, usar "Implementación directa"
- 4-8 archivos → 2-3 subtareas secuenciales
- 9+ archivos o lógica compleja → 3-5 subtareas
-->

### [Opción A: Implementación directa — sin subdivisión]

**Pasos:**
1. [Paso concreto con archivo y función]
2. [Paso concreto]
3. Correr tests: `[comando exacto]`
4. Lint pre-commit: `ruff check [archivos_tocados] --fix && ruff format [archivos_tocados]`
5. Commit: `"[tipo]: [descripción]"`

### [Opción B: Con subtareas]

#### Subtarea 1 — [Nombre descriptivo]
- **Paralela:** [sí/no — solo aplica si modo = Sesión principal]
- **Archivos:** `archivo1.py`, `archivo2.py`
- **Pasos:**
  1. [Paso concreto]
  2. [Paso concreto]
- **Tests:** `[comando]`
- **Lint:** `ruff check [archivos] --fix && ruff format [archivos]`
- **Commit:** `"[tipo]: [descripción]"`

#### Subtarea 2 — [Nombre descriptivo]
- **Depende de:** [Subtarea 1 | ninguna]
- **Archivos:** [lista]
- **Pasos:**
  1. [Paso concreto]
  2. [Paso concreto]
- **Tests:** `[comando]`
- **Lint:** `ruff check [archivos] --fix && ruff format [archivos]`
- **Commit:** `"[tipo]: [descripción]"`

<!-- Repetir para cada subtarea adicional -->

---

## Tests que deben pasar

```bash
# Comando exacto para correr tests
pytest tests/test_[modulo].py -v
```

- [ ] `test_[nombre]`: [Qué verifica — input esperado y output esperado]
- [ ] `test_[nombre]`: [Qué verifica]
- [ ] `test_[nombre]`: [Qué verifica]

## Criterios de aceptación

- [ ] [Condición observable y verificable]
- [ ] [Condición observable y verificable]
- [ ] [Condición observable y verificable]

## NO hacer

<!--
LÍMITE: Máximo 10 restricciones por spec.
Más de 10 constraints causa omisiones críticas — el modelo pierde
instrucciones cuando hay demasiadas reglas compitiendo por atención.
Si necesitás más de 10, priorizá las más peligrosas y mové el resto
a "contexto del proyecto" en el prompt del subagente.
-->
- NUNCA [restricción 1 — qué evitar y por qué]
- NUNCA [restricción 2]
- NUNCA [restricción 3]

## Decisiones de diseño (opcional)
<!-- Registrar aquí las decisiones significativas tomadas al escribir este spec.
     Solo llenar si hubo alternativas consideradas y descartadas.
     Esta sección NO se valida en preflight — es puramente informativa. -->

### D-1 — [Título de la decisión]
- **Decisión:** [Qué se decidió]
- **Motivo:** [Por qué]
- **Alternativas descartadas:** [Qué se consideró y se rechazó, y por qué]

---

## Checklist de autocontención

<!--
El orquestador lanza un subagente que lee ESTE archivo directamente
de disco. El subagente NO recibe:
  - La conversación de Cowork
  - El contexto de otros tickets
  - Los resultados de subagentes anteriores

Por eso este spec debe ser AUTOCONTENIDO. Verificar:
-->

- [ ] ¿Tiene scope fence (archivos permitidos + prohibidos)?
- [ ] ¿Tiene dependencias de lectura listadas (o "Ninguna" explícito)?
- [ ] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [ ] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [ ] ¿Tiene comando exacto de tests?
- [ ] ¿Tiene commit message definido?
- [ ] ¿Tiene criterios de aceptación observables?
- [ ] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [ ] ¿Tiene ≤10 restricciones totales?
- [ ] ¿No depende de contexto que solo existe en la conversación?

Si falta algo, el subagente va a tener que explorar y gastar contexto.
