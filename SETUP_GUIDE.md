# Guía de implementación — Code Orchestrator

Cómo instalar y usar este sistema en cualquier repositorio.

## Requisitos previos

- Claude Code instalado y funcionando
- Cowork con el skill `code-orchestrator` instalado
- Un repositorio git con al menos un commit
- Tickets/tareas definidos (pueden ser informales)

## Paso 1 — Instalar el skill (una sola vez)

Crear un symlink del repo Claude-harness al skill folder de Cowork:

```bash
ln -s "/ruta/a/Claude harness" ~/.claude/skills/code-orchestrator
```

Con el symlink, cada cambio al repo actualiza el skill automáticamente.
No hay que copiar ni sincronizar nada.

Para verificar que funciona:
```bash
ls -la ~/.claude/skills/code-orchestrator/SKILL.md
# Debe apuntar al SKILL.md del repo
```

## Paso 2 — Bootstrap de un repo nuevo

1. Abrí Cowork con acceso al repo target
2. Decile:
   > "Instalar harness en este repo" o "Preparar este repo para Code"
3. Cowork va a:
   - Auditar el repo (stack, comandos, estructura, archivos sensibles)
   - Instalar scaffold: CLAUDE.md, .claude/commands/, .claude/settings.json, .claude/hooks/
   - Personalizar todo para el repo (no copia plantillas sin adaptar)
4. El repo queda listo para preparar ejecuciones.

## Paso 3 — Preparar tus tickets

El skill acepta tickets en cualquier formato, pero produce mejores resultados
cuando cada ticket incluye al menos:

- Objetivo claro (qué cambia en el sistema)
- Archivos probables (aunque sean aproximados)
- Tests mínimos (qué debe verificarse)
- Restricciones (qué NO hacer)

No necesitás formato formal — el skill se encarga de estructurar todo.

## Paso 4 — Activar el skill en Cowork

Decile a Cowork algo como:
- "Tengo estos tickets para implementar con Claude Code"
- "Preparar specs para Code"
- "Organizar este batch de features"

El skill te va a guiar por el flujo de 6 pasos:
inventario → orden + cortes → specs → prompt + reglas → artefactos → revisión.

Al final te da una sola línea para pegar en Claude Code:
```
Lee .ai/prompts/[nombre-batch].md y ejecutá todos los tickets.
```

## Paso 5 — Revisar y ajustar el paquete generado

El skill genera un paquete completo para tu repo. Antes de ejecutar,
revisá y ajustá lo que necesites.

---

## Qué se personaliza y cómo

### CLAUDE.md (personalización OBLIGATORIA)

Este es el archivo más importante para personalizar. El skill genera un
borrador basado en tus tickets, pero vos debés verificar y completar:

| Sección | Qué personalizar | Ejemplo |
|---------|-----------------|---------|
| **Qué es** | Descripción de tu proyecto | "Motor de presupuestos para construcción" |
| **Estructura** | Árbol de directorios real | Copiar output de `tree -L 2` |
| **Comandos** | Comandos reales de tu proyecto | `npm test`, `pytest`, `cargo build` |
| **Convenciones** | Tus reglas de código | `snake_case`, imports absolutos, etc. |
| **Reglas de dominio** | Las reglas que Claude viola sin guía | Ver sección abajo |

**Cómo encontrar tus reglas de dominio:**
Pensá en las veces que un asistente de IA te dio resultados incorrectos
porque no entendió una regla implícita de tu negocio/proyecto.
Esas son las reglas que van acá.

**Meta-regla:** Mantener CLAUDE.md bajo 100 líneas. Cada línea debe
existir porque previene un error real. Si una regla nunca ha prevenido
un error, borrarla.

### Agentes custom (DIFERIDO — no instalar de entrada)

Los agentes custom NO se crean upfront. Se instalan después de la primera
ejecución, solo si la evidencia lo justifica.

**Señales de que necesitás un agente custom (las detecta /learn):**
- El mismo tipo de error se repitió 3+ veces en el mismo dominio
- Claude confunde reglas entre subsistemas diferentes
- Hay "gotchas" de dominio que CLAUDE.md no logra prevenir

