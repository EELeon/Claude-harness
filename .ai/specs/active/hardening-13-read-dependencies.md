# hardening-13 — Campo de dependencias de lectura en spec template

## Objetivo

Agregar sección "Archivos de lectura (dependencias implícitas)" al spec template, entre el scope fence y los archivos a modificar. Esto permite al orquestador detectar dependencias entre tickets que no se solapan en escritura pero sí en lectura.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/spec-template.md`

### Archivos prohibidos
- `templates/orchestrator-prompt.md` — fuera de alcance (no necesita cambio para esto)
- `references/concurrency-classes.md` — fuera de alcance

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/spec-template.md` | Agregar sección de dependencias de lectura |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/spec-template.md`. Localizar la línea `---` que separa el scope fence de "## Archivos a modificar".

2. Insertar ANTES de "## Archivos a modificar" (después del cierre del scope fence):

```markdown
## Archivos de lectura (dependencias implícitas)

<!--
Archivos que este ticket LEE pero NO modifica.
Listar aquí permite al orquestador detectar dependencias ocultas:
si Ticket A lee `events.py` y Ticket B lo modifica, A no debería
correr en paralelo con B (aunque sus scope fences de ESCRITURA no se solapen).

Solo listar archivos que otros tickets del sprint podrían modificar.
No listar archivos estables como CLAUDE.md o librerías externas.

Si no hay dependencias de lectura relevantes, escribir "Ninguna".
-->

- `ruta/archivo_que_lee.py` — [qué dato lee de este archivo]
- Ninguna
```

3. En el "## Checklist de autocontención" al final del template, agregar un check:

Después de `- [ ] ¿Tiene scope fence (archivos permitidos + prohibidos)?`, agregar:
```
- [ ] ¿Tiene dependencias de lectura listadas (o "Ninguna" explícito)?
```

4. Commit: `"feat(hardening-13): campo de dependencias de lectura en spec template"`

---

## Tests que deben pasar

```bash
grep "Archivos de lectura" templates/spec-template.md
# Debe retornar al menos 1 línea (título de sección)

grep "dependencias implícitas" templates/spec-template.md
# Debe retornar al menos 1 línea

grep "dependencias de lectura" templates/spec-template.md
# Debe retornar al menos 2 líneas (sección + checklist)
```

- [ ] `grep_section`: La sección "Archivos de lectura" existe
- [ ] `grep_implicit`: Se explica el concepto de dependencias implícitas
- [ ] `grep_checklist`: El checklist incluye verificación de dependencias de lectura

## Criterios de aceptación

- [ ] La sección existe entre scope fence y archivos a modificar
- [ ] Hay comentario HTML explicando el propósito y cuándo listar
- [ ] El ejemplo muestra el formato esperado
- [ ] El checklist de autocontención incluye la verificación
- [ ] Se puede escribir "Ninguna" cuando no hay dependencias de lectura

## NO hacer

- NUNCA hacer esta sección obligatoria en el preflight — es informativa para el orquestador
- NUNCA agregar lógica de scheduling automático basada en esta sección — es input para decisión humana
- NUNCA mover la sección a un lugar diferente al especificado (entre scope fence y archivos a modificar)
