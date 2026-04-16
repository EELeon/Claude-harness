# Flujo principal del orquestador

Todas las rutas son relativas a este skill.

## Paso 0 — Meta del proyecto (condicional)

Si el usuario quiere usar auditoría recursiva o menciona "meta":

**Si no existe `.ai/meta.md`:**
1. Preguntar al usuario (AskUserQuestion): "¿Cuál es la visión general del sistema?
   Describilo en 2-3 párrafos."
2. Con la respuesta, generar un borrador de `.ai/meta.md` siguiendo
   `templates/meta-template.md`: identificar dominios, extraer capacidades,
   definir criterios verificables
3. Presentar el borrador al usuario para revisión
4. Iterar hasta que el usuario apruebe
5. Validar con lógica de `commands/validate-meta.md`
6. Guardar `.ai/meta.md` en el repo

**Si ya existe `.ai/meta.md`:**
1. Validar con lógica de `commands/validate-meta.md`
2. Si FAIL → mostrar errores, corregir con el usuario
3. Si PASS → continuar

**Este paso es condicional** — solo se ejecuta si el usuario quiere auditoría
recursiva. Para sprints normales de tickets, saltar directamente al Paso 1.

## Paso 1 — Inventario y análisis

Leer todos los tickets. Para cada uno, extraer:

| Campo | Qué buscar |
|-------|-----------|
| **Archivos** | Archivos mencionados explícitamente + inferidos del contexto |
| **Complejidad** | Simple (1-3 archivos), Media (4-8), Alta (9+) |
| **Dependencias** | ¿Qué tickets deben completarse antes? |
| **Dominio** | ¿Qué área del proyecto afecta? (frontend, backend, infra, dominio específico, etc.) |
| **Tests** | Tests mencionados en el ticket |
| **Modo de ejecución** | Subagente (default) o Sesión principal (si es excepcionalmente complejo) |

Presentar tabla-resumen al usuario antes de continuar.

## Paso 1.5 — Triage de tamaño (gate obligatorio)

ANTES de ordenar o escribir specs, evaluar si cada ticket necesita partirse.
Este paso usa SOLO los datos del inventario (Paso 1) — NO profundiza en código.

**Objetivo:** Detectar tickets sobredimensionados antes de gastar contexto en
specs detallados. La decisión de partir es barata aquí y cara después.

### Proceso

Para cada ticket con complejidad Media o Alta, evaluar las 6 señales de
complejidad de `references/subagent-sizing.md` usando solo la información
del inventario:

| Señal | Cómo evaluarla con datos del inventario |
|-------|----------------------------------------|
| Objetivo con múltiples responsabilidades | ¿El título/descripción del ticket tiene "y", "además", "también"? |
| Más de 8 archivos en scope | Contar archivos del inventario (columna Archivos) |
| Más de 4 criterios de aceptación independientes | Contar criterios mencionados en el ticket |
| Subtareas sin archivos compartidos | ¿Los grupos de archivos son disjuntos? |
| Más de 2 módulos/directorios afectados | Contar directorios únicos de los archivos del inventario |
| Complejidad Alta + más de 3 subtareas | ¿Se anticipa que necesite 4+ subtareas? |

### Decisión

| Señales activas | Acción |
|----------------|--------|
| 0-1 | Ticket pasa al Paso 2 tal cual |
| 2+ | OBLIGATORIO partir en sub-tickets |

### Cómo documentar la partición

Para tickets que se parten, producir una **tabla de triage** (NO specs completos):

```
Ticket original: T-N — [título]
Señales activas: [N]/6 — [listar cuáles]

| Sub-ticket | Scope rough | Archivos (~) | Complejidad estimada |
|------------|-------------|-------------|---------------------|
| T-N.a | [1 frase] | [lista corta] | Simple/Media |
| T-N.b | [1 frase] | [lista corta] | Simple/Media |
```

**Reglas de la partición:**
- Cada sub-ticket debe poder ejecutarse y hacer commit independiente
- Cada sub-ticket debe tener complejidad Simple o Media (NUNCA Alta)
- Si un sub-ticket resultante sigue siendo Alta → partir otra vez
- Documentar dependencias entre sub-tickets (ej: "T-N.b requiere T-N.a")
- NUNCA escribir specs detallados aquí — solo nombre, scope de 1 frase,
  archivos rough, y complejidad estimada

### Gate

Presentar tabla de triage al usuario. NO continuar al Paso 2 hasta que
el usuario apruebe las particiones. Si el usuario ajusta la división,
actualizar la tabla.

Los sub-tickets aprobados reemplazan al ticket original en el inventario
y entran al Paso 2 como tickets independientes.

**Tickets Simple:** Pasan directo — no necesitan triage.

