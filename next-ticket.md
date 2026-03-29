# /next-ticket — Iniciar siguiente ticket del sprint

Lee EXECUTION_PLAN.md y determina cuál es el siguiente ticket pendiente.

1. Leer `EXECUTION_PLAN.md` para identificar el ticket actual
2. Leer `done-tasks.md` para confirmar qué ya se completó
3. Leer el spec correspondiente: `specs/ticket-[N].md`
4. Mostrar resumen:
   - Título del ticket
   - Complejidad
   - Número de subtareas
   - Archivos que se tocarán
   - Dependencias ya cumplidas

5. Preguntar: "¿Procedo con la implementación?"

Si Edwin confirma, implementar siguiendo el spec exactamente.
Usar subagentes para las subtareas marcadas.
Commit atómico después de cada subtarea.

Al terminar, recordar: "Ejecuta /learn ticket-[N] [título] para capturar lecciones."

$ARGUMENTS
