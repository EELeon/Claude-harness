---
name: code-orchestrator
description: >
  Orquestador de tickets para Claude Code. Usa este skill siempre que el usuario tenga
  múltiples tickets, tareas, features o issues que implementar con Claude Code.
  Actívalo cuando diga: "tengo estos tickets", "implementar estos cambios",
  "preparar specs para Code", "dividir en subtareas", "organizar trabajo para Code",
  "sprint de desarrollo", "batch de features", o cualquier referencia a preparar
  trabajo de programación en lote. También actívalo si el usuario pregunta cómo dividir
  trabajo entre subagentes, cómo manejar contexto en sesiones largas de Code,
  o cómo organizar implementación de múltiples cambios en un codebase.
---

# Code Orchestrator — De tickets a ejecución autónoma en Claude Code

## Propósito

Convertir un lote de tickets/tareas en un paquete que Claude Code ejecute
de manera autónoma, con un solo prompt por sprint. El paquete incluye:

1. **Specs ejecutables** — cada ticket sin ambigüedad
2. **Mega-prompt orquestador** — un prompt por sprint que ejecuta todos los tickets
3. **División en subtareas** — respetando límites de contexto de subagentes
4. **Agentes custom** — archivos `.claude/agents/` para el proyecto
5. **Comandos** — `/learn`, `/status`, `/next-ticket`
6. **CLAUDE.md seed** — reglas base del proyecto
7. **Hook Stop** — anti-racionalización para prevenir trabajo incompleto

---

## Modelo de ejecución: subagentes + gestión inteligente de contexto

Claude Code no puede ejecutar `/clear` ni `/compact` programáticamente.
El orquestador usa una estrategia de 4 capas para que Code
nunca se quede sin ventana de contexto:

1. **Subagentes por ticket** — Cada ticket corre como subagente con contexto
   fresco (~200k tokens). El orquestador solo recibe el resultado resumido.
2. **Estado en disco** — El orquestador escribe resultados a `results.tsv`
   (TSV estructurado: ticket, commit, tests, status, description). Si se
   pierde contexto, retoma leyendo ese archivo. `/learn` complementa con
   `done-tasks.md` para lecciones narrativas.
3. **Compactación proactiva** — Después de cada ticket, el orquestador evalúa
   su propio contexto. Si está pesado (3+ tickets completados), le pide al
   usuario correr `/compact` antes de continuar.
4. **Puntos de corte** — Para sprints largos (5+ tickets), el prompt del sprint
   incluye puntos de pausa donde el usuario puede hacer `/clear` y re-pegar
   el prompt. El orquestador retoma automáticamente desde donde se quedó.

**Limitaciones:**
- Los subagentes no pueden crear sub-subagentes. Si un ticket tiene subtareas,
  el subagente las ejecuta secuencialmente en su propia ventana.
- **Máximo 5 subagentes concurrentes** por codebase (más = degradación sistémica).
- Cada subagente empieza con **contexto en blanco** — todo lo que necesita
  saber debe ir en el prompt de delegación.
- El subagente devuelve **síntesis, no datos crudos** (patrón Heat Shield)
  para proteger el contexto del orquestador.

Para tickets excepcionalmente complejos (Alta complejidad + 4 subtareas de 5+ archivos),
se sacan del prompt del sprint y se ejecutan directo en la sesión principal.

---

## Flujo principal

### Paso 1 — Inventario y análisis

Leer todos los tickets. Para cada uno, extraer:

| Campo | Qué buscar |
|-------|-----------|
| **Archivos** | Archivos mencionados explícitamente + inferidos del contexto |
| **Complejidad** | Simple (1-3 archivos), Media (4-8), Alta (9+) |
| **Dependencias** | ¿Qué tickets deben completarse antes? |
| **Dominio** | ¿Eléctrico, hidráulico, estructural, UI, catálogo, etc.? |
| **Tests** | Tests mencionados en el ticket |
| **Modo de ejecución** | Subagente (default) o Sesión principal (si es excepcionalmente complejo) |

Presentar tabla-resumen al usuario antes de continuar.

### Paso 2 — Agrupación en sprints

Agrupar tickets por estos criterios (en orden de prioridad):

1. **Dependencia técnica** — si B depende de A, van en el mismo sprint (A primero)
2. **Dominio compartido** — tickets que tocan los mismos archivos juntos
3. **Complejidad balanceada** — no más de 2 tickets de complejidad Alta por sprint

Cada sprint = 1 rama de git = 1 prompt de sprint. Presentar propuesta al usuario.

### Paso 3 — Generar specs

Para CADA ticket, generar un archivo `specs/ticket-N.md` siguiendo
la plantilla en `templates/spec-template.md`.

