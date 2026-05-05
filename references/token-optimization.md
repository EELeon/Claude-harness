# Optimizacion de Tokens — Hallazgos y Configuraciones

Basado en auditoria de 926 sesiones reales de Claude Code.

> **Nota v4.7:** Algunos hallazgos (especialmente #2) son del ecosistema pre-auto-compact.
> Claude Code moderno auto-compacta cuando hace falta y Opus 4.7 auto-gestiona contexto
> mejor. Conservamos el documento como referencia, pero las recomendaciones marcadas
> como **[LEGADO]** ya no aplican.

---

## Hallazgos clave

### 1. Tool schema bloat
- **Problema**: Cargar todos los tool schemas agrega ~14k-20k tokens de overhead por turno.
- **Fix**: Activar `ENABLE_TOOL_SEARCH: true` reduce el overhead a ~5k tokens por turno (reduccion del 65-75%).
- **Donde aplicar**: Variable de entorno o configuracion del harness.

### 2. Cache expiry por pausas [LEGADO]
- **Problema**: El prompt cache de Anthropic tiene un TTL de ~5 minutos. El 54%+ de los turnos despues de una pausa >5 min implican re-procesamiento completo del contexto.
- **Fix original**: Ejecutar `/compact` antes de pausas largas.
- **Estado actual**: Claude Code auto-compacta. NUNCA pedir `/compact` manualmente — contradice la política de compactación actual (ver `compaction-policy.md`). El costo de re-procesamiento post-pausa sigue existiendo pero el usuario no necesita actuar sobre él.

### 3. Skills no usadas
- **Problema**: Skills habilitadas pero no utilizadas consumen espacio en el prompt del sistema.
- **Fix**: Auditar periodicamente las skills activas y deshabilitar las que no se usen en el proyecto actual.
- **Frecuencia recomendada**: Al inicio de cada sprint o al cambiar de contexto de proyecto.

### 4. Lecturas redundantes
- **Problema**: Re-leer archivos que ya estan en el contexto de la conversacion desperdicia tokens.
- **Fix**: Confiar en el contenido ya leido. Re-leer solo si (a) el archivo fue modificado despues de la ultima lectura o (b) hay duda razonable del estado actual (e.g., post /clear, post rollback, despues de un subagente que pudo tocarlo).

---

## Configuraciones recomendadas

| Configuracion | Valor | Donde |
|---------------|-------|-------|
| `ENABLE_TOOL_SEARCH` | `true` | Variable de entorno del harness |
| `/compact` antes de pausas | **[LEGADO]** — ya no aplica. Auto-compact lo maneja | — |
| Skills activas | Solo las necesarias para el sprint actual | `.claude/settings.json` > `permissions.allow` |
| Re-lectura de archivos | Solo si fue modificado o hay duda razonable del estado | Regla del orquestador / CLAUDE.md |

---

## Reglas para el orquestador

1. **Confiar en lo ya leido**: Si un archivo ya fue leido en el contexto actual, usar la version en memoria. Re-leer solo si se modifico o hay duda razonable del estado.
2. **Reportes lean en retornos**: Limitar el output de subagentes a resumen de 1-3 lineas + hash + tests + archivos tocados. Evitar retornos verbosos.
3. **Puntos de corte**: NO hardcodear `/compact` o `/clear` cada N tickets. Auto-compact maneja el contexto; el checkpoint dinamico (Regla 5) decide si hace falta `/clear`.
4. **Preflight de skills**: Antes de un sprint, verificar que solo las skills necesarias estan habilitadas.

---

## Metricas de referencia

| Optimizacion | Antes | Despues | Reduccion |
|--------------|-------|---------|-----------|
| Tool schema (ENABLE_TOOL_SEARCH) | ~14k-20k tokens/turno | ~5k tokens/turno | 65-75% |
| Cache hit rate (con /compact) | ~46% despues de pausa | ~85%+ con contexto reducido | ~40 pts porcentuales |
| Skills activas (auditoria) | 15-20 skills cargadas | 5-8 relevantes | 50-70% menos overhead |
| Lecturas redundantes | 2-3 re-lecturas/ticket | 0 re-lecturas | 100% eliminado |
