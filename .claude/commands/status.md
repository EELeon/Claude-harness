# /status — Estado del sprint actual

Reporta el progreso del sprint actual:

1. Leer `.ai/plan.md`
2. Leer `.ai/runs/results.tsv` para ver qué tickets tienen status keep/discard/crash
3. Leer `.ai/done-tasks.md` para lecciones (si existe)
4. Verificar rama actual con `git branch --show-current`
5. Contar commits del sprint con `git log --oneline main..HEAD`

Mostrar:

```
Sprint: [nombre]
Rama: [nombre]
Progreso: [N] keep / [N] discard / [N] crash de [M] total

Completados (keep):
  - T-[N]: [título] ([commit])

Descartados (discard):
  - T-[N]: [título] — [razón del discard]

Siguiente:
  - T-[N]: [título] — [complejidad]

Pendientes:
  - T-[N]: [título]

Commits: [N] commits en esta rama
```

$ARGUMENTS
