# Flujo principal del orquestador

Todas las rutas son relativas a este skill.

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

## Paso 2 — Agrupación en sprints

Agrupar tickets por estos criterios (en orden de prioridad):

1. **Dependencia técnica** — si B depende de A, van en el mismo sprint (A primero)
2. **Dominio compartido** — tickets que tocan los mismos archivos juntos
3. **Complejidad balanceada** — no más de 2 tickets de complejidad Alta por sprint

Cada sprint = 1 rama de git = 1 prompt de sprint. Presentar propuesta al usuario.

## Paso 3 — Generar specs

Para CADA ticket, generar un archivo `.ai/specs/active/ticket-N.md`
siguiendo la plantilla en `templates/spec-template.md`.

**Ubicación:** Los specs van en `.ai/specs/active/` (relativo a la raíz
del repositorio). Al finalizar el sprint, se archivan automáticamente
en `.ai/specs/archive/sprint-[LETRA]/`.

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

ANTES de generar el prompt del sprint, validar TODOS los specs generados
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

## Paso 4 — Generar prompt del sprint + reglas de orquestación

Para CADA sprint, generar DOS archivos siguiendo `templates/orchestrator-prompt.md`:

1. **Prompt del sprint** (~1-2K tokens) — Lo que el usuario pega en Claude Code.
   Solo contiene: instrucción de leer reglas + tabla de tickets con ruta al spec.
   Es ultra-lean para mantenerse en la zona de fidelidad total (0-5K tokens).

2. **`.ai/rules.md`** — Reglas de orquestación que el agente lee de disco.
   Contiene: las 7 reglas (incluyendo 2b scope audit y 2c completitud),
   formato de .ai/runs/results.tsv, patrón Heat Shield, y paso final de `/learn`.

**Principio de diseño (lazy loading):**
- El prompt del sprint NO inlinea los prompts de cada ticket
- Cada subagente lee su spec directamente de `.ai/specs/active/ticket-N.md`
- Los specs ya son autocontenidos (verificar checklist en spec-template.md)
- Esto mantiene el prompt del orquestador lean, resiste /compact sin
  paraphrase loss, y escala sin importar cuántos tickets tenga el sprint

## Paso 5 — Generar artefactos de soporte (progresivo)

La infraestructura no se pre-carga toda de una vez. Seguir este orden
de **mínimo viable → crece según necesidad**:

**Siempre generar (Sprint 1):**
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

**Instalar en Sprint 1 (costo mínimo, protección máxima):**
4. **Guard destructivo** (PreToolUse hook) — protege contra `rm -rf`, `git push --force`
   - Leer `templates/stop-hook.md` sección "Hook 1"
   - Hook tipo `command` (~50ms), no afecta performance
   - Compatible con el rollback de Regla 2 (no bloquea `git reset --hard`)

**Sugerir pero no instalar aún (evaluar después del Sprint 1):**
5. **Agentes custom** en `.claude/agents/`
   - Leer `references/agent-patterns.md` para los patrones
   - Solo crear si después del primer sprint `/learn` detecta que el mismo
     tipo de error se repite 3+ veces en un dominio específico
6. **Hook anti-racionalización** (Stop hook)
   - Leer `templates/stop-hook.md` sección "Hook 2"
   - Solo instalar si durante la ejecución Claude declara victoria prematura
7. **`/retrospective`** — análisis retroactivo de sesiones
   - Instalar `commands/retrospective.md` después del primer sprint completo

**Principio:** La complejidad emerge de la presión real, no se anticipa.

**Presupuesto de tokens (thresholds empíricos):**
- CLAUDE.md: ~2500 tokens (100 líneas). Más = dilución de atención
- Cada spec: ~5000 tokens. Más = pérdida de fidelidad
- Máx 10 constraints por spec/delegación. Más = omisiones
- Contexto del orquestador: degradación medible a ~100K tokens (50% capacidad)
- Zona segura de fidelidad total: 0-5K tokens de instrucciones

## Paso 6 — Revisión con el usuario

Presentar el paquete completo:
- Tabla de sprints con tickets y modo de ejecución
- Specs generados (resumen de cada uno)
- **Prompts lean generados** (uno por sprint, listos para copiar y pegar)
- Advertencias sobre tickets sacados del prompt (si los hay)
- **Infraestructura diferida:** qué se podría agregar después del Sprint 1

Ajustar según feedback antes de empaquetar.
