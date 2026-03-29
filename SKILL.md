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
El mega-prompt orquestador usa una estrategia de 4 capas para que Code
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
4. **Puntos de corte** — Para sprints largos (5+ tickets), el mega-prompt
   incluye puntos de pausa donde el usuario puede hacer `/clear` y re-pegar
   el prompt. El orquestador retoma automáticamente desde donde se quedó.

**Limitación:** los subagentes no pueden crear sub-subagentes. Si un ticket
tiene subtareas, el subagente las ejecuta secuencialmente en su propia ventana.
Para tickets excepcionalmente complejos (Alta complejidad + 4 subtareas de 5+ archivos),
se sacan del mega-prompt y se ejecutan directo en la sesión principal.

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

Cada sprint = 1 rama de git = 1 mega-prompt. Presentar propuesta al usuario.

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

### Paso 4 — Generar mega-prompt orquestador

Para CADA sprint, generar un mega-prompt siguiendo `templates/orchestrator-prompt.md`.

El mega-prompt es el producto final más importante. Debe:
1. Listar los tickets del sprint en orden
2. Para cada ticket, incluir un **prompt autocontenido** para el subagente
3. Incluir verificación de tests y commits entre tickets
4. Incluir paso final de `/learn` (actualizar CLAUDE.md)

**Cómo construir el prompt de cada subagente:**
1. Leer el spec del ticket
2. Extraer: archivos, pasos, tests, commit message, restricciones
3. Agregar 1-2 líneas de contexto del CLAUDE.md relevantes al dominio
4. El prompt debe funcionar SIN que el subagente lea nada más que los archivos del repo

### Paso 5 — Generar artefactos de soporte (progresivo)

La infraestructura no se pre-carga toda de una vez. Seguir este orden
de **mínimo viable → crece según necesidad**:

**Siempre generar (Sprint 1):**
1. **CLAUDE.md** del proyecto (si no existe o necesita actualización)
   - Leer `templates/claudemd-template.md` para la estructura
   - Mantener bajo 100 líneas — se enriquece con `/learn` después de cada ticket
2. **Comandos base** en `.claude/commands/`
   - `/learn` — captura conocimiento post-ticket (ver `commands/learn.md`)
   - `/next-ticket` — lee el siguiente spec y empieza (ver `commands/next-ticket.md`)
   - `/status` — muestra progreso del sprint (ver `commands/status.md`)
3. **Plan de ejecución** — `EXECUTION_PLAN.md` en la raíz
   - Leer `templates/execution-plan-template.md`

**Sugerir pero no instalar aún (evaluar después del Sprint 1):**
4. **Agentes custom** en `.claude/agents/`
   - Leer `references/agent-patterns.md` para los patrones
   - Solo crear si después del primer sprint `/learn` detecta que el mismo
     tipo de error se repite 3+ veces en un dominio específico
   - Describir al usuario qué agentes SE PODRÍAN crear y por qué, pero
     dejar que la experiencia real del primer sprint confirme la necesidad
5. **Hook Stop** — anti-racionalización
   - Leer `templates/stop-hook.md` para las opciones
   - Solo instalar si durante la ejecución Claude declara victoria prematura
     o `/learn` reporta trabajo incompleto aceptado
   - Mencionar al usuario que existe y cómo activarlo cuando lo necesite
6. **`/retrospective`** — análisis retroactivo de sesiones
   - Instalar `commands/retrospective.md` después del primer sprint completo
   - Complementa a `/learn` (captura en caliente) con vista panorámica periódica

**Principio:** La complejidad emerge de la presión real, no se anticipa.
Un CLAUDE.md con 3 reglas probadas en batalla vale más que uno con 30
reglas teóricas. `/learn` se encarga de que las reglas crezcan orgánicamente.

### Paso 6 — Revisión con el usuario

Presentar el paquete completo:
- Tabla de sprints con tickets y modo de ejecución
- Specs generados (resumen de cada uno)
- **Mega-prompts generados** (uno por sprint, listos para copiar y pegar)
- Advertencias sobre tickets sacados del mega-prompt (si los hay)
- **Infraestructura diferida:** qué agentes custom, hooks, y comandos
  adicionales podrían ser útiles DESPUÉS del primer sprint, y bajo qué
  condiciones activarlos

Ajustar según feedback antes de empaquetar.

---

## Reglas de escritura de specs

Un spec debe permitir que Claude Code ejecute **sin preguntar nada**.
Si Claude Code tiene que "entender" o "explorar" antes de actuar,
el spec está incompleto.

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
│   │   └── status.md          # Siempre
│   ├── agents/                # Solo si /learn lo sugiere después del Sprint 1
│   └── settings.json          # Solo si se necesita hook Stop
├── specs/
│   ├── ticket-1.md
│   ├── ticket-2.md
│   └── ...
├── CLAUDE.md                  # Mínimo viable — crece con /learn
├── EXECUTION_PLAN.md
├── results.tsv                # Tracking estructurado (keep/discard/crash)
└── done-tasks.md              # Lecciones narrativas (escrito por /learn)
```

Después del Sprint 1, `/learn` y `/retrospective` sugieren qué agregar.
La infraestructura crece orgánicamente en vez de pre-cargarse.

Instrucciones para el usuario:

> **Para ejecutar un sprint:**
> 1. `git checkout -b sprint-[X]-[nombre]`
> 2. `claude`
> 3. Pegar el mega-prompt del sprint (está en EXECUTION_PLAN.md)
> 4. Esperar a que Claude Code termine todos los tickets
> 5. Revisar el resumen final
> 6. `gh pr create --title "Sprint [X]: [nombre]"`
>
> **Si un ticket falla durante la ejecución autónoma:**
> Claude Code lo reportará en el resumen. Podés corregirlo manualmente
> o correr `/next-ticket` para reintentar.
>
> **Para tickets sacados del mega-prompt (excepcionalmente complejos):**
> 1. Ejecutar el mega-prompt primero (tickets normales)
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
| `templates/orchestrator-prompt.md` | Al generar el mega-prompt de cada sprint |
| `templates/stop-hook.md` | Al configurar el hook anti-racionalización |
| `templates/claudemd-template.md` | Al generar CLAUDE.md |
| `templates/execution-plan-template.md` | Al generar el plan de ejecución |
| `commands/learn.md` | Al instalar el comando /learn |
| `commands/next-ticket.md` | Al instalar el comando /next-ticket |
| `commands/status.md` | Al instalar el comando /status |
| `commands/retrospective.md` | Al instalar /retrospective (post Sprint 1) |
