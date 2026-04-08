# Reglas de orquestación

Estas reglas gobiernan la ejecución autónoma de los tickets.
Seguílas estrictamente en el orden indicado.

## Regla 1: Cada ticket como subagente
Para cada ticket, lanzá un **subagente general-purpose** con el prompt
indicado en el prompt de ejecución. El subagente lee el spec de disco.
NO implementes tickets directamente en el contexto principal
(excepto correcciones menores post-rollback).

## Regla 2: Verificación y rollback automático
Después de cada subagente:
1. Guardá el hash del commit anterior: `git rev-parse HEAD` (antes del subagente)
2. Verificá que el commit existe: `git log -1 --oneline`
3. **Auditoría de scope** (ver Regla 2b abajo)
4. Corré los tests del ticket (el comando está en el spec)
5. **Si scope OK + tests pasan:** ejecutá Regla 2c (auditoría de completitud).
   Si completitud OK → registrá `keep` en `.ai/runs/results.tsv` y continuá.
6. **Si scope violation (archivos prohibidos tocados):** rollback inmediato:
   `git reset --hard [hash anterior]`, registrá `discard` con
   `failure_category=scope_violation` en `.ai/runs/results.tsv`, continuá
7. **Si los tests fallan:** intentá una corrección rápida (máximo 2 intentos).
   Si no se resuelve, hacé rollback: `git reset --hard [hash anterior]`,
   registrá `discard` con `failure_category=test_failure`, y continuá.

**Commits atómicos:** Cada ticket DEBE terminar con un commit atómico
que incluya el número de ticket en el mensaje (ej: `feat(T-5): ...`).

## Regla 2b: Auditoría de scope por diff
Después de cada subagente, antes de correr tests:
1. Corré `git diff --name-only [hash anterior]..HEAD` para ver archivos tocados
2. Leé la sección "Scope fence" del spec del ticket
3. Si hay archivo en denylist → rollback automático, registrar `scope_violation`
4. Si hay archivo fuera de toda lista → registrar warning pero NO bloquear

## Regla 2c: Auditoría de completitud
Después de que scope y tests pasen:
1. Leé `## Criterios de aceptación` del spec
2. Verificá cada criterio
3. Todos cumplidos → `keep`. ≥80% → `keep` con warning. <80% → `discard` con `incomplete`

## Regla 3: Autonomía total (NEVER STOP)
Continuá ejecutando tickets hasta terminar todos o hasta que el usuario interrumpa.
Las únicas razones válidas para pausar: /compact necesario, punto de corte, o error sistémico.

## Regla 4: Gestión de contexto
Después de cada ticket:
1. Registrá en `.ai/runs/results.tsv`
2. Si llevás 3+ tickets, sugerí `/compact`

**Formato de .ai/runs/results.tsv:**
```
ticket	commit	tests	status	failure_category	description
```

## Regla 5: Punto de corte
Después de T-6 (antes de T-7), ejecutar punto de corte:
1. Verificar que T-5 y T-6 están registrados en results.tsv
2. Sugerir `/compact` si el contexto está pesado
3. Continuar con T-7

## Regla 6: Retomar después de /clear
Si `.ai/runs/results.tsv` ya tiene tickets completados, saltá los completados
y continuá con el siguiente pendiente.

## Patrón Heat Shield
El subagente devuelve SOLO:
- Resumen (1-3 líneas)
- Hash del commit
- Estado de tests (passed/failed)
- Archivos tocados
- Estado de criterios de aceptación (sí/no/parcial)

NO devuelve logs completos ni output de tests.

## Regla 7: Auto-learn por ticket
Después de cada ticket con status `keep`, ejecutá `/learn ticket-[N] [título]`.

## Al terminar todos los tickets

1. Corré la suite completa de tests (para este repo: verificar que todos los .md son válidos)
2. Asegurate de que `.ai/runs/results.tsv` está completo
3. Ejecutá `/learn infraestructura-estado-v2 completo`
4. **Limpieza:**
   ```bash
   mkdir -p .ai/specs/archive/infraestructura-estado-v2
   mv .ai/specs/active/* .ai/specs/archive/infraestructura-estado-v2/
   rm -f .ai/rules.md .ai/plan.md .ai/runs/results.tsv
   git add -A && git commit -m "chore: archivar specs y limpiar infraestructura-estado-v2"
   ```
5. Creá el PR
