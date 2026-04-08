# Task Locks en disco — Protocolo de concurrencia para batch y auditoría

## Propósito

Sistema liviano de locks basado en archivos JSON para evitar que múltiples subagentes o procesos de auditoría colisionen al trabajar sobre los mismos artifacts. Prerequisito para escalar batch paralelo y recursive audit de forma segura.

## Ubicación

Todos los locks viven en `.ai/locks/[task_id].lock.json` — flat, sin subdirectorios.

## Estructura de un lock

```json
{
  "task_id": "T-3",
  "owner": "subagent-batch-2",
  "acquired_at": "2026-04-07T12:30:00Z",
  "lease_expires_at": "2026-04-07T12:45:00Z",
  "status": "in_progress",
  "files_locked": ["src/auth/login.ts", "tests/auth.test.ts"]
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `task_id` | string | Identificador del ticket (ej: T-3) |
| `owner` | string | Identificador del agente que posee el lock |
| `acquired_at` | ISO 8601 | Timestamp de adquisición |
| `lease_expires_at` | ISO 8601 | Timestamp de expiración del lease |
| `status` | string | `in_progress` mientras el agente trabaja |
| `files_locked` | string[] | Lista de archivos que este ticket protege |

## Reglas de lease

- NUNCA tomar una tarea si existe un lock válido (no expirado)
- Lease default por complejidad:
  - Simple = 10 minutos
  - Media = 15 minutos
  - Alta = 30 minutos
- Renovar lease: escribir nueva timestamp en `lease_expires_at` antes de que expire
- Si un lock expira, cualquier otro agente puede reclamar la tarea (borrar el lock viejo y crear uno nuevo)
- Al completar: borrar el lock inmediatamente
- Al fallar (rollback): borrar el lock y registrar en `results.tsv`
- NUNCA bloquear la ejecución si no se puede adquirir un lock — registrar warning y saltar al siguiente ticket

## Flujo de adquisición

```
1. Verificar si existe .ai/locks/[task_id].lock.json
2. Si existe y NO expiró → esperar o saltar al siguiente ticket
3. Si NO existe o expiró → crear lock con lease
4. Implementar ticket
5. Borrar lock
```

Diagrama de decisión:

```
¿Existe .ai/locks/T-N.lock.json?
  ├── NO → Crear lock → Ejecutar ticket → Borrar lock
  └── SÍ → ¿Expiró el lease?
              ├── SÍ → Borrar lock viejo → Crear lock nuevo → Ejecutar → Borrar
              └── NO → Warning "lock activo" → Saltar al siguiente ticket
```

## Integración con execution_class

La clase de ejecución (definida en `references/concurrency-classes.md`) determina qué tipo de lock necesita cada ticket:

| Clase | Tipo de lock | Razón |
|-------|-------------|-------|
| `read_only` | No requiere lock | No modifica archivos del repo |
| `isolated_write` | Lock solo sobre sus archivos específicos | Protege los archivos listados en `files_locked` |
| `shared_write` | Lock mutex global (solo un agente a la vez) | Comparte archivos con otros tickets, requiere exclusión total |
| `repo_wide` | No usa locks (corre en sesión principal exclusiva) | Ya tiene exclusividad por diseño |

## Limpieza

- `.ai/locks/` es una carpeta de artifacts temporales de runtime
- Se borra al final de cada sprint (en la limpieza post-ejecución)
- Los locks NUNCA se commitean al repo
- Si quedan locks huérfanos después de un crash, se pueden borrar manualmente sin riesgo

## Reglas imperativas

- NUNCA commitear archivos de `.ai/locks/` al repo
- NUNCA crear subdirectorios dentro de `.ai/locks/`
- NUNCA implementar locks como código ejecutable — son archivos JSON que los agentes leen/escriben
- NUNCA hacer que los locks sean obligatorios para ejecución secuencial — solo aplican a batch y audit paralelo
- SIEMPRE borrar el lock al terminar o fallar un ticket
- SIEMPRE respetar leases activos de otros agentes
