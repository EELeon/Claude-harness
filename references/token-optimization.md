# Optimizacion de Tokens — Hallazgos y Configuraciones

Basado en auditoria de 926 sesiones reales de Claude Code.

---

## Hallazgos clave

### 1. Tool schema bloat
- **Problema**: Cargar todos los tool schemas agrega ~14k-20k tokens de overhead por turno.
- **Fix**: Activar `ENABLE_TOOL_SEARCH: true` reduce el overhead a ~5k tokens por turno (reduccion del 65-75%).
- **Donde aplicar**: Variable de entorno o configuracion del harness.

### 2. Cache expiry por pausas
- **Problema**: El prompt cache de Anthropic tiene un TTL de ~5 minutos. El 54%+ de los turnos despues de una pausa >5 min implican re-procesamiento completo del contexto.
- **Fix**: Ejecutar `/compact` antes de pausas largas para reducir el contexto y minimizar el costo de re-carga.
- **Impacto**: Evita reprocesar miles de tokens que ya no estan en cache.

### 3. Skills no usadas
- **Problema**: Skills habilitadas pero no utilizadas consumen espacio en el prompt del sistema.
- **Fix**: Auditar periodicamente las skills activas y deshabilitar las que no se usen en el proyecto actual.
- **Frecuencia recomendada**: Al inicio de cada sprint o al cambiar de contexto de proyecto.

### 4. Lecturas redundantes
- **Problema**: Re-leer archivos que ya estan en el contexto de la conversacion desperdicia tokens.
- **Fix**: Confiar en el contenido ya leido. Solo re-leer si el archivo fue modificado despues de la ultima lectura.

---

## Configuraciones recomendadas

| Configuracion | Valor | Donde |
|---------------|-------|-------|
| `ENABLE_TOOL_SEARCH` | `true` | Variable de entorno del harness |
| `/compact` antes de pausas | Siempre si pausa >5 min | Comando manual o regla del orquestador |
| Skills activas | Solo las necesarias para el sprint actual | `.claude/settings.json` > `permissions.allow` |
| Re-lectura de archivos | Solo si fue modificado post-lectura | Regla del orquestador / CLAUDE.md |

---

## Reglas para el orquestador

1. **No re-leer archivos**: Si un archivo ya fue leido en el contexto actual, usar la version en memoria. Solo re-leer si se modifico despues.
2. **Reportes lean en retornos**: Limitar el output de subagentes a resumen de 1-3 lineas + hash + tests + archivos tocados. Evitar retornos verbosos.
3. **Puntos de corte**: Ejecutar `/compact` o `/clear` cada 3-4 tickets para evitar degradacion de contexto.
4. **Preflight de skills**: Antes de un sprint, verificar que solo las skills necesarias estan habilitadas.

---

## Metricas de referencia

| Optimizacion | Antes | Despues | Reduccion |
|--------------|-------|---------|-----------|
| Tool schema (ENABLE_TOOL_SEARCH) | ~14k-20k tokens/turno | ~5k tokens/turno | 65-75% |
| Cache hit rate (con /compact) | ~46% despues de pausa | ~85%+ con contexto reducido | ~40 pts porcentuales |
| Skills activas (auditoria) | 15-20 skills cargadas | 5-8 relevantes | 50-70% menos overhead |
| Lecturas redundantes | 2-3 re-lecturas/ticket | 0 re-lecturas | 100% eliminado |
