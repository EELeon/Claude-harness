# hardening-12 — Trigger cuantitativo de compact

## Objetivo

Agregar heurística cuantitativa al checkpoint dinámico (Regla 5) en `templates/orchestrator-prompt.md`: después de cada 8 tickets completados sin reset, el orquestador DEBE evaluar activamente si hay degradación. También actualizar `references/compaction-policy.md` con la heurística.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna (no depende de numeración de reglas nuevas — modifica Regla 5 existente)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`
- `references/compaction-policy.md`

### Archivos prohibidos
- `.ai/rules-v3.md` — instancia vieja

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar heurística cuantitativa a Regla 5 |
| `references/compaction-policy.md` | Agregar trigger cuantitativo a Nivel 3 |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md` y localizar Regla 5 ("Checkpoint dinámico").

2. En "**Paso 1 — Detectar degradación:**", agregar un tercer bullet:

```
- ¿Llevo 8+ tickets completados desde el último /clear o inicio de sesión?
  Si sí → evaluar activamente los otros dos indicadores. Con 8+ tickets,
  la probabilidad de degradación es alta aunque no sea obvia.
```

3. En "**Paso 2 — Decidir acción:**", modificar el primer bullet:

**Antes:**
```
- **Sin señales de degradación** → Continuar al siguiente ticket.
  Claude Code auto-compacta cuando se acerca al límite — no intervenir.
```

**Después:**
```
- **Sin señales de degradación Y menos de 8 tickets desde último reset** →
  Continuar al siguiente ticket.
  Claude Code auto-compacta cuando se acerca al límite — no intervenir.
- **8+ tickets sin reset pero sin señales obvias** →
  Hacer un "smoke test" rápido: releer el spec del próximo ticket y verificar
  que las reglas de scope fence siguen claras. Si algo se siente vago
  o necesitás releer rules.md, eso ES degradación — proceder con reset.
```

4. Leer `references/compaction-policy.md`. En "## Nivel 3 -- Reset resumible", modificar el trigger:

**Antes:**
```
**Trigger:** Checkpoint dinamico (Regla 5) detecta degradacion de fidelidad:
el orquestador relee archivos que ya leyo, pierde track del orden de tickets,
o confunde resultados. Esto es raro si Heat Shield y auto-compact funcionan bien.
```

**Después:**
```
**Trigger:** Cualquiera de estas condiciones:
1. Checkpoint dinamico (Regla 5) detecta degradacion de fidelidad:
   el orquestador relee archivos que ya leyo, pierde track del orden de tickets,
   o confunde resultados.
2. Se completaron 8+ tickets desde el ultimo /clear o inicio de sesion,
   Y el "smoke test" de Regla 5 indica vaguedad al leer el proximo spec.

Nota: la condicion 2 es una heuristica conservadora. En sprints observados,
las sesiones que excedieron 8 tickets sin reset consistentemente perdieron
contexto (evidencia: C3 con 31 tickets agoto contexto, C4 con 24 tickets
necesito 2 continuaciones).
```

5. Commit: `"feat(hardening-12): trigger cuantitativo de compact — heurística de 8 tickets"`

---

## Tests que deben pasar

```bash
grep "8.*tickets" templates/orchestrator-prompt.md
# Debe retornar al menos 2 líneas (paso 1 y paso 2)

grep "smoke test" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "8.*tickets" references/compaction-policy.md
# Debe retornar al menos 1 línea
```

- [ ] `grep_8_tickets_prompt`: Regla 5 menciona el umbral de 8 tickets
- [ ] `grep_smoke_test`: Hay un "smoke test" definido para el umbral
- [ ] `grep_8_tickets_policy`: La compaction policy incluye el trigger cuantitativo

## Criterios de aceptación

- [ ] Regla 5 tiene heurística de 8 tickets como indicador de degradación
- [ ] Hay un "smoke test" definido (releer spec del próximo ticket)
- [ ] `references/compaction-policy.md` tiene el trigger cuantitativo en Nivel 3
- [ ] La heurística incluye evidencia de sprints observados

## NO hacer

- NUNCA hacer el umbral de 8 tickets un hard-stop automático — es un trigger de evaluación
- NUNCA pedir /compact manualmente — solo sugerir /clear si hay degradación real
- NUNCA cambiar los Niveles 1 y 2 de la compaction policy
