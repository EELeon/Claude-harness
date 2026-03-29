# Ticket [N] — [Título descriptivo]

## Objetivo

[1-2 frases. Qué cambia en el sistema después de implementar este ticket.]

## Complejidad: [Simple | Media | Alta]

## Dependencias

- Requiere: [Ticket X completado | Ninguna]
- Bloquea: [Ticket Y | Ninguno]

## Modo de ejecución: [Subagente | Sesión principal]

<!--
Subagente (default): se ejecuta dentro del mega-prompt orquestador.
  El subagente NO puede lanzar sub-subagentes. Si hay subtareas,
  las ejecuta secuencialmente dentro de su propia ventana de contexto.
Sesión principal: solo para tickets Alta complejidad + 4 subtareas
  de 5+ archivos cada una. Estos tickets SÍ pueden usar subagentes
  para sus subtareas, pero se ejecutan fuera del mega-prompt.
-->

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
4. Commit: `"[tipo]: [descripción]"`

### [Opción B: Con subtareas]

#### Subtarea 1 — [Nombre descriptivo]
- **Paralela:** [sí/no — solo aplica si modo = Sesión principal]
- **Archivos:** `archivo1.py`, `archivo2.py`
- **Pasos:**
  1. [Paso concreto]
  2. [Paso concreto]
- **Tests:** `[comando]`
- **Commit:** `"[tipo]: [descripción]"`

#### Subtarea 2 — [Nombre descriptivo]
- **Depende de:** [Subtarea 1 | ninguna]
- **Archivos:** [lista]
- **Pasos:**
  1. [Paso concreto]
  2. [Paso concreto]
- **Tests:** `[comando]`
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

- No [restricción 1 — qué evitar y por qué]
- No [restricción 2]
- No [restricción 3]

---

## Prompt para el mega-prompt orquestador

<!--
SECCIÓN CLAVE: Este bloque es lo que el skill copia al mega-prompt
del sprint. Debe ser AUTOCONTENIDO — el subagente no recibe:
  - La conversación de Cowork
  - El contexto de otros tickets
  - Los resultados de subagentes anteriores

Incluir todo lo necesario para que el subagente ejecute sin explorar.
-->

```
Lee e implementa el spec en `specs/ticket-[N].md`.

Contexto del proyecto: [1-2 líneas del CLAUDE.md que el subagente necesita
saber — reglas de dominio, convenciones de naming, ubicación de tests]

Archivos a modificar:
- `ruta/archivo1.py` — [qué contiene actualmente y qué cambiar]
- `ruta/archivo2.py` — [ídem]

Archivos a crear:
- `ruta/nuevo.py` — [qué debe contener y su propósito]

Pasos:
1. [Paso concreto — copiado/condensado de las subtareas de arriba]
2. [Paso concreto]
3. [...]

Tests: `pytest tests/test_[modulo].py -v`
Todos los tests listados en el spec deben pasar antes de commitear.

Commit con mensaje: "[tipo]: [descripción]"

NO hagas:
- [Restricción 1 del ticket]
- [Restricción 2 del ticket]
```