**Cómo crearlos cuando sea el momento:**
1. Copiar el patrón de `references/agent-patterns.md` que más se ajuste
2. Reemplazar `[dominio]`, `[proyecto]`, archivos clave
3. Agregar las reglas específicas extraídas de las lecciones de `/learn`
4. Guardar en `.claude/agents/` de tu repo

### Hook Stop (DIFERIDO — instalar si hay evidencia)

El hook anti-racionalización se instala solo si durante la ejecución
Claude declara "listo" con trabajo incompleto. `/learn` detecta esto
y lo sugiere.

Cuando sea el momento, viene en dos versiones (ver `templates/stop-hook.md`):

| Versión | Cuándo usar |
|---------|------------|
| **Básica** | Primer intento — detecta lenguaje de racionalización |
| **Extendida** | Si la básica no es suficiente — también verifica tests y archivos |

**Cómo ajustar sensibilidad:**
- Si el hook bloquea demasiado (falsos positivos), removí la detección
  de frases como "mostly done" del prompt
- Si el hook deja pasar trabajo incompleto, agregá frases específicas
  de tu dominio que Claude usa para racionalizar

### /retrospective (instalar después de la primera ejecución)

Complementa a `/learn` con una vista panorámica. Mientras `/learn` captura
lecciones en caliente después de cada ticket, `/retrospective` analiza
múltiples sesiones pasadas para encontrar patrones que no se ven
ticket por ticket.

Instalar `commands/retrospective.md` en `.claude/commands/` después
de la primera ejecución completa. Correrlo cada 2-3 ejecuciones.

### Specs (se generan por ticket, no se personalizan manualmente)

El skill genera los specs automáticamente. Pero podés influir en su
calidad dándole mejor input:

- Cuanto más específicos tus tickets → mejores specs
- Si mencionás archivos exactos → el spec los incluye
- Si das ejemplos concretos → el spec los convierte en tests

### Prompt + .ai/rules.md (ajustes menores)

El prompt es lean (~1-2K tokens) — solo lista los tickets y apunta
a sus specs. Las reglas viven en `.ai/rules.md` que el orquestador
lee de disco. Lo que podrías ajustar:

- **Punto de corte:** Si sabés que ciertos tickets son más pesados,
  podés mover el punto de corte para que caiga antes de ellos
- **Comando de tests:** Asegurate de que el comando de tests global
  sea correcto en `.ai/rules.md`

### Comandos /learn, /next-ticket, /status (generalmente no se tocan)

Estos comandos son genéricos y funcionan con cualquier proyecto.
La única personalización útil sería agregar verificaciones específicas
a `/learn` si hay patrones de error recurrentes en tu proyecto.

---

## Auditoría recursiva contra meta

El loop recursivo permite que el orquestador audite, escriba specs para
cerrar gaps, e implemente — todo autónomamente hasta que el sistema esté
completo según la visión de alto nivel (el "meta").

### Definir el meta

El meta es un documento que describe QUÉ debe hacer el sistema, no CÓMO.
Cada capacidad tiene un criterio verificable por un agente.

1. Decile a Cowork: "Quiero definir el meta de este proyecto"
2. El skill te guía con preguntas para extraer dominios y capacidades
3. Resultado: `.ai/meta.md` con capacidades verificables y parámetros del loop

O crealo manualmente siguiendo `templates/meta-template.md`.

### Ejecutar el loop

```bash
claude
# Pegar: /recursive-audit
# O: Lee .ai/meta.md y ejecutá auditoría recursiva.
```

El loop:
1. **Audita** código vs meta → encuentra gaps
2. **Analiza** y prioriza los gaps
3. **Genera specs** para cerrar los gaps
4. **Implementa** usando el orquestador existente
5. **Repite** hasta: gaps = 0, max iterations, o diminishing returns

### Parámetros configurables (en .ai/meta.md)

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| max_iterations | 3 | Máximo de ciclos |
| coverage_threshold | 90% | % para considerar FIN |
| diminishing_returns | 2 | Si cierra < N gaps en un ciclo → FIN |
| priority_cutoff | Media | Hasta qué prioridad auditar |
| audit_split | single | 1 o 2 auditores paralelos |

---