## Paso 2 — Ordenar tickets, detectar paralelismo, y definir puntos de corte

Ordenar TODOS los tickets en una sola secuencia de ejecución.

**Criterios de orden (por prioridad):**
1. **Dependencia técnica** — si B depende de A, A va primero
2. **Dominio compartido** — tickets que tocan los mismos archivos van juntos
3. **Complejidad intercalada** — evitar agrupar varios tickets de complejidad Alta seguidos

### Computar execution_class por spec (OBLIGATORIO)

Después de que TODOS los specs estén escritos, el Paso 2 computa la
`execution_class` de cada spec comparando scope fences cruzados.
El campo viene con valor `auto` en el frontmatter — NUNCA lo llena
el escritor del spec manualmente.

**Algoritmo:**
```
Para cada spec S:
  1. ¿S modifica archivos? (allowed_paths no vacío y no es solo lectura)
     - NO → execution_class = read_only
     - SÍ → continuar
  2. ¿Algún archivo de S.allowed_paths aparece en allowed_paths de otro spec?
     - NO → ¿S toca config global (.claude/*, CLAUDE.md, CI)?
       - NO → execution_class = isolated_write
       - SÍ → execution_class = repo_wide
     - SÍ → execution_class = shared_write
```

Actualizar el frontmatter de cada spec con el valor computado.
Los specs con `isolated_write` son candidatos a batch-eligible.

### Detección de tickets batch-eligible (para /batch)

Después de ordenar, identificar clusters de tickets que pueden ejecutarse
en paralelo con `/batch`:

**Un ticket es batch-eligible si:**
- No tiene dependencias hacia otros tickets del batch
- Ningún otro ticket depende de él dentro del batch
- Su complejidad es Simple o Media (NO Alta)
- Su scope fence no se solapa con el de otros tickets batch-eligible
  (no comparten archivos en sus allowlists)

**Agrupar batch-eligible:**
1. Construir grafo de dependencias
2. Tickets sin aristas (nodos aislados) son candidatos
3. Verificar que no comparten archivos
4. Si hay 3+ candidatos → marcar como grupo batch-eligible
5. Si hay <3 → no justifica /batch, ejecutar secuencialmente

**En el plan de ejecución, marcar los tickets batch-eligible:**
```
| # | Ticket | Modo |
| B | T-3, T-5, T-7 | /batch (paralelo) |
| 4 | T-8 | Subagente (secuencial) |
| 5 | T-9 | Subagente (secuencial) |
```

**Si /batch no está disponible:** Todos se ejecutan secuencialmente.
El plan sigue siendo válido — los batch-eligible simplemente se corren uno por uno.

### Gestión de contexto (auto-compact + checkpoint)

NO insertar puntos de corte hardcoded en el plan. El contexto se gestiona así:

- **Auto-compact:** Claude Code compacta automáticamente cuando el contexto
  se acerca al límite. NUNCA pedir /compact manualmente.
- **Checkpoint (Regla 5):** Después de cada ticket, el orquestador verifica
  si hay degradación real (relectura de archivos, pérdida de track).
  Solo pide `/clear` si detecta degradación que el auto-compact no resolvió.
- Toda la ejecución ocurre en **una sola rama y un solo PR**
- Para que el auto-compact preserve lo importante, SIEMPRE incluir
  instrucciones de compactación en CLAUDE.md del proyecto (ver Paso 5)

Presentar propuesta de orden al usuario.

## Paso 3 — Generar specs

### Tickets triviales (sin spec)

Un ticket es **trivial** si cumple TODOS estos criterios:
- Toca ≤2 archivos
- El cambio es mecánico (renombrar, cambiar valor, actualizar docstring)
- No tiene dependencias ni bloquea a otros
- No requiere tests nuevos

Los tickets triviales NO necesitan spec completo. En su lugar, se incluyen
como **oneliners** directamente en la tabla del prompt de ejecución:

```
| # | Ticket | Spec | Complejidad |
| 1 | T-3 | INLINE: Cambiar 'no_response' a 'deferred' en docstrings de core/outcomes.py L133,138,144 | Trivial |
```

El subagente recibe la instrucción inline y hace commit. La verificación
post-subagente sigue aplicando (scope, tests, completitud básica).

### Tickets normales (con spec)

Para cada ticket NO trivial, generar un archivo `.ai/specs/active/ticket-N.md`
siguiendo la plantilla en `templates/spec-template.md`.

**Límite de specs por subagente: máximo 6.**
Si el sprint tiene más de 6 tickets, partir la generación de specs en
lotes de ≤6 y delegar cada lote a un subagente diferente. Cada subagente
recibe: la tabla de inventario (Paso 1), la plantilla de spec, y la lista
de tickets que le tocan. Esto previene degradación de calidad en los
últimos specs por acumulación de contexto.

