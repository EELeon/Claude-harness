# Recovery Matrix — Protocolo de recuperación de errores

## Cómo usar este documento

**Para el orquestador:** Cuando detectes una anomalía durante la ejecución de un ticket (subagente lento, archivos fuera de scope, tests que no terminan, etc.), consultá esta tabla para la acción estándar. NO improvisar recuperaciones — seguir el protocolo documentado.

**Para el usuario:** Cuando una ejecución falla o se comporta de forma inesperada, buscá la situación en la tabla y seguí los pasos de la columna "Detalle". Si ninguna situación coincide, escalá manualmente.

---

## Tabla de situaciones

| # | Situación | Señal de detección | Acción | Detalle |
|---|-----------|-------------------|--------|---------|
| 1 | Contexto pesado (>80%) | Orquestador reporta lentitud o paraphrase loss | `shrink` | Microcompact + /compact |
| 2 | Subagente tangencial | Reporte del subagente muestra archivos fuera de scope | `rollback` | git reset --hard + re-spec |
| 3 | Test suite lenta | Tests tardan >5min sin terminar | `split` | Separar tests lentos, marcar como known-slow |
| 4 | Comando no disponible | Error de herramienta o permiso | `retry` | Fallback documentado por tipo |
| 5 | CI falla post-PR | Pipeline falla después de crear PR | `escalate` | Sesión principal con diagnóstico |
| 6 | Sesión cortada | Claude Code se desconecta | `continue` | Leer .ai/runs/results.tsv + retomar |
| 7 | Spec ambiguo | Subagente reporta "asumí" o "interpreté" | `split ticket` | Dividir + re-spec con usuario |
| 8 | Output demasiado grande | Salida excede límites de result budgeting | `archive artifact` | Truncar + persistir a disco |
| 9 | Batch con colisión | Dos subagentes tocaron mismo archivo | `rollback` | Reclasificar execution_class |
| 10 | Cherry-pick conflict | Cherry-pick retorna conflicto en archivo compartido | `resolve` | Abort, resolver manual preservando HEAD, tests post-merge |
| 11 | Subagente sin commit | Hash pre/post subagente idénticos | `discard` | Registrar no_commit, re-ejecutar subagente |

---

## Detalle por situación

### 1. Contexto pesado (>80%) — `shrink`

**Señales de detección:**
- El orquestador empieza a parafrasear instrucciones que antes citaba textualmente
- Las respuestas se vuelven más lentas o menos precisas
- Se repiten preguntas sobre cosas que ya se discutieron
- Llevás 3+ tickets completados sin /compact

**Pasos exactos:**
1. Verificar que `.ai/runs/results.tsv` está actualizado con todos los tickets completados
2. Ejecutar `/compact` para comprimir el contexto
3. Después de /compact, releer `.ai/runs/results.tsv` para retomar el estado
4. Si /compact no es suficiente (el orquestador sigue lento), pedir `/clear` y retomar con la línea de ejecución original

**Ejemplo concreto:** Después de completar T-1, T-2, y T-3, el orquestador empieza a confundir archivos del scope de T-2 con los de T-4. Señal clara de paraphrase loss. Acción: registrar T-3 en results.tsv, ejecutar /compact, releer results.tsv, y continuar con T-4.

---

### 2. Subagente tangencial — `rollback`

**Señales de detección:**
- Reporte del subagente reporta archivos que no están en la allowlist ni en condicionales del spec
- El diff muestra cambios en archivos de la denylist
- El subagente reporta haber "refactorizado" o "mejorado" cosas no pedidas
- La descripción del cambio no coincide con el objetivo del spec

**Pasos exactos:**
1. Ejecutar `git diff --name-only [hash anterior]..HEAD` para ver archivos tocados
2. Comparar contra el scope fence del spec (Regla 2b del orquestador)
3. Si hay archivos en denylist: `git reset --hard [hash anterior]`
4. Registrar `discard` con `failure_category=scope_violation` en results.tsv
5. Evaluar si el spec necesita clarificación antes de reintentar
6. Si el spec es claro, relanzar el subagente con el mismo spec

**Ejemplo concreto:** T-5 pide crear `utils/helper.py` pero el subagente también modificó `config/settings.py` (que está en denylist). Rollback inmediato, registrar scope_violation, relanzar subagente.

---

### 3. Test suite lenta — `split`

**Señales de detección:**
- Los tests del ticket llevan >5 minutos sin terminar
- El proceso de tests consume recursos excesivos
- Tests de integración bloquean tests unitarios rápidos

