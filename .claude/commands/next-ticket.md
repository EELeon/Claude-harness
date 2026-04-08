# /next-ticket — Iniciar siguiente ticket del sprint

Lee `.ai/plan.md` y determina cuál es el siguiente ticket pendiente.

1. Leer `.ai/plan.md` para identificar el ticket actual
2. Leer `.ai/runs/results.tsv` para confirmar qué ya se completó (status = keep)
3. Leer el spec correspondiente: `.ai/specs/active/ticket-[N].md`
4. Mostrar resumen:
   - Título del ticket
   - Complejidad
   - Número de subtareas
   - Archivos que se tocarán
   - Dependencias ya cumplidas

5. Preguntar: "¿Procedo con la implementación?"

Si el usuario confirma, implementar siguiendo el spec exactamente.
Usar subagentes para las subtareas marcadas.
Commit atómico después de cada subtarea.

Al terminar, recordar: "Ejecuta /learn ticket-[N] [título] para capturar lecciones."

$ARGUMENTS
