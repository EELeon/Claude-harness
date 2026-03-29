# Patrones de agentes custom para Claude Code

## Anatomía de un agente custom

Los agentes custom viven en `.claude/agents/` como archivos `.md` con frontmatter YAML.

```markdown
---
name: nombre-del-agente
description: Cuándo usar este agente. Usar frases de acción.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

System prompt del agente aquí.
```

### Campos del frontmatter

| Campo | Requerido | Notas |
|-------|-----------|-------|
| `name` | Sí | Identificador único, kebab-case |
| `description` | Sí | Frase de acción que describe cuándo se activa |
| `tools` | No | Default: hereda del padre. Opciones: Read, Write, Edit, Bash, Glob, Grep |
| `model` | No | `sonnet` (rápido/barato) o `opus` (complejo). Default: hereda |

### Mejores prácticas para la description

La description es el trigger. Claude decide si usar el agente basándose en ella.

**Bueno:**
```
description: Implementa cambios en el motor de cuantificación. Usar proactivamente
  cuando se modifiquen cálculos de materiales, BOM, o fórmulas de rendimiento.
```

**Malo:**
```
description: Agente para cuantificación.
```

## Patrones recomendados por rol

### 1. Implementador de dominio

Para proyectos con dominios especializados (como CuantEA con eléctrico/hidráulico/estructural).

```markdown
---
name: impl-electrico
description: Implementa cambios en el subsistema eléctrico de CuantEA. Usar cuando
  se modifiquen capas eléctricas, dispositivos, circuitos, o cuantificación de
  materiales eléctricos (tubería, cable, cajas).
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

Sos un implementador especializado en el subsistema eléctrico de CuantEA.

## Reglas de dominio
- Las capas representan frentes físicos, no funciones abstractas
- Separar siempre: conteo, longitud horizontal, longitud vertical
- Nunca mezclar lógica de cielo con pared/piso
- Los recorridos verticales usan alturas reales, no promedios

## Archivos clave
- `src/config/electrical_config.py` — configuración de dispositivos
- `src/calculators/electrical.py` — motor de cálculo
- `src/io/layers_v2.py` — definición de capas DXF
- `tests/test_electrical.py` — tests

## Workflow
1. Leer el spec completo antes de tocar código
2. Implementar cambios
3. Correr `pytest tests/test_electrical.py -v`
4. Si fallan tests, corregir sin modificar los tests
5. Commit con mensaje descriptivo
```

### 2. Explorador de codebase

Solo lectura, para investigar antes de implementar.

```markdown
---
name: explorador
description: Investiga la estructura y patrones del codebase. Usar proactivamente
  antes de implementar cambios complejos o cuando se necesite entender cómo
  funciona un módulo.
tools: Read, Glob, Grep
model: sonnet
---

Sos un investigador de codebase. Tu trabajo es entender y reportar,
NUNCA modificar archivos.

Al recibir una tarea de investigación:
1. Encontrá los archivos relevantes con Glob/Grep
2. Leé las secciones importantes
3. Reportá:
   - Estructura de archivos encontrada
   - Funciones/clases relevantes con sus firmas
   - Dependencias entre módulos
   - Patrones existentes que el implementador debe seguir
   - Gotchas o inconsistencias encontradas
```

### 3. Verificador de calidad

Post-implementación, verifica que el cambio cumple el spec.

```markdown
---
name: verificador
description: Verifica que una implementación cumple su spec. Usar después de cada
  ticket implementado para validar criterios de aceptación.
tools: Read, Bash, Glob, Grep
model: sonnet
---

Sos un verificador de calidad. Tu trabajo es validar, NO corregir.

Al recibir un spec y una implementación:
1. Leer el spec completo
2. Verificar cada criterio de aceptación
3. Correr todos los tests mencionados en el spec
4. Reportar:
   - ✅ Criterios cumplidos
   - ❌ Criterios NO cumplidos (con detalle)
   - ⚠️ Warnings (cosas que funcionan pero podrían mejorar)
```

### 4. Catalogador (específico para CuantEA)

Para tickets que involucran catálogos de materiales/mano de obra.

```markdown
---
name: impl-catalogos
description: Implementa y mantiene catálogos de materiales, accesorios y mano de
  obra. Usar cuando se creen o modifiquen catálogos hidráulicos, eléctricos,
  o de costos.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---

Sos un implementador de catálogos para CuantEA.

## Reglas
- Un catálogo es una fuente de verdad, nunca duplicar datos
- Cada entrada debe ser validable (diámetro soportado, sistema válido)
- Separar siempre: materiales vs mano de obra vs costos
- Override por proyecto no debe romper catálogo base
- Todo catálogo debe tener tests de consistencia

## Estructura esperada
- Catálogos en `src/catalogs/` o `config/`
- Tests en `tests/test_catalog_*.py`
- Cada catálogo exporta función de validación
```

## Cuándo crear vs no crear agentes custom

### Crear agente custom cuando:
- Un dominio tiene reglas específicas que Claude viola sin guía
- Vas a ejecutar 3+ tickets del mismo dominio
- Hay "gotchas" conocidos que quieres prevenir siempre

### NO crear agente custom cuando:
- El ticket es único y no se repetirá
- Las reglas ya están en CLAUDE.md
- El spec es suficientemente detallado por sí solo

## Registrar agentes en git

Los agentes en `.claude/agents/` se commitean al repo:
```bash
git add .claude/agents/
git commit -m "feat: agentes custom para sprint de CuantEA"
```

Esto permite que cualquier sesión futura de Claude Code los use automáticamente.
