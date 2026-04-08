# Prompt Evolution — Protocolo de consolidación de CLAUDE.md

## Objetivo

Separar reglas operacionales (correcciones recientes) de principios de comportamiento (patrones validados), y definir cuándo y cómo fusionar, podar, y promover reglas para mantener CLAUDE.md lean y efectivo.

---

## Dos categorías de reglas

### [OP] — Regla operacional
- Corrección inmediata derivada de un error reciente
- Tiene fecha de creación y contador de activaciones
- Formato en CLAUDE.md: `[OP YYYY-MM-DD] NUNCA hacer X — porque Y`
- Candidata a promoción o eliminación después de 3 sprints

### [BP] — Principio de comportamiento
- Estrategia validada por múltiples sprints (2+ activaciones exitosas)
- Permanente salvo que la experience library demuestre utilidad <50%
- Formato en CLAUDE.md: `[BP] SIEMPRE hacer X — porque Y`

### Sin marcador
- Regla original del proyecto (pre-evolución)
- Tratar como [BP] a todos los efectos

---

## Ciclo de vida de una regla

```
Error detectado
  → /learn crea regla [OP YYYY-MM-DD] con 1 activación
  → Siguiente sprint: si se activa de nuevo → incrementar contador
  → 2+ activaciones exitosas → promover a [BP] (quitar fecha, mantener principio)
  → 3 sprints sin activarse → candidata a eliminación
  → Experience library muestra utilidad <50% → eliminar
```

---

## Protocolo de consolidación

### Mini-consolidación (al final de cada sprint completo)

Trigger: `/learn [batch] completo` o `/learn` del último ticket del sprint.

Acciones:
1. Fusionar reglas [OP] redundantes (mismo error, diferente redacción)
2. Promover [OP] con 2+ activaciones a [BP]
3. Eliminar [OP] con 0 activaciones en 3+ sprints consecutivos

### Consolidación profunda (cada 3 sprints o CLAUDE.md > 90 líneas)

Trigger: cada 3 sprints completados, o cuando CLAUDE.md supere 90 líneas.

Acciones (incluye todo lo de mini-consolidación, más):
1. Cross-reference con `.ai/experience/`: eliminar reglas con utilidad <50%
2. Verificar que cada regla pasa el test de sustracción causal
3. Simplificar redacción sin perder protección
4. Target: volver a 80 líneas o menos

---

## Criterios de promoción [OP] a [BP]

Una regla [OP] se promueve a [BP] cuando cumple TODOS estos criterios:

1. **Activaciones:** 2+ activaciones exitosas en sprints diferentes
2. **No obvio:** La regla previene un error que no es obvio por pre-training
3. **Sin conflicto:** La regla no contradice ningún [BP] existente

Al promover:
- Quitar la fecha y el marcador [OP]
- Reemplazar con [BP]
- Mantener el principio en forma imperativa (SIEMPRE/NUNCA)

---

## Criterios de eliminación

Una regla se elimina cuando cumple AL MENOS UNO de estos criterios:

1. **Inactividad:** 0 activaciones en 3+ sprints consecutivos
2. **Baja utilidad:** Experience library muestra utilidad <30% después de 5+ aplicaciones
3. **Obsoleta:** Referencia archivos, APIs, o dependencias que ya no existen
4. **Redundante:** Duplica otra regla de mayor utilidad o cobertura

---

## Integración con Experience Library

La consolidación consulta `.ai/experience/` para validar utilidad:

- **Antes de promover [OP] a [BP]:** verificar que la experience library tiene el insight correspondiente con utilidad >= 50%
- **Antes de eliminar una regla:** verificar que la experience library NO muestra alta utilidad (>= 70%) para el insight correspondiente
- **Durante consolidación profunda:** cross-reference completo entre reglas en CLAUDE.md e insights en `.ai/experience/`

---

## Ejemplo de evolución

```
Sprint 1: /learn detecta error → agrega [OP 2026-04-07] NUNCA usar rm -rf sin path absoluto
Sprint 2: el error se repite → contador sube a 2
Sprint 3: /learn consolida → promueve a [BP] NUNCA usar rm -rf sin path absoluto
Sprint 6: consolidación profunda → experience library muestra 5/5 utilidad → mantener
```

```
Sprint 1: /learn detecta error → agrega [OP 2026-04-01] SIEMPRE validar JSON antes de parsear
Sprint 2: no se activa
Sprint 3: no se activa
Sprint 4: mini-consolidación → 0 activaciones en 3 sprints → eliminar
```