**Regla crítica de división en subtareas:**

Leer `references/subagent-sizing.md` para las reglas de cuándo y cómo
dividir un ticket en subtareas para subagentes.

Resumen rápido:
- Si un ticket toca **≤ 3 archivos** y tiene **≤ 3 pasos lógicos** → NO dividir
- Si toca **4-8 archivos** → dividir en 2-3 subtareas
- Si toca **9+ archivos** o tiene lógica algorítmica compleja → dividir en 3-5 subtareas
- Cada subtarea debe ser **autocontenida**: ejecutable sin saber qué hacen las otras
- Cada subtarea termina con un **commit atómico**

### Paso 3.5 — Preflight: validar specs antes de continuar

ANTES de generar el prompt del sprint, validar TODOS los specs generados
usando la lógica definida en `commands/preflight.md`.

**Esta validación es obligatoria.** No generar prompt si hay specs con FAIL.

Resumen de lo que valida:
- Campos obligatorios: objetivo, modo, scope fence, archivos, tests, aceptación, commit
- Campos warning: restricciones, dependencias, complejidad, pasos concretos
- Cruce: archivos del spec vs allowlist del scope fence
- Cruce: dependencias referenciadas vs specs existentes
- Restricciones excesivas (>10 = warning)

Si hay FAIL:
1. Listar specs fallidos con campos faltantes
2. Corregir los specs antes de continuar
3. Re-validar

Si hay solo WARNINGS:
1. Mostrar al usuario
2. Preguntar si quiere corregir o continuar

Nota: este es el MISMO motor que el comando `/preflight`.
Cowork lo corre aquí; el usuario puede correrlo después con `/preflight`.

### Paso 4 — Generar prompt del sprint + reglas de orquestación

Para CADA sprint, generar DOS archivos siguiendo `templates/orchestrator-prompt.md`:

1. **Prompt del sprint** (~1-2K tokens) — Lo que el usuario pega en Claude Code.
   Solo contiene: instrucción de leer reglas + tabla de tickets con ruta al spec.
   Es ultra-lean para mantenerse en la zona de fidelidad total (0-5K tokens).

2. **ORCHESTRATOR_RULES.md** — Reglas de orquestación que el agente lee de disco.
   Contiene: las 6 reglas, formato de results.tsv, patrón Heat Shield, y
   paso final de `/learn`.

**Principio de diseño (lazy loading):**
- El prompt del sprint NO inlinea los prompts de cada ticket
- Cada subagente lee su spec directamente de `specs/ticket-N.md`
- Los specs ya son autocontenidos (verificar checklist en spec-template.md)
- Esto mantiene el prompt del orquestador lean, resiste /compact sin
  paraphrase loss, y escala sin importar cuántos tickets tenga el sprint

### Paso 5 — Generar artefactos de soporte (progresivo)

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
3. **Plan de ejecución** — `EXECUTION_PLAN.md` en la raíz
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
   - Describir al usuario qué agentes SE PODRÍAN crear y por qué, pero
     dejar que la experiencia real del primer sprint confirme la necesidad
6. **Hook anti-racionalización** (Stop hook)
   - Leer `templates/stop-hook.md` sección "Hook 2"
   - Solo instalar si durante la ejecución Claude declara victoria prematura
     o `/learn` reporta trabajo incompleto aceptado
   - Mencionar al usuario que existe y cómo activarlo cuando lo necesite
6. **`/retrospective`** — análisis retroactivo de sesiones
   - Instalar `commands/retrospective.md` después del primer sprint completo
   - Complementa a `/learn` (captura en caliente) con vista panorámica periódica

**Principio:** La complejidad emerge de la presión real, no se anticipa.
Un CLAUDE.md con 3 reglas probadas en batalla vale más que uno con 30
reglas teóricas. `/learn` se encarga de que las reglas crezcan orgánicamente.

**Presupuesto de tokens (thresholds empíricos):**
- CLAUDE.md: ~2500 tokens (100 líneas). Más = dilución de atención
- Cada spec: ~5000 tokens. Más = pérdida de fidelidad
- Máx 10 constraints por spec/delegación. Más = omisiones
- Contexto del orquestador: degradación medible a ~100K tokens (50% capacidad)
- Zona segura de fidelidad total: 0-5K tokens de instrucciones

### Paso 6 — Revisión con el usuario

Presentar el paquete completo:
- Tabla de sprints con tickets y modo de ejecución
- Specs generados (resumen de cada uno)
- **Mega-prompts generados** (uno por sprint, listos para copiar y pegar)
- Advertencias sobre tickets sacados del prompt (si los hay)
- **Infraestructura diferida:** qué agentes custom, hooks, y comandos
  adicionales podrían ser útiles DESPUÉS del primer sprint, y bajo qué
  condiciones activarlos

