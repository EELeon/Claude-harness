# Template para .ai/plan.md

# Plan de Ejecución — [Nombre del batch]

Generado: [fecha] | Total: [N] tickets | Rama: `[nombre-rama]` | Perfil: `[conservative|standard|aggressive]`

## Orden de ejecución

| # | Ticket | Título | Complejidad | Modo | Estado |
|---|--------|--------|-------------|------|--------|
| B | T-3, T-5, T-7 | [títulos] | S, S, M | /batch | ⬜ |
| — | **PUNTO DE CORTE** | /compact o /clear | — | — | — |
| 4 | T-[N] | [título] | [S/M/A] | Subagente | ⬜ |

<!-- Estados: ⬜ pendiente | 🔄 en progreso | ✅ completado | ❌ bloqueado
     Modos: /batch (paralelo, Solo S/M sin dependencias), Subagente (default), Sesión principal (Alta + 4 subtareas de 5+ archivos) -->

## Dependencias
- T-[X] antes de T-[Y] — [razón]

## Ejecución

```
Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.
```

Tickets fuera del prompt (excepcionalmente complejos):
```
Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.
```

## Fallback: ejecución manual
1. `/status` → ver qué se completó
2. `/next-ticket` → ejecutar siguiente pendiente
3. `/learn ticket-[N] [título]` → capturar lecciones
4. `/clear` → continuar con `/next-ticket`

## Rollback de ticket específico
```bash
git log --oneline --grep="T-[N]"
git revert [hash] --no-edit
```

## Infraestructura

| Comando | Propósito |
|---------|-----------|
| `/learn` | Captura lecciones en `.ai/done-tasks.md` |
| `/next-ticket` | Siguiente ticket pendiente |
| `/status` | Progreso actual |
| `/preflight` | Validación pre-ejecución |

### Estructura .ai/
```
.ai/
├── specs/active/     # Specs del batch actual
├── specs/archive/    # Batches pasados
├── runs/results.tsv  # Tracking (temporal)
├── prompts/          # Un archivo por batch (permanente)
├── rules.md          # Reglas de orquestación (temporal)
├── plan.md           # Este archivo (temporal)
└── done-tasks.md     # Lecciones acumulativas (NO borrar)
```

## Integraciones opcionales
| Integración | Regla | Cuándo |
|-------------|-------|--------|
| `/simplify` | R8 | Post-ticket Media/Alta |
| `/batch` | R9 | 3+ tickets batch-eligible |
| `/loop` | Post-PR | Si usuario acepta monitoreo |