**Pasos exactos:**
1. Cancelar la ejecución de tests en curso (Ctrl+C o timeout)
2. Identificar qué tests son lentos (ver output parcial)
3. Separar tests lentos en un archivo o grupo marcado como `known-slow`
4. Correr primero los tests rápidos para validar funcionalidad básica
5. Documentar los tests lentos en la description del results.tsv
6. Si los tests rápidos pasan, marcar como `keep` con warning sobre tests lentos

**Ejemplo concreto:** T-7 tiene tests de integración que hacen llamadas HTTP reales y tardan 8 minutos. Separar esos tests, correr solo los unitarios (pasan en 15 segundos), registrar keep con nota "tests de integración pendientes de revisión".

---

### 4. Comando no disponible — `retry`

**Señales de detección:**
- Error de "tool not available" o "permission denied"
- El subagente reporta que no puede ejecutar un comando del spec
- Herramientas que funcionaban antes dejan de responder

**Pasos exactos:**
1. Identificar qué comando/herramienta falló
2. Buscar fallback según tipo:
   - **Herramienta de búsqueda no disponible:** usar grep/find manual
   - **Subagente no puede crear archivos:** crear desde el contexto principal
   - **Git command falla:** verificar estado del repo con `git status`
   - **Permiso denegado en archivo:** verificar si el archivo está en scope
3. Si el fallback funciona, continuar con la ejecución
4. Si no hay fallback viable, registrar `crash` en results.tsv y continuar con el siguiente ticket

---

### 5. CI falla post-PR — `escalate`

**Señales de detección:**
- `gh pr checks` muestra failures después de crear el PR
- Pipeline de CI/CD reporta errores
- Tests que pasaban localmente fallan en CI

**Pasos exactos:**
1. Ejecutar `gh pr checks` para ver qué checks fallaron
2. Leer los logs del check fallido
3. Clasificar el fallo:
   - **Fallo de lint/formato:** corregir y pushear
   - **Fallo de test:** diagnosticar si es flaky o real
   - **Fallo de build:** verificar dependencias
   - **Fallo de permisos/config:** escalar al usuario
4. Si la corrección es simple (lint, formato), aplicarla directamente
5. Si el fallo requiere cambios sustanciales, abrir sesión principal con diagnóstico completo para el usuario

---

### 6. Sesión cortada — `continue`

**Señales de detección:**
- Claude Code se desconectó o crasheó
- El usuario retoma después de un `/clear`
- Se perdió el contexto de la conversación

**Pasos exactos:**
1. Leer `.ai/runs/results.tsv` para ver qué tickets ya se completaron
2. Verificar el estado del repo con `git log --oneline -10` y `git status`
3. Identificar el último ticket completado exitosamente
4. Verificar si hay cambios sin commitear (posible ticket en progreso interrumpido)
5. Si hay cambios sin commitear: evaluar si son viables o hacer rollback
6. Retomar desde el siguiente ticket pendiente según results.tsv

**Ejemplo concreto:** La sesión se cortó después de T-3. Al retomar, results.tsv muestra T-1 keep, T-2 keep, T-3 keep. Git log confirma los 3 commits. Se retoma con T-4.

---

### 7. Spec ambiguo — `split ticket`

**Señales de detección:**
- El subagente reporta "asumí que..." o "interpreté que..."
- El resultado no coincide con lo que el usuario esperaba
- Múltiples interpretaciones válidas del spec
- El subagente pidió clarificación (pero no puede preguntar al usuario)

**Pasos exactos:**
1. Registrar `discard` con `failure_category=spec_ambiguity` en results.tsv
2. Hacer rollback: `git reset --hard [hash anterior]`
3. Documentar la ambigüedad detectada en la description
4. Notificar al usuario: "El spec de T-[N] tiene ambigüedad en [punto específico]. Necesita re-spec."
5. El usuario debe dividir o clarificar el spec antes de reintentar
6. NO reintentar con el mismo spec ambiguo — siempre re-spec primero

---

### 8. Output demasiado grande — `archive artifact`

**Señales de detección:**
- La salida del subagente excede los límites definidos en `references/output-budgets.md`
- El Reporte del subagente recibe un bloque de texto demasiado grande
- El retorno del subagente amenaza con inflar el contexto del orquestador

**Pasos exactos:**
1. Crear carpeta si no existe: `mkdir -p .ai/artifacts`
2. Persistir el output completo a `.ai/artifacts/ticket-[N]-output.md`
3. Truncar el retorno al orquestador: solo las primeras 10 líneas + ruta del archivo
4. Continuar con la verificación normal (scope, tests, completitud)
5. El archivo completo queda disponible para consulta manual

