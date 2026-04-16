# [sprint-prefix]-[seq] — [Título descriptivo]

<!-- Naming: references/spec-naming.md | Archivo: [sprint-prefix]-[seq]-[slug].md -->

---
id: "[sprint-prefix]-[seq]"
title: "[Título descriptivo]"
goal: "[1-2 frases — mismo contenido que ## Objetivo]"
complexity: Simple | Media | Alta
execution_mode: Subagente | Sesion_principal
execution_class: auto
allowed_paths:
  - "ruta/exacta/archivo.py"
denied_paths:
  - "ruta/config_produccion.py"
dependencies:
  requires: []
  blocks: []
closure_criteria:
  - "Criterio observable y verificable"
required_validations:
  - "comando o check específico"
max_attempts: 3
retry_only_if:
  - "tests fallan por causa identificable"
  - "scope violation en archivo no-denylist"
escalate_if:
  - "el mismo test falla 2 veces con fix diferente"
  - "subagente reporta ambigüedad en el spec"
blocked_if:
  - "dependencia no resuelta"
discard_if:
  - "max_attempts alcanzado sin tests passing"
  - "scope violation en archivo denylist"
---

## Objetivo

[1-2 frases. Qué cambia en el sistema después de implementar este ticket.]

## Dependencias

- Requiere: [Ticket X | Ninguna]
- Bloquea: [Ticket Y | Ninguno]

<!-- Si depende de ticket no implementado: definir contrato explícito (interfaz/stub) para desarrollo paralelo. -->

## Scope fence

### Archivos permitidos
- `ruta/exacta/archivo.py`
- `tests/test_modulo.py`

### Archivos prohibidos
- `ruta/config_produccion.py` — [razón]
- `.ai/*` — propiedad del orquestador

### Archivos condicionales (opcional)
<!-- Condición debe ser verificable en diff. ❌ "si es necesario" ✅ "si se agrega función nueva" -->
- `ruta/shared_utils.py` — solo si se agrega función helper nueva

## Archivos de lectura (dependencias implícitas)
<!-- Archivos que este ticket LEE pero NO modifica. Solo listar si otros tickets del sprint podrían modificarlos. -->
- Ninguna

## Archivos a modificar/crear

| Archivo | Cambio |
|---------|--------|
| `ruta/archivo.py` | [Qué agregar/cambiar] |
| `ruta/nuevo.py` | [Crear: qué contiene] |

## Subtareas

<!-- ≤3 archivos y ≤3 pasos → sin subdivisión. 4-8 archivos → 2-3 subtareas. 9+ → 3-5 subtareas. -->

**Pasos:**
1. [Paso concreto con archivo y función]
2. [Paso concreto]
3. Tests: `[comando exacto]`
4. Lint: `ruff check [archivos] --fix && ruff format [archivos]`
5. Commit: `"[tipo]: [descripción]"`

## Tests que deben pasar

```bash
pytest tests/test_[modulo].py -v
```

- [ ] `test_[nombre]`: [Qué verifica]

## Criterios de aceptación

- [ ] [Condición observable y verificable]