Ejemplo con 14 tickets:
- Subagente 1: specs T-1 a T-6 (6 specs)
- Subagente 2: specs T-7 a T-12 (6 specs)
- Subagente 3: specs T-13 a T-14 (2 specs)

Si hay dependencias entre tickets de diferentes lotes, incluir en el
prompt del subagente posterior un resumen de 1 línea de los specs
relevantes ya generados (leer de disco). NO pasar specs completos
como contexto — solo: id, título, allowed_paths.

**Ubicación:** Los specs van en `.ai/specs/active/` (relativo a la raíz
del repositorio). Al finalizar, se archivan automáticamente
en `.ai/specs/archive/[nombre-batch]/`.

**Commits atómicos obligatorios:**
Cada ticket (o subtarea) termina con un commit atómico independiente.
Esto permite `git revert [hash]` de cualquier ticket sin afectar al resto.
El mensaje de commit debe incluir el número de ticket para trazabilidad.

**Regla crítica de división en subtareas:**

Leer `references/subagent-sizing.md` para las reglas de cuándo y cómo
dividir un ticket en subtareas para subagentes.

Resumen rápido:
- Si un ticket toca **≤ 3 archivos** y tiene **≤ 3 pasos lógicos** → NO dividir
- Si toca **4-8 archivos** → dividir en 2-3 subtareas
- Si toca **9+ archivos** o tiene lógica algorítmica compleja → dividir en 3-5 subtareas
- Cada subtarea debe ser **autocontenida**: ejecutable sin saber qué hacen las otras
- Cada subtarea termina con un **commit atómico**

## Paso 3.5 — Preflight: validar specs antes de continuar

ANTES de generar el prompt, validar TODOS los specs generados
usando la lógica definida en `commands/preflight.md`.

**Esta validación es obligatoria.** No generar prompt si hay specs con FAIL.

Resumen de lo que valida (dos capas):

**Capa 1 — Estructural (determinista, sin interpretación):**
- Headings obligatorios existen (Objetivo, Scope fence, Tests, etc.)
- Secciones no vacías
- Formato correcto (rutas con backtick, commits con formato, criterios como checkbox)
- Cruces numéricos (allowlist ≥ archivos, denylist > 0, restricciones ≤ 10)

**Capa 2 — Semántico (requiere interpretación):**
- Campos obligatorios: objetivo, modo, scope fence, archivos, tests, aceptación, commit
- Campos warning: restricciones, dependencias, complejidad, pasos concretos
- Cruce: archivos del spec vs allowlist del scope fence
- Cruce: dependencias referenciadas vs specs existentes

La capa estructural se ejecuta primero y es determinista (mismo spec = mismo resultado).

Si hay FAIL:
1. Listar specs fallidos con campos faltantes
2. Corregir los specs antes de continuar
3. Re-validar

Si hay solo WARNINGS:
1. Mostrar al usuario
2. Preguntar si quiere corregir o continuar

Nota: este es el MISMO motor que el comando `/preflight`.

## Paso 4 — Generar prompt + reglas de orquestación

Generar estos archivos siguiendo `templates/orchestrator-prompt.md`:

1. **Prompt de ejecución** (~1-2K tokens) — archivo independiente en
   `.ai/prompts/[nombre-batch].md`. Crear la carpeta si no existe:
   `mkdir -p .ai/prompts`
   Solo contiene: instrucción de leer reglas + tabla de tickets con ruta al spec.
   Es ultra-lean para mantenerse en la zona de fidelidad total (0-5K tokens).

2. **`.ai/rules.md`** — SOLO overrides del sprint (perfil de permiso, comando de tests,
   puntos de corte). Las reglas estándar viven en
   `${CLAUDE_PLUGIN_ROOT}/references/reglas-orquestacion.md` y el prompt apunta a ambos.

**El prompt es un archivo independiente** para que el usuario solo
necesite pegar una línea en Claude Code:
```
Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.
```
Cowork genera esta línea en el Paso 6.

**Principio de diseño (lazy loading):**
- El prompt NO inlinea los prompts de cada ticket
- Cada subagente lee su spec directamente de `.ai/specs/active/ticket-N.md`
- Los specs ya son autocontenidos (verificar checklist en spec-template.md)
- Esto mantiene el prompt del orquestador lean, resiste /compact sin
  paraphrase loss, y escala sin importar cuántos tickets haya

## Paso 5 — Generar artefactos de soporte (progresivo)

La infraestructura no se pre-carga toda de una vez. Seguir este orden
de **mínimo viable → crece según necesidad**:

