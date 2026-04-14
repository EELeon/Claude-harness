# Clases de ejecución — Taxonomía de concurrencia

## Tabla de clases

| Clase | Definición | Regla de scheduling | Ejemplo |
|-------|-----------|---------------------|---------|
| `read_only` | El ticket NO modifica archivos del repo. Solo lee, analiza, o genera output fuera del árbol (reportes, auditorías). | Paralelo libre: puede correr simultáneamente con cualquier otro ticket, sin restricciones. | Auditoría de código, generación de documentación externa, análisis de dependencias. |
| `isolated_write` | El ticket modifica archivos que NINGÚN otro ticket del sprint toca. El scope fence no se solapa con ningún otro spec activo. | Paralelo en worktree: puede correr en paralelo usando worktrees de git, ya que no hay conflictos posibles. | Agregar un nuevo módulo independiente, crear tests para un archivo que nadie más modifica. |
| `shared_write` | El ticket modifica al menos un archivo que OTRO ticket del sprint también modifica. Hay solapamiento en los scope fences. | Secuencial estricto: NUNCA ejecutar en paralelo con el ticket que comparte archivos. Respetar el orden de dependencias. | Dos tickets que ambos modifican `config.py`, tickets que tocan el mismo template. |
| `repo_wide` | El ticket modifica configuración global, hooks, CI, o archivos que afectan a TODO el repositorio. Cambios con efecto transversal. | Sesión principal: ejecutar solo en la sesión principal, sin otros tickets corriendo. Requiere atención exclusiva del orquestador. | Cambiar `.claude/settings.json`, modificar hooks de git, actualizar `CLAUDE.md`, cambiar estructura de directorios. |

## Árbol de decisión: cómo clasificar un ticket

```
¿El ticket modifica archivos del repo?
├── NO → read_only
└── SÍ → ¿Algún archivo del scope fence aparece en otro spec activo?
    ├── NO → ¿Modifica configuración global o archivos transversales?
    │   ├── NO → isolated_write
    │   └── SÍ → repo_wide
    └── SÍ → shared_write
```

### Reglas de clasificación

1. SIEMPRE verificar el scope fence contra todos los demás specs activos del sprint
2. Si hay DUDA entre `isolated_write` y `shared_write`, elegir `shared_write` (más conservador)
3. Archivos en `### Archivos condicionales` cuentan como posible solapamiento
4. `repo_wide` tiene prioridad: si el ticket toca archivos globales, es `repo_wide` aunque también toque archivos aislados

## Ejemplos de tickets reales por clase

### `read_only`
- Generar reporte de cobertura de tests sin modificar código
- Auditar specs contra meta (recursive-audit)
- Validar estructura de archivos existentes (preflight)

### `isolated_write`
- Crear un nuevo archivo de referencia que ningún otro ticket toca
- Agregar tests para un módulo que no está en scope de otros tickets
- Implementar un comando nuevo sin dependencias compartidas

### `shared_write`
- Dos tickets que ambos agregan campos al mismo template
- Un ticket que modifica un archivo de referencia que otro ticket también edita
- Tickets que agregan validaciones al mismo comando de preflight

### `repo_wide`
- Modificar `CLAUDE.md` del repositorio
- Cambiar hooks de pre-commit o post-commit
- Reestructurar directorios del proyecto
- Actualizar `settings.json` o configuración de CI

## Protocolo de integración post-worktree

Cuando tickets `isolated_write` o `shared_write` se ejecutan en worktrees paralelos,
sus commits deben integrarse al branch del sprint. Este protocolo define cómo.

Ver Regla 10 en `templates/orchestrator-prompt.md` para las reglas detalladas de cherry-pick.

### Para `isolated_write` (paralelo en worktree)

1. Crear worktree desde HEAD del branch del sprint (NUNCA desde main)
2. Subagente ejecuta y hace commit en el worktree
3. Cherry-pick al branch del sprint: `git cherry-pick [hash]`
4. Si no hay conflicto → OK
5. Si hay conflicto (raro para isolated_write, pero posible en archivos transversales
   como imports o __init__.py) → resolver preservando HEAD + agregar líneas nuevas
6. Correr tests después del cherry-pick

### Para `shared_write` (secuencial estricto)

Los tickets `shared_write` NO deben ejecutarse en worktrees paralelos.
Se ejecutan secuencialmente en la sesión principal. Si por error se ejecutan
en paralelo y hay colisión, aplicar situación #9 de `references/recovery-matrix.md`.

### Antipatrón: `--theirs` en cherry-pick

NUNCA resolver conflictos con `git cherry-pick --theirs`. Esto reemplaza el archivo
completo con la versión del worktree, perdiendo todos los cambios que tickets
anteriores del sprint ya integraron al branch. Esta es la causa más frecuente
de regresiones silenciosas en sprints multi-ticket.