Ajustar según feedback antes de empaquetar.

---

## Reglas de escritura de specs

Un spec debe permitir que Claude Code ejecute **sin preguntar nada**.
Si Claude Code tiene que "entender" o "explorar" antes de actuar,
el spec está incompleto.

**Límites empíricos para specs efectivos:**
- Máximo **10 constraints** por spec (más causa omisiones críticas)
- Target ~5000 tokens por spec (>5K = pérdida de fidelidad en instrucciones)
- Forma imperativa en restricciones: "NUNCA X", "SIEMPRE Y"
- Si hay dependencia fuerte con otro ticket, usar patrón Interface-First
  (definir contrato/stub compartido antes de implementar)

Cada spec DEBE incluir:

```markdown
# Ticket N — [Título]

## Objetivo (1-2 frases)

## Archivos a modificar
- `ruta/exacta/archivo.py` — qué cambiar

## Archivos a crear
- `ruta/exacta/nuevo.py` — qué contiene

## Subtareas (si aplica)
### Subtarea 1 — [nombre]
**Archivos:** [lista]
**Instrucciones:** [paso a paso]
**Tests:** [comando exacto]
**Commit message:** "[tipo]: descripción"

## Tests que deben pasar
- [ ] Test 1: descripción exacta
- [ ] Test 2: descripción exacta

## Criterios de aceptación
- [ ] Criterio 1
- [ ] Criterio 2

## NO hacer
- No X
- No Y
```

---

## Entrega final

El paquete del Sprint 1 incluye solo lo esencial:

```
proyecto/
├── .claude/
│   ├── commands/
│   │   ├── learn.md           # Siempre
│   │   ├── next-ticket.md     # Siempre
│   │   ├── status.md          # Siempre
│   │   └── preflight.md       # Siempre (motor del Paso 3.5)
│   ├── agents/                # Solo si /learn lo sugiere después del Sprint 1
│   └── settings.json          # Guard destructivo (Sprint 1) + hook Stop (si se necesita)
├── specs/
│   ├── ticket-1.md
│   ├── ticket-2.md
│   └── ...
├── CLAUDE.md                  # Mínimo viable — crece con /learn
├── ORCHESTRATOR_RULES.md      # Reglas de orquestación (leídas de disco)
├── EXECUTION_PLAN.md          # Plan + prompts lean por sprint
├── results.tsv                # Tracking estructurado (keep/discard/crash)
└── done-tasks.md              # Lecciones narrativas (escrito por /learn)
```

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

Instrucciones para el usuario:

> **Para ejecutar un sprint:**
> 1. `git checkout -b sprint-[X]-[nombre]`
> 2. `claude`
> 3. Pegar el prompt del sprint (está en EXECUTION_PLAN.md — es lean, ~1-2K tokens)
> 4. El orquestador lee ORCHESTRATOR_RULES.md y cada subagente lee su spec de disco
> 5. Esperar a que Claude Code termine todos los tickets
> 6. Revisar el resumen final
> 7. `gh pr create --title "Sprint [X]: [nombre]"`
>
> **Si un ticket falla durante la ejecución autónoma:**
> Claude Code lo reportará en el resumen. Podés corregirlo manualmente
> o correr `/next-ticket` para reintentar.
>
> **Para tickets sacados del prompt (excepcionalmente complejos):**
> 1. Ejecutar el prompt del sprint primero (tickets normales)
> 2. Después: `> Lee specs/ticket-[N].md e impleméntalo. Usa subagents.`
> 3. `> /learn ticket-[N] [título]`

---

## Archivos de referencia del skill

Leer estos archivos cuando sea necesario:

| Archivo | Cuándo leerlo |
|---------|--------------|
| `references/subagent-sizing.md` | Al dividir tickets en subtareas |
| `references/agent-patterns.md` | Al crear agentes custom |
| `templates/spec-template.md` | Al escribir cada spec |
| `templates/orchestrator-prompt.md` | Al generar el prompt del sprint + ORCHESTRATOR_RULES.md |
| `templates/stop-hook.md` | Al configurar hooks (guard destructivo + anti-racionalización) |
| `templates/claudemd-template.md` | Al generar CLAUDE.md |
| `templates/execution-plan-template.md` | Al generar el plan de ejecución |
| `commands/learn.md` | Al instalar el comando /learn |
| `commands/next-ticket.md` | Al instalar el comando /next-ticket |
| `commands/status.md` | Al instalar el comando /status |
| `commands/preflight.md` | Al instalar el comando /preflight Y como motor del Paso 3.5 |
| `commands/retrospective.md` | Al instalar /retrospective (post Sprint 1) |