**Siempre generar:**
1. **CLAUDE.md** del proyecto (si no existe o necesita actualización)
   - Leer `templates/claudemd-template.md` para la estructura
   - Mantener bajo 100 líneas / ~2500 tokens — se enriquece con `/learn`
   - Forma imperativa obligatoria (SIEMPRE/NUNCA) — 94% compliance vs 73% descriptivo
   - Incluir sección "Intentos fallidos" (previene ciclos de reintento costosos)
   - Reglas procedurales (lint, formato) → hooks/settings.json, NO en CLAUDE.md
   - Test de sustracción: cada regla debe prevenir un error concreto y específico
2. **Comandos base** en `.claude/commands/`
   - `/learn` — captura conocimiento post-ticket (ver `commands/learn.md`)
   - `/next-ticket` — lee el siguiente spec y empieza (ver `commands/next-ticket.md`)
   - `/status` — muestra progreso del sprint (ver `commands/status.md`)
   - `/preflight` — validación pre-ejecución de specs (ver `commands/preflight.md`)
3. **Plan de ejecución** — `.ai/plan.md`
   - Leer `templates/execution-plan-template.md`

**Instalar (costo mínimo, protección máxima):**
4. **Guard destructivo** (PreToolUse hook) — protege contra `rm -rf`, `git push --force`
   - Leer `templates/stop-hook.md` sección "Hook 1"
   - Script externo en `.claude/hooks/guard-destructive.sh`
   - Compatible con el rollback de Regla 2 (no bloquea `git reset --hard`)

**Activar si están disponibles (integraciones con Claude Code):**
5. **`/simplify`** — gate de calidad post-implementación (Regla 8)
   - Se activa automáticamente si `/simplify` está disponible
   - Solo para tickets de complejidad Media o Alta
   - NO requiere configuración — las reglas en `.ai/rules.md` lo manejan
6. **`/batch`** — ejecución paralela de tickets independientes (Regla 9)
   - Se activa si hay 3+ tickets batch-eligible (detectados en Paso 2)
   - Requiere que `/batch` esté disponible en Claude Code
   - NO requiere configuración — el orquestador detecta y delega

**Sugerir pero no instalar aún (evaluar después de la primera ejecución):**
7. **Agentes custom** en `.claude/agents/`
   - Leer `references/agent-patterns.md` para los patrones
   - Solo crear si `/learn` detecta que el mismo tipo de error se repite 3+ veces
8. **Hook anti-racionalización** (Stop hook)
   - Leer `templates/stop-hook.md` sección "Hook 2"
   - Solo instalar si durante la ejecución Claude declara victoria prematura
9. **`/retrospective`** — análisis retroactivo de sesiones
   - Instalar `commands/retrospective.md` después de la primera ejecución completa
10. **`/loop`** — monitor post-PR para CI y review comments
    - Ejecutar después de crear el PR: `/loop 5m` para monitorear CI status,
      review comments, y auto-fix failures
    - Solo sugerir si el proyecto tiene CI configurado

**Principio:** La complejidad emerge de la presión real, no se anticipa.

**Presupuesto de tokens (thresholds empíricos):**
- CLAUDE.md: ~2500 tokens (100 líneas). Más = dilución de atención
- Cada spec: ~5000 tokens. Más = pérdida de fidelidad
- Máx 10 constraints por spec/delegación. Más = omisiones
- Contexto del orquestador: degradación medible a ~100K tokens (50% capacidad)
- Zona segura de fidelidad total: 0-5K tokens de instrucciones

## Paso 6 — Revisión con el usuario

Presentar el paquete completo:
- Tabla de tickets en orden de ejecución, con puntos de corte marcados
- Specs generados (resumen de cada uno)
- Advertencias sobre tickets sacados del prompt (si los hay)
- **Infraestructura diferida:** qué se podría agregar después de la primera ejecución

**Línea de ejecución:**
Generar una sola línea lista para copiar-pegar en Claude Code:

```
Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.
```

Para tickets sacados del prompt (excepcionalmente complejos):
```
Lee .ai/specs/active/ticket-[N].md e impleméntalo. Usa subagents.
```

Ajustar según feedback antes de continuar al Paso 7.

## Paso 7 — Commit de preparación

Commitear todos los artefactos generados para que Claude Code los encuentre
en un estado limpio (importante: `git reset --hard` durante rollback borraría
archivos no commiteados, incluyendo los specs).

```bash
git add .ai/specs/active/ .ai/prompts/ .ai/rules.md .ai/plan.md \
       CLAUDE.md .claude/ 2>/dev/null
git commit -m "chore: preparar sprint [nombre-batch] — [N] tickets"
```

**Incluir:** specs, prompt, rules.md, plan.md, CLAUDE.md, .claude/ (si nuevos/modificados).
**NO incluir:** archivos .plugin, .ai/runs/ (se crea durante ejecución), temporales.

Este commit es el punto de partida limpio para la ejecución autónoma.
