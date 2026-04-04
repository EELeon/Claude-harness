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

## Paso 2 — Ordenar tickets y definir puntos de corte

Ordenar TODOS los tickets en una sola secuencia de ejecución.

**Criterios de orden (por prioridad):**
1. **Dependencia técnica** — si B depende de A, A va primero
2. **Dominio compartido** — tickets que tocan los mismos archivos van juntos
3. **Complejidad intercalada** — evitar agrupar varios tickets de complejidad Alta seguidos

**Puntos de corte** (para gestión de contexto, NO son sprints separados):
- Insertar un punto de corte cada 3-4 tickets
- Nunca cortar entre tickets con dependencia directa
- El punto de corte es una pausa para `/compact` o `/clear`, nada más
- Toda la ejecución ocurre en **una sola rama y un solo PR**

Presentar propuesta de orden al usuario.

## Paso 3 — Generar specs

Para CADA ticket, generar un archivo `.ai/specs/active/ticket-N.md`
siguiendo la plantilla en `templates/spec-template.md`.

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

2. **`.ai/rules.md`** — Reglas de orquestación que el agente lee de disco.
   Contiene: las 7 reglas (incluyendo 2b scope audit y 2c completitud),
   formato de .ai/runs/results.tsv, patrón Heat Shield, y paso final de `/learn`.

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

**Sugerir pero no instalar aún (evaluar después de la primera ejecución):**
5. **Agentes custom** en `.claude/agents/`
   - Leer `references/agent-patterns.md` para los patrones
   - Solo crear si `/learn` detecta que el mismo tipo de error se repite 3+ veces
6. **Hook anti-racionalización** (Stop hook)
   - Leer `templates/stop-hook.md` sección "Hook 2"
   - Solo instalar si durante la ejecución Claude declara victoria prematura
7. **`/retrospective`** — análisis retroactivo de sesiones
   - Instalar `commands/retrospective.md` después de la primera ejecución completa

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

Ajustar según feedback antes de empaquetar.
