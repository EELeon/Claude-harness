# Pipeline de Captura de Decisiones — Referencia Operativa

## Problema

El harness captura **qué** se hizo (specs, results.tsv, done-tasks.md) pero no **por qué** se tomaron las decisiones. El razonamiento vive en tres lugares efímeros que se pierden:

1. **Transcript de Cowork** — decisiones durante escritura de specs. Muere al cerrar sesión.
2. **Contexto del subagente** — decisiones tácticas durante implementación. Solo sobrevive el Heat Shield.
3. **Conversación de auditoría** — hallazgos que quedan en chat, no en el repo.

## Formato de una entrada de decisión

```
### [D-N] — [Título]
- **Fase:** spec | implementación | auditoría
- **Decisión:** [Qué se decidió — 1 línea]
- **Motivo:** [Por qué]
- **Alternativas descartadas:** [Lo más valioso — qué se consideró y rechazó]
- **Tickets relacionados:** [T-N]
```

El ID es secuencial dentro del batch: `D-1`, `D-2`, etc.
El campo "Alternativas descartadas" es el más valioso — es lo que más se pierde.

## Ubicación de archivos

- **Archivo por batch:** `.ai/decisions/[nombre-batch].decisions.md`
- Se archiva junto con los specs al terminar el batch
- Sigue el mismo ciclo de vida que `.ai/specs/archive/[batch]/`

## Referencia completa

Para fases futuras (reconciliación, auditoría, consolidación), ver el spec de diseño completo: `SPEC-decision-capture-pipeline.md`
