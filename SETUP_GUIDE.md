# Guía de implementación — Code Orchestrator

Cómo instalar y personalizar este sistema en cualquier repositorio.

## Requisitos previos

- Claude Code instalado y funcionando
- Un repositorio git con al menos un commit
- Tickets/tareas definidos (pueden ser informales)

## Paso 1 — Instalar el skill en Cowork

El skill `code-orchestrator` se instala en la carpeta de skills de Cowork:

```
~/.claude/skills/code-orchestrator/
├── SKILL.md                              # Orquestador principal
├── templates/
│   ├── spec-template.md                  # Template para specs de tickets
│   ├── orchestrator-prompt.md            # Template para mega-prompts
│   ├── execution-plan-template.md        # Template para plan de ejecución
│   ├── claudemd-template.md              # Template para CLAUDE.md
│   └── stop-hook.md                      # Template para hook anti-racionalización
├── references/
│   ├── subagent-sizing.md                # Reglas de división en subtareas
│   └── agent-patterns.md                 # Patrones de agentes custom
└── commands/
    ├── learn.md                          # Comando /learn
    ├── next-ticket.md                    # Comando /next-ticket
    └── status.md                         # Comando /status
```

Copiar toda la carpeta a la ubicación de skills.

## Paso 2 — Preparar tus tickets

El skill acepta tickets en cualquier formato, pero produce mejores resultados
cuando cada ticket incluye al menos:

- Objetivo claro (qué cambia en el sistema)
- Archivos probables (aunque sean aproximados)
- Tests mínimos (qué debe verificarse)
- Restricciones (qué NO hacer)

No necesitás formato formal — el skill se encarga de estructurar todo.

## Paso 3 — Activar el skill en Cowork

Decile a Cowork algo como:
- "Tengo estos tickets para implementar con Claude Code"
- "Preparar specs para Code"
- "Organizar este sprint de desarrollo"

El skill te va a guiar por el flujo de 6 pasos:
inventario → sprints → specs → mega-prompt → artefactos → revisión.

## Paso 4 — Revisar y ajustar el paquete generado

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

### Agentes custom (personalización OPCIONAL)

Solo crear agentes custom si tu proyecto tiene dominios diferenciados
con reglas que Claude viola sistemáticamente.

**Cuándo SÍ crear:**
- Proyecto con 3+ subsistemas independientes (ej: backend, frontend, infra)
- Cada subsistema tiene reglas de dominio que Claude confunde entre sí
- Vas a ejecutar 3+ tickets del mismo dominio

**Cuándo NO crear:**
- Proyecto pequeño con un solo dominio
- Las reglas ya están bien cubiertas en CLAUDE.md
- Los specs son suficientemente detallados

**Cómo personalizar un agente:**
1. Copiar el patrón de `references/agent-patterns.md` que más se ajuste
2. Reemplazar `[dominio]`, `[proyecto]`, archivos clave
3. Agregar las reglas específicas de tu dominio
4. Guardar en `.claude/agents/` de tu repo

### Hook Stop (personalización RECOMENDADA)

El hook anti-racionalización viene en dos versiones (ver `templates/stop-hook.md`):

| Versión | Cuándo usar |
|---------|------------|
| **Básica** | Proyectos nuevos donde no sabés qué errores esperar |
| **Extendida** | Proyectos con specs estructurados y tests definidos |

**Cómo ajustar sensibilidad:**
- Si el hook bloquea demasiado (falsos positivos), removí la detección
  de frases como "mostly done" del prompt
- Si el hook deja pasar trabajo incompleto, agregá frases específicas
  de tu dominio que Claude usa para racionalizar

### Specs (se generan por ticket, no se personalizan manualmente)

El skill genera los specs automáticamente. Pero podés influir en su
calidad dándole mejor input:

- Cuanto más específicos tus tickets → mejores specs
- Si mencionás archivos exactos → el spec los incluye
- Si das ejemplos concretos → el spec los convierte en tests