**Ejemplo concreto:** T-8 genera un reporte de auditoría de 500 líneas. Se persiste a `.ai/artifacts/ticket-8-output.md`, se retorna al orquestador solo "Auditoría completada: 47 archivos verificados, 3 warnings. Detalle completo en .ai/artifacts/ticket-8-output.md".

---

### 9. Batch con colisión — `rollback`

**Señales de detección:**
- Dos subagentes ejecutados en paralelo (via /batch) tocaron el mismo archivo
- Git reporta conflictos de merge
- El diff de un ticket incluye cambios que pertenecen a otro ticket

**Pasos exactos:**
1. Hacer rollback de AMBOS tickets: `git reset --hard [hash anterior al batch]`
2. Registrar ambos como `discard` con `failure_category=scope_violation` en results.tsv
3. Reclasificar los tickets: cambiar `execution_class` de `batch` a `sequential`
4. Re-ejecutar los tickets de forma secuencial (Regla 1 del orquestador)
5. El primero en ejecutarse define el estado del archivo; el segundo lo lee fresco

---

### 10. Cherry-pick conflict — `resolve`

**Señales de detección:**
- `git cherry-pick [hash]` retorna conflicto (exit code ≠ 0)
- Archivos en conflicto son archivos que otros tickets del sprint ya tocaron
- El worktree tiene una versión divergente del archivo (basado en un commit anterior)

**Pasos exactos:**
1. Ejecutar `git cherry-pick --abort` para cancelar el cherry-pick
2. Ejecutar `git cherry-pick --no-commit [hash]` para aplicar sin commit
3. Para CADA archivo en conflicto:
   a. Si el archivo fue tocado por un ticket anterior del sprint →
      resolver preservando HEAD y agregando solo las líneas nuevas del worktree
   b. Si el archivo NO fue tocado por tickets anteriores →
      aceptar la versión del worktree: `git checkout --theirs -- [archivo]`
   c. Si el archivo está fuera del scope del ticket →
      descartar: `git checkout HEAD -- [archivo]`
4. Después de resolver todos los conflictos: `git add -A && git commit`
5. Correr tests ANTES de continuar con el siguiente cherry-pick
6. Si los tests fallan después de la resolución → el merge fue incorrecto:
   `git reset --hard HEAD~1` y repetir desde paso 2 con más cuidado

**Ejemplo concreto:** El ticket B3c migra `close_engagement.py` a beta contract
en un worktree. Pero el worktree se creó desde main, no desde el sprint branch.
Al hacer cherry-pick, hay conflicto porque B3a ya modificó el import section.
Resolución: preservar HEAD (que tiene los imports de B3a) y agregar solo el
código nuevo de B3c. NUNCA usar `--theirs` que borraría los cambios de B3a.

---

### 11. Subagente sin commit — `discard`

**Señales de detección:**
- `git rev-parse HEAD` antes y después del subagente son idénticos
- El subagente reporta "completado" pero no hay commit nuevo
- Hay cambios uncommitted en el working directory

**Pasos exactos:**
1. Registrar `discard` con `failure_category=no_commit` en results.tsv
2. Descartar cualquier cambio uncommitted: `git checkout -- .` y `git clean -fd`
3. Re-ejecutar el subagente con el mismo spec (cuenta como iteración 2)
4. Si falla de nuevo → registrar como `discard` definitivo y continuar

**Ejemplo concreto:** El subagente de F-4 termina sin commit. Git status muestra
archivos modificados. En vez de commitear manualmente (riesgo de scope violation),
descartar y re-ejecutar. Si el spec es correcto, el subagente debería poder
completar en un segundo intento.

---

## Referencia rápida de acciones

| Acción | Qué hace | Cuándo usarla |
|--------|----------|---------------|
| `shrink` | Comprimir contexto | Cuando el orquestador pierde fidelidad |
| `rollback` | Revertir cambios | Cuando el subagente se sale de scope o hay colisión |
| `split` | Separar componentes | Cuando tests son demasiado lentos |
| `retry` | Reintentar con fallback | Cuando un comando/herramienta no está disponible |
| `escalate` | Escalar al usuario | Cuando CI falla y la corrección no es trivial |
| `continue` | Retomar desde disco | Cuando la sesión se cortó |
| `split ticket` | Dividir el ticket | Cuando el spec es ambiguo |
| `archive artifact` | Persistir a disco | Cuando el output excede límites |
| `resolve` | Resolver conflicto manual | Cuando cherry-pick tiene conflictos en archivos compartidos |
