# hardening-04 — Situación de cherry-pick conflict en recovery matrix

## Objetivo

Agregar la situación #10 "Cherry-pick conflict en archivo compartido" a `references/recovery-matrix.md`, documentando señales de detección, pasos de recuperación, y ejemplo concreto.

## Complejidad: Simple

## Dependencias

- Requiere: hardening-01 (la situación referencia la Regla 10)
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: isolated_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/recovery-matrix.md`

### Archivos prohibidos
- `templates/orchestrator-prompt.md` — lo cubren hardening-01 y hardening-02

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `references/recovery-matrix.md` | Agregar situación #10 a la tabla y su detalle |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `references/recovery-matrix.md` completo.
2. En la tabla "## Tabla de situaciones", agregar fila #10:

```
| 10 | Cherry-pick conflict | Cherry-pick retorna conflicto en archivo compartido | `resolve` | Abort, resolver manual preservando HEAD, tests post-merge |
```

3. Agregar la sección de detalle después de la sección "### 9. Batch con colisión":

```markdown
### 10. Cherry-pick conflict — `resolve`

**Señales de detección:**
- `git cherry-pick [hash]` retorna conflicto (exit code ≠ 0)
- Archivos en conflicto son archivos que otros tickets del sprint ya tocaron
- El worktree tiene una versión divergente del archivo (basado en un commit anterior)

**Pasos exactos:**
1. Ejecutar `git cherry-pick --abort` para cancelar el cherry-pick
2. Ejecutar `git cherry-pick --no-commit [hash]` para aplicar sin commit
3. Para CADA archivo en conflicto:
   a. Si el archivo fue tocado por un ticket anterior del sprint →
      resolver preservando HEAD y agregando solo las líneas nuevas del worktree
   b. Si el archivo NO fue tocado por tickets anteriores →
      aceptar la versión del worktree: `git checkout --theirs -- [archivo]`
   c. Si el archivo está fuera del scope del ticket →
      descartar: `git checkout HEAD -- [archivo]`
4. Después de resolver todos los conflictos: `git add -A && git commit`
5. Correr tests ANTES de continuar con el siguiente cherry-pick
6. Si los tests fallan después de la resolución → el merge fue incorrecto:
   `git reset --hard HEAD~1` y repetir desde paso 2 con más cuidado

**Ejemplo concreto:** El ticket B3c migra `close_engagement.py` a beta contract
en un worktree. Pero el worktree se creó desde main, no desde el sprint branch.
Al hacer cherry-pick, hay conflicto porque B3a ya modificó el import section.
Resolución: preservar HEAD (que tiene los imports de B3a) y agregar solo el
código nuevo de B3c. NUNCA usar `--theirs` que borraría los cambios de B3a.
```

4. En la tabla "## Referencia rápida de acciones", agregar fila:

```
| `resolve` | Resolver conflicto manual | Cuando cherry-pick tiene conflictos en archivos compartidos |
```

5. Commit: `"feat(hardening-04): situación cherry-pick conflict en recovery matrix"`

---

## Tests que deben pasar

```bash
grep "Cherry-pick conflict" references/recovery-matrix.md
# Debe retornar al menos 2 líneas (tabla + detalle)

grep "resolve" references/recovery-matrix.md | grep -c "Cherry-pick\|conflicto manual"
# Debe retornar >= 2
```

- [ ] `grep_situation`: La situación #10 existe en la tabla y tiene detalle
- [ ] `grep_action`: La acción "resolve" aparece en la referencia rápida

## Criterios de aceptación

- [ ] La tabla tiene fila #10 con la situación de cherry-pick conflict
- [ ] El detalle incluye pasos exactos de resolución
- [ ] Hay un ejemplo concreto basado en evidencia real
- [ ] La referencia rápida incluye la acción `resolve`
- [ ] El formato es consistente con las situaciones 1-9 existentes

## NO hacer

- NUNCA modificar las situaciones 1-9 existentes
- NUNCA cambiar el formato de la tabla
