# /status — Estado del sprint actual

Reporta el progreso del sprint actual:

1. Leer `EXECUTION_PLAN.md`
2. Leer `done-tasks.md`
3. Verificar rama actual con `git branch --show-current`
4. Contar commits del sprint con `git log --oneline main..HEAD`

Mostrar:

```
Sprint: [nombre]
Rama: [nombre]
Progreso: [N/M] tickets completados

✅ Completados:
  - Ticket N: [título] ([fecha])

🔄 Siguiente:
  - Ticket N: [título] — [complejidad]

⏳ Pendientes:
  - Ticket N: [título]

Commits: [N] commits en esta rama
Contexto: [estimación de uso basada en /context]
```

$ARGUMENTS