## Ejemplo: flujo completo con un proyecto Node.js

```bash
# 1. BOOTSTRAP (una sola vez)
#    Abrir Cowork con acceso a mi-api-node/
#    Decir: "Instalar harness en este repo"
#    Cowork detecta: npm test, ESLint, TypeScript strict
#    Cowork instala: CLAUDE.md, commands, settings.json, hooks

# 2. PREPARAR TICKETS (cada vez que hay trabajo)
#    En la misma sesión o en una nueva con mi-api-node/
#    Decir: "Tengo estos 5 tickets: [pegar tickets]"
#    El skill genera specs, preflight, prompt + rules.

# 3. EJECUCIÓN
cd mi-api-node
claude
# Pegar: Lee .ai/prompts/auth-flow.md y ejecutá todos los tickets.
# Claude Code ejecuta autónomamente: una rama, commits atómicos, un PR.
```

## Ejemplo: flujo con proyecto Python

```bash
# Bootstrap: Cowork detecta pytest, ruff, mypy
# CLAUDE.md incluye: snake_case, type hints, reglas de dominio
# Mismo flujo de preparación y ejecución
```

---

## Flujo de vida del sistema

```
Primera ejecución (mínimo viable):
  Tickets → Cowork (skill) → Specs + CLAUDE.md mínimo + prompt lean → Claude Code
  Una rama, commits atómicos por ticket, un PR.
  Después de cada ticket: /learn captura lecciones y enriquece CLAUDE.md
  Al terminar: /learn sugiere si hacen falta agentes custom o hooks

Post primera ejecución (evolución guiada):
  /retrospective analiza las sesiones
  Instalar agentes custom SI /learn detectó errores repetidos por dominio
  Instalar hook Stop SI Claude declaró victoria prematura
  Instalar /retrospective para análisis periódico

Ejecuciones siguientes:
  Nuevos tickets → Cowork (skill) → Nuevos specs → Claude Code
  CLAUDE.md ya tiene reglas probadas en batalla
  La infraestructura crece solo cuando la evidencia lo justifica

Mantenimiento periódico:
  /retrospective cada 2-3 ejecuciones para vista panorámica
  /learn después de cada ticket para captura en caliente
  Meta-regla: si CLAUDE.md pasa de 100 líneas, consolidar
```

## Troubleshooting

**Claude Code ignora el spec y hace lo que quiere**
→ El spec probablemente es ambiguo. Revisá que tenga rutas exactas,
  pasos concretos, y restricciones claras.

**El orquestador se queda sin contexto antes de terminar**
→ Cuando Claude te pida correr `/compact`, ejecutá el comando vos
  directamente en la terminal de Claude Code (es un comando del usuario,
  no algo que Claude pueda correr solo). Si ya es muy tarde, ejecutá
  `/clear` vos y pegá la misma línea de ejecución — Claude retoma
  automáticamente leyendo `.ai/runs/results.tsv`.

**El hook Stop bloquea todo**
→ Bajá la sensibilidad removiendo frases del prompt del hook.
  O usá la versión básica en vez de la extendida.

**Un subagente falla a mitad de un ticket**
→ Claude Code lo reporta en el resumen del orquestador. Los cambios
  hasta el último commit atómico están salvados. Podés corregir
  manualmente en el contexto principal, o ejecutá `/next-ticket`
  para saltar al siguiente y volver al fallido después.

**Quiero agregar más tickets a mitad de ejecución**
→ No modifiqués el prompt activo. Terminá la ejecución actual y
  generá un nuevo batch con los tickets adicionales.

**¿`.ai/runs/results.tsv` y `.ai/done-tasks.md` se commitean o se ignoran?**
→ Commitealos. `.ai/runs/results.tsv` es el tracking estructurado que permite
  retomar después de `/clear`. `.ai/done-tasks.md` tiene las lecciones
  narrativas que `/retrospective` analiza. Si trabajás en equipo,
  ambos permiten ver el progreso.

**Quiero revertir un solo ticket sin afectar al resto**
→ Cada ticket tiene un commit atómico con el número de ticket:
  `git log --oneline --grep="T-[N]"` para encontrarlo,
  `git revert [hash] --no-edit` para revertirlo.
