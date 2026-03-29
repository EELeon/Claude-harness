# Ticket [N] — [Título descriptivo]

## Objetivo

[1-2 frases. Qué cambia en el sistema después de implementar este ticket.]

## Complejidad: [Simple | Media | Alta]

## Dependencias

- Requiere: [Ticket X completado | Ninguna]
- Bloquea: [Ticket Y | Ninguno]

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
Regla de división:
- ≤3 archivos y ≤3 pasos → NO dividir, poner todo en "Implementación directa"
- 4-8 archivos → 2-3 subtareas
- 9+ archivos o lógica compleja → 3-5 subtareas
-->

### [Opción A: Implementación directa — sin subagentes]

**Pasos:**
1. [Paso concreto con archivo y función]
2. [Paso concreto]
3. Correr tests: `[comando exacto]`
4. Commit: `"[tipo]: [descripción]"`

### [Opción B: Subtareas con subagentes]

#### Subtarea 1 — [Nombre descriptivo]
- **Subagente:** [explorador | impl-dominio | general-purpose]
- **Paralela:** [sí/no — puede correr al mismo tiempo que otra subtarea]
- **Archivos:** `archivo1.py`, `archivo2.py`
- **Prompt para el subagente:**
  ```
  [Prompt completo y autocontenido que el agente padre
  pasará al subagente. Incluir rutas, contexto mínimo
  necesario, pasos, y criterio de terminación.]
  ```
- **Output esperado:** [Qué produce — archivo modificado, reporte, etc.]
- **Commit:** `"[tipo]: [descripción]"`

#### Subtarea 2 — [Nombre descriptivo]
- **Subagente:** [tipo]
- **Paralela:** [sí/no]
- **Depende de:** [Subtarea 1 | ninguna]
- **Archivos:** [lista]
- **Prompt para el subagente:**
  ```
  [Prompt completo]
  ```
- **Output esperado:** [descripción]
- **Commit:** `"[tipo]: [descripción]"`

<!-- Repetir para cada subtarea adicional -->

---

## Tests que deben pasar

```bash
# Comando exacto para correr tests
pytest tests/test_[modulo].py -v
```

- [ ] `test_[nombre]`: [Qué verifica — input → output esperado]
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
