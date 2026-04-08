# Plan de Ejecución — infraestructura-estado-v2

Generado: 2026-04-07
Total tickets: 4
Rama: `feat/infraestructura-estado-v2`
Prerequisito: Sprint P1 (contratos-operativos-v1) completado y archivado

## Orden de ejecución

| # | Ticket | Título | Complejidad | Modo | Subtareas | Depende de | Estado |
|---|--------|--------|-------------|------|-----------|------------|--------|
| 1 | T-5 | Política de compactación 3 niveles | Media | Subagente | 0 | T-1 (P1) | ⬜ |
| 2 | T-6 | Task Locks en disco | Media | Subagente | 0 | T-2 (P1) | ⬜ |
| 3 | T-7 | Experience Library | Media | Subagente | 0 | T-4 (P1) | ⬜ |
| 4 | T-8 | Decision Capture Pipeline MVP | Media | Subagente | 0 | T-1 (P1) | ⬜ |

## Dependencias

- T-5 depende de T-1 (P1) — referencia output-budgets.md para Nivel 1 de compactación
- T-6 depende de T-2 (P1) — referencia concurrency-classes.md para integración de locks por clase
- T-7 depende de T-4 (P1) — referencia recovery-matrix.md como complemento
- T-8 depende de T-1 (P1) — modifica Heat Shield ya actualizado por T-1
- T-5, T-6, T-7, T-8 son independientes entre sí dentro de este sprint

**Nota sobre conflictos de archivos:**
- T-5, T-6, T-7, T-8 todos modifican `templates/orchestrator-prompt.md` en secciones distintas
- T-6 y T-8 ambos modifican `templates/spec-template.md` en secciones distintas
- T-7 y T-8 ambos modifican `.claude/commands/learn.md` en secciones distintas
- Se ejecutan secuencialmente para evitar conflictos de merge

## Tickets fuera del prompt

Ninguno — los 4 son Media y caben como subagentes.

## Notas para el orquestador

- Al iniciar, verificar que los archivos de P1 existen: `references/output-budgets.md`, `references/concurrency-classes.md`, `references/token-optimization.md`, `references/recovery-matrix.md`
- Si alguno falta → P1 no se completó correctamente → no ejecutar este sprint
- Después de T-5 y T-6 (que son más independientes), sugerir `/compact` antes de T-7 y T-8 (que modifican learn.md)

---

## Ejecución — línea para Claude Code

```
Lee .ai/prompts/infraestructura-estado-v2.md y ejecutá todos los tickets.
```

## Fallback: ejecución manual

1. `/status` para ver progreso
2. `/next-ticket` para el siguiente pendiente
3. `/learn ticket-[N] [título]` después de cada ticket
4. `/clear` si el contexto está pesado, retomar con la misma línea

## Rollback de un ticket específico

```bash
git log --oneline --grep="T-[N]"
git revert [hash] --no-edit
```
