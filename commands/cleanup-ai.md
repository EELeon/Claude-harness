# Limpieza de .ai/ + migración de hook destructivo

Escaneá la carpeta `.ai/` del repo actual, organizala según la estructura canónica,
y migrar el hook PreToolUse de one-liner inline a script externo.

---

## PARTE 1: Organizar .ai/

### Estructura objetivo

```
.ai/
├── standards/           # Harness de auditoría — NO tocar
├── specs/
│   ├── active/          # Specs del batch en curso (si hay)
│   └── archive/
│       └── [nombre]/    # Un folder por batch pasado
├── runs/
│   └── results.tsv      # Solo si hay ejecución en curso
├── prompts/             # Un .md por batch (permanente)
│   └── [nombre-batch].md
├── rules.md             # Solo si hay ejecución en curso
├── plan.md              # Solo si hay ejecución en curso
└── done-tasks.md        # Acumulativo — NUNCA borrar
```

### Paso 1: Inventario

Corré `find .ai/ -type f` y clasificá cada archivo:

| Categoría | Criterio | Acción |
|-----------|----------|--------|
| **En su lugar** | Ya está en la ruta correcta | No tocar |
| **Reubicable** | Artefacto válido en ruta incorrecta | Mover |
| **Huérfano** | No corresponde a ninguna categoría | → `.ai/_orphans/` |
| **Basura** | Temporales, duplicados, nombres sin sentido | Listar para borrar |

Reglas de clasificación:
- Archivos con headings Objetivo/Scope fence/Tests → specs → `.ai/specs/active/` o `.ai/specs/archive/[nombre-batch]/`
- Archivos con "Setup inicial" + tabla de tickets → prompts → `.ai/prompts/[nombre-batch].md`
- `rules.md` → `.ai/rules.md`
- `plan.md` → `.ai/plan.md`
- `done-tasks.md` → `.ai/done-tasks.md`
- `results.tsv` → `.ai/runs/results.tsv`

**Presentá la tabla ANTES de mover nada. Esperá confirmación.**

### Paso 2: Crear estructura y mover

```bash
mkdir -p .ai/specs/active .ai/specs/archive .ai/runs .ai/prompts
```

Para cada archivo reubicable, mostrá `origen → destino` y ejecutá `mv`.
Huérfanos van a `mkdir -p .ai/_orphans && mv [archivo] .ai/_orphans/`.

---

## PARTE 2: Migrar hook PreToolUse

### Paso 3: Detectar hook actual

Leé `.claude/settings.json`. Si tiene un hook PreToolUse con command inline
tipo `bash -c "CMD=$(cat | jq ...` → necesita migración.

Si no tiene hook PreToolUse o ya apunta a un script externo → saltar esta parte.

### Paso 4: Crear script externo

```bash
mkdir -p .claude/hooks
cat > .claude/hooks/guard-destructive.sh << 'SCRIPT'
#!/usr/bin/env bash
# Guard de comandos destructivos para Claude Code
# Exit 0 = OK, Exit 2 = BLOCK

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$CMD" ]; then
  exit 0
fi

case "$CMD" in
  *'rm -rf /'*|*'rm -rf ~'*)
    echo "BLOCKED: rm -rf en ruta protegida" >&2; exit 2 ;;
  *'git push --force'*|*'git push -f '*)
    echo "BLOCKED: force push" >&2; exit 2 ;;
  *'git clean -fd'*)
    echo "BLOCKED: git clean destructivo" >&2; exit 2 ;;
  *)
    exit 0 ;;
esac
SCRIPT
chmod +x .claude/hooks/guard-destructive.sh
```

### Paso 5: Actualizar settings.json

En `.claude/settings.json`, reemplazá el hook PreToolUse inline con:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/guard-destructive.sh",
      "timeout": 5
    }
  ]
}
```

Conservá el resto del settings.json intacto (otros hooks, permissions, etc).

### Paso 6: Verificar

```bash
echo '{"tool_input":{"command":"echo hello"}}' | .claude/hooks/guard-destructive.sh && echo "PASS: comando normal"
echo '{"tool_input":{"command":"rm -rf /"}}' | .claude/hooks/guard-destructive.sh || echo "PASS: destructivo bloqueado (exit $?)"
```

Ambos deben pasar. Si no, corregir antes de continuar.

---

## PARTE 3: Reporte

Mostrá un resumen final:

```
=== ORGANIZACIÓN .ai/ ===
ANTES:  [N] archivos, [N] fuera de lugar
DESPUÉS: [N] archivos, estructura canónica ✓
MOVIDOS: [lista]
HUÉRFANOS: [lista en .ai/_orphans/]
BASURA: [lista — confirmar para borrar]

=== HOOK PRETOOLUSE ===
ANTES:  one-liner inline en settings.json
DESPUÉS: .claude/hooks/guard-destructive.sh (script externo)
TESTS:  comando normal ✓ | destructivo bloqueado ✓
```
