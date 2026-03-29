# Ticket [N] — [Título descriptivo]

## Objetivo

[1-2 frases. Qué cambia en el sistema después de implementar este ticket.]

## Complejidad: [Simple | Media | Alta]

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

## Modo de ejecución: [Subagente | Sesión principal]

<!--
Subagente (default): se ejecuta dentro del prompt orquestador.
  El subagente NO puede lanzar sub-subagentes. Si hay subtareas,
  las ejecuta secuencialmente dentro de su propia ventana de contexto.
Sesión principal: solo para tickets Alta complejidad + 4 subtareas
  de 5+ archivos cada una. Estos tickets SÍ pueden usar subagentes
  para sus subtareas, pero se ejecutan fuera del prompt orquestador.
-->

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

### Archivos condicionales (opcional)
<!-- Archivos que pueden tocarse SOLO si se cumple una condición -->
- `ruta/shared_utils.py` — solo si se necesita agregar un helper nuevo

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
- [ ] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [ ] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [ ] ¿Tiene comando exacto de tests?
- [ ] ¿Tiene commit message definido?
- [ ] ¿Tiene criterios de aceptación observables?
- [ ] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [ ] ¿Tiene ≤10 restricciones totales?
- [ ] ¿No depende de contexto que solo existe en la conversación?

Si falta algo, el subagente va a tener que explorar y gastar contexto.