### Mega-prompt (se genera por sprint, ajustes menores)

El mega-prompt se genera automáticamente por sprint. Lo único que
podrías querer ajustar:

- **Punto de corte:** Si sabés que ciertos tickets son más pesados,
  podés mover el punto de corte para que caiga antes de ellos
- **Comando de tests:** Asegurate de que el comando de tests global
  sea correcto para tu proyecto

### Comandos /learn, /next-ticket, /status (generalmente no se tocan)

Estos comandos son genéricos y funcionan con cualquier proyecto.
La única personalización útil sería agregar verificaciones específicas
a `/learn` si hay patrones de error recurrentes en tu proyecto.

---

## Ejemplo: instalar en un proyecto Node.js

```bash
# 1. El skill ya está en Cowork

# 2. En Cowork, decí:
#    "Tengo estos 5 tickets para mi API de Node.js: [pegar tickets]"

# 3. El skill genera el paquete. Verificá CLAUDE.md:
#    - Comandos: npm test, npm run lint
#    - Convenciones: camelCase, ESM imports, TypeScript strict
#    - Reglas: "Nunca usar any", "Handlers siempre retornan Response"

# 4. Copiar los archivos generados a tu repo:
cp -r specs/ /ruta/a/tu/repo/
cp CLAUDE.md EXECUTION_PLAN.md /ruta/a/tu/repo/
cp -r .claude/ /ruta/a/tu/repo/

# 5. Ejecutar en Claude Code:
cd /ruta/a/tu/repo
git checkout -b sprint-a-nombre
claude
# Pegar el mega-prompt del Sprint A
```

## Ejemplo: instalar en un proyecto Python

```bash
# Mismos pasos, pero CLAUDE.md tendría:
#   - Comandos: pytest, ruff check, mypy
#   - Convenciones: snake_case, type hints, docstrings numpy-style
#   - Reglas: según tu dominio
```

---

## Flujo de vida del sistema

```
Primera vez:
  Tickets → Cowork (skill) → Specs + CLAUDE.md + mega-prompt → Claude Code

Sprints siguientes:
  Nuevos tickets → Cowork (skill) → Nuevos specs → Claude Code
  (CLAUDE.md ya existe y se enriquece con /learn después de cada ticket)

Mantenimiento:
  /learn actualiza CLAUDE.md automáticamente después de cada ticket
  Las reglas se acumulan y Claude cada vez comete menos errores
```

## Troubleshooting

**Claude Code ignora el spec y hace lo que quiere**
→ El spec probablemente es ambiguo. Revisá que tenga rutas exactas,
  pasos concretos, y restricciones claras.

**El mega-prompt se queda sin contexto antes de terminar**
→ Cuando Claude te pida correr `/compact`, ejecutá el comando vos
  directamente en la terminal de Claude Code (es un comando del usuario,
  no algo que Claude pueda correr solo). Si ya es muy tarde, ejecutá
  `/clear` vos y pegá el mega-prompt de nuevo — Claude retoma
  automáticamente leyendo `done-tasks.md`.

**El hook Stop bloquea todo**
→ Bajá la sensibilidad removiendo frases del prompt del hook.
  O usá la versión básica en vez de la extendida.

**Un subagente falla a mitad de un ticket**
→ Claude Code lo reporta en el resumen del orquestador. Los cambios
  hasta el último commit atómico están salvados. Podés corregir
  manualmente en el contexto principal, o ejecutá `/next-ticket`
  para saltar al siguiente y volver al fallido después.

**Quiero agregar más tickets a mitad de un sprint**
→ No modifiqués el mega-prompt activo. Agregá los tickets nuevos al
  siguiente sprint, o creá un mini-sprint adicional.

**¿`done-tasks.md` se commitea o se ignora?**
→ Commitealo. Sirve como registro de progreso y permite que `/learn`
  y `/status` funcionen entre sesiones. Si trabajás en equipo,
  cada persona puede ver qué tickets ya se completaron.
