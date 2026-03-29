# Reglas de escritura de specs

Un spec debe permitir que Claude Code ejecute **sin preguntar nada**.
Si Claude Code tiene que "entender" o "explorar" antes de actuar,
el spec está incompleto.

## Límites empíricos para specs efectivos

- Máximo **10 constraints** por spec (más causa omisiones críticas)
- Target ~5000 tokens por spec (>5K = pérdida de fidelidad en instrucciones)
- Forma imperativa en restricciones: "NUNCA X", "SIEMPRE Y"
- Si hay dependencia fuerte con otro ticket, usar patrón Interface-First
  (definir contrato/stub compartido antes de implementar)

## Estructura obligatoria de cada spec

```markdown
# Ticket N — [Título]

## Objetivo (1-2 frases)

## Scope fence
### Archivos permitidos
- `ruta/exacta/archivo.py`
### Archivos prohibidos
- `ruta/config_prod.py` — razón

## Archivos a modificar
- `ruta/exacta/archivo.py` — qué cambiar

## Archivos a crear
- `ruta/exacta/nuevo.py` — qué contiene

## Subtareas (si aplica)
### Subtarea 1 — [nombre]
**Archivos:** [lista]
**Pasos:** [paso a paso concreto]
**Tests:** `[comando exacto]`
**Commit:** `"[tipo]: descripción"`

## Tests que deben pasar
- [ ] Test 1: descripción exacta
- [ ] Test 2: descripción exacta

## Criterios de aceptación
- [ ] Criterio observable 1
- [ ] Criterio observable 2

## NO hacer
- NUNCA [restricción 1 — por qué]
- NUNCA [restricción 2 — por qué]
```

## Referencia

Para la plantilla completa con todos los campos opcionales y
ejemplos detallados, leer `templates/spec-template.md`.
