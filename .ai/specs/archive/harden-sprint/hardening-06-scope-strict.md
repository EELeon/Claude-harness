# hardening-06 — Scope fence estricto: revertir archivos fuera de scope

## Objetivo

Modificar la Regla 2b (auditoría de scope por diff) en `templates/orchestrator-prompt.md` para que los archivos fuera de TODA lista (ni allowlist, ni denylist, ni condicionales) se reviertan automáticamente en vez de solo generar un warning. Actualmente estos archivos pasan con warning, lo que permite que subagentes acumulen cambios fuera de scope sin consecuencia.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

## Clase de ejecución: shared_write

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `references/recovery-matrix.md` — fuera de alcance
- `.ai/rules-v3.md` — instancia vieja

---

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Modificar tabla de clasificación en Regla 2b |

---

## Subtareas

### Implementación directa

**Pasos:**

1. Leer `templates/orchestrator-prompt.md` y localizar la Regla 2b ("Auditoría de scope por diff").
2. En la tabla de clasificación de archivos tocados, cambiar la fila de "No está en ninguna lista":

**Antes:**
```
| No está en ninguna lista | — | — | **WARNING** — registrar pero no bloquear |
```

**Después:**
```
| No está en ninguna lista | — | — | **REVERTIR** — ejecutar `git checkout HEAD -- [archivo]` para descartar los cambios en ese archivo. Registrar en scope_warnings. NO bloquear el ticket completo. |
```

3. Modificar el texto explicativo debajo de la tabla. Cambiar:

**Antes:**
```
- Si hay archivo fuera de toda lista → registrar warning en description de .ai/runs/results.tsv
  pero NO bloquear (el subagente puede haber tocado un test auxiliar legítimamente)
```

**Después:**
```
- Si hay archivo fuera de toda lista → revertir ese archivo específico con
  `git checkout HEAD -- [archivo]` y registrar en scope_warnings.
  Esto preserva los cambios válidos del ticket y descarta solo el exceso.
  NO bloquear el ticket completo — solo limpiar los archivos fuera de scope.
```

4. Commit: `"feat(hardening-06): scope fence estricto — revertir archivos fuera de lista"`

---

## Tests que deben pasar

```bash
grep "REVERTIR" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

grep "git checkout HEAD -- \[archivo\]" templates/orchestrator-prompt.md
# Debe retornar al menos 1 línea

# Verificar que WARNING ya no es la acción para archivos fuera de lista
grep -c "WARNING.*registrar pero no bloquear" templates/orchestrator-prompt.md
# Debe retornar 0
```

- [ ] `grep_revert`: La tabla usa "REVERTIR" en vez de "WARNING" para archivos fuera de lista
- [ ] `grep_checkout`: Hay comando `git checkout HEAD` como acción
- [ ] `grep_no_old_warning`: La frase "registrar pero no bloquear" ya no está

## Criterios de aceptación

- [ ] La tabla de Regla 2b muestra "REVERTIR" para archivos fuera de toda lista
- [ ] El comando de revert es `git checkout HEAD -- [archivo]` (revert por archivo, no rollback total)
- [ ] El ticket NO se bloquea — solo se limpian los archivos excedentes
- [ ] Se registra en scope_warnings del results.tsv

## NO hacer

- NUNCA hacer rollback completo del ticket por archivos fuera de lista — solo revertir esos archivos
- NUNCA cambiar el comportamiento para archivos en denylist (esos siguen siendo BLOQUEANTE → rollback)
- NUNCA modificar el comportamiento de archivos condicionales
