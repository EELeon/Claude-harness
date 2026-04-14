# Guía de project_notes/ — Conocimiento estático del proyecto

## Qué es

El directorio `.ai/docs/project_notes/` almacena conocimiento no-efímero del proyecto: bugs conocidos, decisiones arquitectónicas, hechos clave, e issues abiertos. Complementa la experience library (conocimiento destilado de ejecuciones) con conocimiento estático que no cambia entre sprints.

## Estructura

```
.ai/docs/project_notes/
├── bugs.md          # Bugs conocidos no resueltos — con severidad y workaround
├── decisions.md     # Decisiones arquitectónicas del proyecto (complementa .ai/decisions/)
├── key_facts.md     # Hechos clave: constraints externos, dependencias, límites técnicos
└── issues.md        # Issues abiertos no cubiertos por specs actuales
```

## Convenciones por archivo

### bugs.md

```markdown
### [BUG-N] — [Título]
- **Severidad:** alta | media | baja
- **Descripción:** [Qué falla]
- **Workaround:** [Cómo evitarlo mientras no se resuelve]
- **Archivos afectados:** [rutas]
- **Reportado:** [fecha]
```

### decisions.md

```markdown
### [ADR-N] — [Título]
- **Estado:** aceptada | superseded | deprecated
- **Contexto:** [Por qué se tomó esta decisión]
- **Decisión:** [Qué se decidió]
- **Consecuencias:** [Qué implica para el proyecto]
```

### key_facts.md

```markdown
### [Categoría]
- [Hecho concreto con fuente/referencia]
```

### issues.md

```markdown
### [ISSUE-N] — [Título]
- **Prioridad:** alta | media | baja
- **Descripción:** [Qué necesita resolverse]
- **Bloqueado por:** [dependencia externa, decisión pendiente, etc.]
```

## Diferencia con otros archivos del harness

| Archivo | Propósito | Ciclo de vida |
|---------|-----------|---------------|
| `done-tasks.md` | Registro cronológico de ejecuciones | Efímero por sprint |
| `.ai/experience/` | Insights destilados de ejecuciones | Evolucionan con ADD/MERGE/PRUNE |
| `.ai/decisions/` | Decisiones tomadas durante sprints específicos | Por batch |
| `project_notes/` | Conocimiento estático del proyecto | Actualizado manualmente, no por el orquestador |

## Quién lo mantiene

El usuario, con ayuda de `/learn` que puede sugerir agregar entradas. El orquestador NO modifica project_notes — solo los lee como contexto.

## Cuándo crear los archivos

Los archivos se crean cuando hay contenido real. NUNCA pre-crear archivos vacíos.
