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

## Nivel 2 -- Auto-compact (automatico, gestionado por Claude Code)

**Trigger:** Claude Code compacta automaticamente cuando el contexto se acerca al limite.

**Responsable:** Claude Code (no el orquestador).

**Que sobrevive al auto-compact:**
- Instrucciones en CLAUDE.md (por eso SIEMPRE incluir instrucciones de compactacion ahi)
- Interacciones recientes
- Decisiones clave

**Acciones del orquestador (para facilitar auto-compact limpio):**
1. Usar SOLO Heat Shield para resultados de subagentes (no retener outputs completos)
2. Persistir todo a disco (results.tsv, plan.md) — no depender del contexto
3. Incluir instrucciones de compactacion en CLAUDE.md del proyecto (ver claudemd-template.md)
4. NUNCA pedir /compact manualmente — Claude Code lo maneja

**Ejemplo -- auto-compact transparente:**
```
[Despues de T-5, Claude Code auto-compacta:]
- Preserva: CLAUDE.md, interacciones recientes (T-4, T-5), reglas
- Descarta: outputs detallados de T-1, T-2, T-3
- El orquestador NO se entera — simplemente continua con T-6
- Si necesita datos de T-1-T-3, los lee de .ai/runs/results.tsv
```

---

## Nivel 3 -- Reset resumible (solo si hay degradacion real)

**Trigger:** Checkpoint dinamico (Regla 5) detecta degradacion de fidelidad:
el orquestador relee archivos que ya leyo, pierde track del orden de tickets,
o confunde resultados. Esto es raro si Heat Shield y auto-compact funcionan bien.

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
El contexto esta alto. Recomiendo:
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
| 2 | Auto-compact | Contexto cerca del limite | Si (Claude Code) | Claude Code | Preserva CLAUDE.md + interacciones recientes |
| 3 | Reset | Checkpoint detecta degradacion real | No (manual) | Usuario + guia | Contexto fresco (0 tokens previos) |

---

## Relacion con otros documentos

- `references/output-budgets.md` -- Define los limites de chars por tipo de salida. Nivel 1 lo usa para decidir cuando persistir a disco vs retener en contexto.
- `templates/orchestrator-prompt.md` -- Regla 4 implementa Nivel 1. Nivel 2 es automatico (Claude Code). Regla 5 (checkpoint) implementa Nivel 3.
- `.ai/rules.md` -- Version instanciada de las reglas para el sprint actual.

---

## Reglas imperativas

- NUNCA retener output completo de un subagente si ya fue persistido a disco
- NUNCA depender de "lo que recuerdo de tickets anteriores" -- leer de disco
- SIEMPRE mantener la cola protegida (spec actual + ultimos 2 results + rules + CLAUDE.md) despues de Nivel 2
- SIEMPRE escribir snapshot a disco antes de ejecutar /clear (Nivel 3)
- NUNCA contar tokens exactos para decidir cuando compactar -- usar heuristicas simples (numero de tickets completados, repeticion de outputs)
- SIEMPRE ejecutar checkpoint dinamico (Regla 5) despues de cada ticket completado
- NUNCA insertar puntos de corte hardcoded en el plan — el checkpoint decide
- NUNCA pedir /compact manualmente — Claude Code auto-compacta
- SIEMPRE incluir instrucciones de compactacion en CLAUDE.md del proyecto
