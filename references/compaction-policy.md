# Politica de compactacion de 3 niveles

## Principio

> El contexto es un recurso finito. Compactar proactivamente evita degradacion de fidelidad y perdida de instrucciones.

El orquestador gestiona contexto en 3 niveles progresivos: microcompact (continuo), snip (entre tickets), y reset resumible (entre bloques de trabajo). Cada nivel tiene un trigger explicito, acciones concretas, y un responsable definido.

---

## Nivel 1 -- Microcompact (automatico, continuo)

**Trigger:** Despues de cada interaccion con subagente (al recibir el resultado Heat Shield).

**Responsable:** El prompt del orquestador (regla embedded en Regla 4).

**Acciones:**
1. Sustituir outputs repetidos por referencias a artifact path (ver `references/output-budgets.md` para limites por tipo de salida)
2. Colapsar resultados de tests identicos en una sola linea: "Tests: N passed (sin cambios desde iteracion anterior)"
3. Reemplazar diffs repetidos por "sin cambios desde iteracion N"
4. Usar SOLO Heat Shield (resumen de 4 lineas maximo + ruta) en vez de output completo

**Ejemplo -- antes:**
```
Subagente T-3 devuelve:
  Resumen: Implementado recovery matrix con 9 situaciones
  Hash: abc1234
  Tests: PASS test_file_exists, PASS test_nine_situations, PASS test_actions
  Archivos: references/recovery-matrix.md, templates/orchestrator-prompt.md

Subagente T-4 devuelve:
  Resumen: Documentada optimizacion de tokens
  Hash: def5678
  Tests: PASS test_file_exists, PASS test_rules_count, PASS test_reference
  Archivos: references/token-optimization.md, .ai/rules.md

[El orquestador todavia tiene en contexto los outputs completos de T-3]
```

**Ejemplo -- despues:**
```
Subagente T-4 devuelve:
  Resumen: Documentada optimizacion de tokens
  Hash: def5678
  Tests: 3 passed (sin cambios de patron desde T-3)
  Archivos: references/token-optimization.md, .ai/rules.md

[Los outputs de T-3 ya estan en results.tsv y en disco -- no se retienen en contexto]
```

---

## Nivel 2 -- Snip (semi-automatico, entre tickets)

**Trigger:** Al completar un ticket (despues de registrar en `.ai/runs/results.tsv`).

**Responsable:** Regla 4 del orquestador.

**Acciones:**
1. Mantener en contexto SOLO la cola protegida:
   - Spec del ticket actual (el que se va a ejecutar, no el que acaba de terminar)
   - Ultimos 2 resultados de `.ai/runs/results.tsv`
   - Reglas activas (`.ai/rules.md`)
   - `CLAUDE.md`
2. Todo output de tickets anteriores ya esta persistido a disco por Heat Shield y Result Budgeting
3. Sugerir `/compact` si el contexto acumulado supera ~3 tickets completados

**Ejemplo -- antes:**
```
[En contexto del orquestador despues de T-3, T-4, T-5:]
- Spec de T-3 (ya completado)
- Resultado Heat Shield de T-3
- Spec de T-4 (ya completado)
- Resultado Heat Shield de T-4
- Spec de T-5 (ya completado)
- Resultado Heat Shield de T-5
- Reglas, CLAUDE.md, plan
Total: ~15K tokens de contexto acumulado
```

**Ejemplo -- despues (Snip aplicado antes de T-6):**
```
[Cola protegida:]
- Spec de T-6 (siguiente a ejecutar)
- Resultados de T-4 y T-5 en results.tsv (ultimos 2)
- .ai/rules.md
- CLAUDE.md
Total: ~5K tokens
[Mensaje al usuario: "Recomiendo correr /compact antes de continuar con T-6.
Tu progreso esta guardado en .ai/runs/results.tsv."]
```

---

## Nivel 3 -- Reset resumible (manual, entre bloques de trabajo)

**Trigger:** Punto de corte marcado en el plan, o contexto estimado >80% de capacidad.

**Responsable:** El usuario (con guia del orquestador).

**Acciones:**
1. Escribir snapshot minimo a disco antes del reset:
   - Verificar que `.ai/runs/results.tsv` esta actualizado con todos los tickets completados
   - Verificar que `.ai/plan.md` refleja el progreso actual
2. Ejecutar `/clear`
3. Al retomar, el orquestador reconstruye estado desde disco

**Instrucciones exactas de retoma despues de /clear:**

El orquestador muestra al usuario:
```
Llegamos al punto de corte. Recomiendo:
1. Ejecuta /clear
2. Despues pega esta linea:
   Lee .ai/prompts/[nombre-batch].md y ejecuta todos los tickets.
3. Voy a retomar automaticamente desde el ticket [N] leyendo .ai/runs/results.tsv.
```

Al retomar, el orquestador ejecuta esta secuencia:
```
1. Leer .ai/runs/results.tsv → identificar tickets completados
2. Leer .ai/plan.md → identificar siguiente ticket pendiente
3. Leer .ai/rules.md → cargar reglas de orquestacion
4. Leer CLAUDE.md → cargar contexto del proyecto
5. Continuar con el primer ticket NO registrado en results.tsv
```

**Ejemplo -- antes:**
```
[Contexto despues de 6 tickets, punto de corte alcanzado:]
- Contexto pesado (~150K tokens estimados)
- Fidelidad de instrucciones degradada
- Riesgo de paraphrase loss en proxima compactacion
```

**Ejemplo -- despues:**
```
[Despues de /clear + retoma:]
- Contexto fresco (~3K tokens)
- Lee results.tsv: T-1 keep, T-2 keep, T-3 keep, T-4 keep, T-5 keep, T-6 keep
- Salta a T-7 automaticamente
- Fidelidad de instrucciones al 100%
```

---

## Resumen de niveles

| Nivel | Nombre | Trigger | Automatico? | Responsable | Impacto en contexto |
|-------|--------|---------|-------------|-------------|-------------------|
| 1 | Microcompact | Despues de cada subagente | Si | Prompt del orquestador | Reduce ~30% de outputs repetidos |
| 2 | Snip | Entre tickets (3+ completados) | Semi (sugiere /compact) | Regla 4 | Reduce a cola protegida (~5K tokens) |
| 3 | Reset | Punto de corte o >80% contexto | No (manual) | Usuario + guia | Contexto fresco (0 tokens previos) |

---

## Relacion con otros documentos

- `references/output-budgets.md` -- Define los limites de chars por tipo de salida. Nivel 1 lo usa para decidir cuando persistir a disco vs retener en contexto.
- `templates/orchestrator-prompt.md` -- Regla 4 implementa Nivel 1 y 2. Regla 5 implementa Nivel 3.
- `.ai/rules.md` -- Version instanciada de las reglas para el sprint actual.

---

## Reglas imperativas

- NUNCA retener output completo de un subagente si ya fue persistido a disco
- NUNCA depender de "lo que recuerdo de tickets anteriores" -- leer de disco
- SIEMPRE mantener la cola protegida (spec actual + ultimos 2 results + rules + CLAUDE.md) despues de Nivel 2
- SIEMPRE escribir snapshot a disco antes de ejecutar /clear (Nivel 3)
- NUNCA contar tokens exactos para decidir cuando compactar -- usar heuristicas simples (numero de tickets completados, repeticion de outputs)
- SIEMPRE sugerir /compact despues de 3+ tickets completados (Nivel 2)
