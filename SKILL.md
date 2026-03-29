---
name: code-orchestrator
description: >
  Orquestador de tickets para Claude Code. Usa este skill siempre que Edwin tenga
  múltiples tickets, tareas, features o issues que implementar con Claude Code.
  Actívalo cuando diga: "tengo estos tickets", "implementar estos cambios",
  "preparar specs para Code", "dividir en subtareas", "organizar trabajo para Code",
  "sprint de desarrollo", "batch de features", o cualquier referencia a preparar
  trabajo de programación en lote. También actívalo si Edwin pregunta cómo dividir
  trabajo entre subagentes, cómo manejar contexto en sesiones largas de Code,
  o cómo organizar implementación de múltiples cambios en un codebase.
---

# Code Orchestrator — De tickets a ejecución en Claude Code

## Propósito

Convertir un lote de tickets/tareas en un paquete listo para ejecución
autónoma en Claude Code, incluyendo:

1. **Specs ejecutables** — cada ticket convertido en instrucciones sin ambigüedad
2. **División en subtareas** — respetando límites de contexto de subagentes
3. **Agentes custom** — archivos `.claude/agents/` para el proyecto
4. **Comandos** — `/learn`, `/status`, `/next-ticket`
5. **CLAUDE.md seed** — reglas base del proyecto
6. **Plan de ejecución** — orden, ramas, sprints

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

Presentar tabla-resumen a Edwin antes de continuar.

### Paso 2 — Agrupación en sprints

Agrupar tickets por estos criterios (en orden de prioridad):

1. **Dependencia técnica** — si B depende de A, van en el mismo sprint (A primero)
2. **Dominio compartido** — tickets que tocan los mismos archivos juntos
3. **Complejidad balanceada** — no más de 2 tickets de complejidad Alta por sprint

Cada sprint = 1 rama de git. Presentar propuesta a Edwin.

### Paso 3 — Generar specs

Para CADA ticket, generar un archivo `specs/ticket-N.md` siguiendo
la plantilla en `templates/spec-template.md`.

**Regla crítica de división en subtareas:**

Leer `references/subagent-sizing.md` para las reglas de cuándo y cómo
dividir un ticket en subtareas para subagentes.

Resumen rápido:
- Si un ticket toca **≤ 3 archivos** y tiene **≤ 3 pasos lógicos** → NO dividir
- Si toca **4-8 archivos** → dividir en 2-3 subtareas
- Si toca **9+ archivos** o tiene lógica geométrica/algorítmica compleja → dividir en 3-5 subtareas
- Cada subtarea debe ser **autocontenida**: un subagente debe poder completarla
  sin saber qué hacen las otras subtareas
- Cada subtarea termina con un **commit atómico**

### Paso 4 — Generar artefactos de ejecución

Además de los specs, generar:

1. **CLAUDE.md** del proyecto (si no existe o necesita actualización)
   - Leer `templates/claudemd-template.md` para la estructura
2. **Agentes custom** en `.claude/agents/`
   - Leer `references/agent-patterns.md` para los patrones
3. **Comandos** en `.claude/commands/`
   - `/learn` — captura conocimiento post-ticket
   - `/next-ticket` — lee el siguiente spec y empieza
   - `/status` — muestra progreso del sprint
4. **Plan de ejecución** — `EXECUTION_PLAN.md` en la raíz

### Paso 5 — Revisión con Edwin

Presentar el paquete completo:
- Tabla de sprints con tickets
- Specs generados (resumen de cada uno)
- Agentes custom propuestos
- Estimación de sesiones/clears necesarios
- Advertencias sobre tickets de riesgo

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
**Subagente:** sí/no
**Archivos:** [lista]
**Instrucciones:** [paso a paso]
**Commit message:** "[tipo]: descripción"

### Subtarea 2 — [nombre]
...

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

## Después de generar todo

Decirle a Edwin:

> **Para ejecutar en Claude Code:**
> 1. `git checkout -b sprint-X`
> 2. `claude`
> 3. `> Lee specs/ticket-N.md e impleméntalo. Usa subagents para las subtareas marcadas.`
> 4. Cuando termine: `> /learn ticket-N [título]`
> 5. `> /clear`
> 6. Repetir con siguiente ticket
> 7. `gh pr create` al terminar el sprint

---

## Archivos de referencia

Leer estos archivos cuando sea necesario:

| Archivo | Cuándo leerlo |
|---------|--------------|
| `references/subagent-sizing.md` | Al dividir tickets en subtareas |
| `references/agent-patterns.md` | Al crear agentes custom |
| `templates/spec-template.md` | Al escribir cada spec |
| `templates/claudemd-template.md` | Al generar CLAUDE.md |
| `templates/commands/` | Al generar slash commands |
