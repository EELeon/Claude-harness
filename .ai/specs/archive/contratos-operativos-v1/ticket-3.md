# Ticket 3 — Optimización de tokens (configuración y reglas)

## Objetivo

Documentar las mejores prácticas de optimización de tokens basadas en la auditoría de 926 sesiones reales, incluyendo la configuración de ENABLE_TOOL_SEARCH, gestión de cache, y reducción de skills/lecturas redundantes. Agregar las reglas más críticas a CLAUDE.md del repo.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `CLAUDE.md`
- `references/token-optimization.md`

### Archivos prohibidos
- `templates/orchestrator-prompt.md` — lo tocan T-1 y T-4
- `templates/spec-template.md` — lo toca T-2
- `.claude/settings.json` — configuración de hooks, fuera de scope
- `.claude/commands/preflight.md` — lo toca T-2

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/token-optimization.md` | Documento de referencia con hallazgos de la auditoría de 926 sesiones, configuraciones recomendadas, y reglas de eficiencia |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `CLAUDE.md` | Agregar 2-3 reglas críticas de eficiencia de tokens en la sección "Reglas de dominio" |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/token-optimization.md` con estas secciones:
   - **Hallazgos clave** (de la auditoría de 926 sesiones):
     - Tool schema bloat: ~14k-20k tokens de overhead por turno si se cargan todos los schemas. Fix: `ENABLE_TOOL_SEARCH: true` reduce a ~5k
     - Cache expiry: TTL de ~5min en prompt cache de Anthropic. 54%+ de turnos tras pausa >5min = re-procesamiento completo. Fix: `/compact` antes de pausas largas
     - Skills no usadas: auditar periódicamente y deshabilitar las que no se usen
     - Lecturas redundantes: no re-leer archivos que ya están en contexto
   - **Configuraciones recomendadas** con valores exactos y dónde aplicarlas
   - **Reglas para el orquestador**: no re-leer archivos, usar Heat Shield para limitar retorno, puntos de corte cada 3-4 tickets
   - **Métricas de referencia**: antes/después de aplicar cada optimización
2. Leer `CLAUDE.md` y agregar en la sección "Reglas de dominio" (antes de "## NO hacer"):
   - `SIEMPRE usar /compact antes de pausas largas (>5 min) — el cache de Anthropic expira y re-procesa todo el contexto`
   - `NUNCA re-leer un archivo que ya está en el contexto actual — confiar en lo que ya se leyó`
   - Mantener el total de CLAUDE.md bajo 100 líneas después de agregar
3. Verificar que CLAUDE.md sigue siendo ≤100 líneas después de las adiciones
4. Commit: `"feat(T-3): documentar optimización de tokens y agregar reglas de eficiencia"`

## Tests que deben pasar

```bash
# Verificar que el archivo de referencia existe
test -s references/token-optimization.md && echo "PASS" || echo "FAIL"
# Verificar que CLAUDE.md menciona compact o tokens
grep -q "compact\|tokens\|cache" CLAUDE.md && echo "PASS" || echo "FAIL"
# Verificar que CLAUDE.md no excede 100 líneas
LINE_COUNT=$(wc -l < CLAUDE.md)
test "$LINE_COUNT" -le 100 && echo "PASS: $LINE_COUNT lines" || echo "FAIL: $LINE_COUNT lines (max 100)"
```

- [ ] `test_reference_exists`: El archivo `references/token-optimization.md` existe y no está vacío
- [ ] `test_claudemd_rules`: `CLAUDE.md` contiene al menos 1 regla relacionada a tokens/compact/cache
- [ ] `test_claudemd_length`: `CLAUDE.md` tiene ≤100 líneas

## Criterios de aceptación

- [ ] Existe `references/token-optimization.md` con los 3 hallazgos clave documentados
- [ ] El documento incluye configuraciones recomendadas con valores exactos
- [ ] `CLAUDE.md` tiene al menos 2 reglas nuevas de eficiencia de tokens
- [ ] `CLAUDE.md` sigue siendo ≤100 líneas después de las adiciones

## NO hacer

- NUNCA agregar más de 3 reglas a CLAUDE.md — el documento debe mantenerse lean
- NUNCA incluir datos crudos de la auditoría (926 sesiones) — solo conclusiones accionables
- NUNCA recomendar configuraciones que requieran modificar el runtime de Claude Code — solo lo que el usuario puede configurar
- NUNCA borrar reglas existentes de CLAUDE.md para hacer espacio — consolidar si es necesario

---

## Checklist de autocontención

- [x] ¿Tiene scope fence (archivos permitidos + prohibidos)?
- [x] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [x] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [x] ¿Tiene comando exacto de tests?
- [x] ¿Tiene commit message definido?
- [x] ¿Tiene criterios de aceptación observables?
- [x] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [x] ¿Tiene ≤10 restricciones totales?
- [x] ¿No depende de contexto que solo existe en la conversación?
