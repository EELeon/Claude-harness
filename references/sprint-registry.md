# Sprint Registry — Protocolo de trazabilidad

## Propósito

Registrar cada sprint ejecutado para trazabilidad histórica. El registro permite:
- Saber cuántos sprints se han corrido en un repo
- Ver la tasa de keep/discard por sprint
- Identificar tendencias de calidad a lo largo del tiempo
- Encontrar el results.tsv archivado de cualquier sprint

## Ubicación del archivo de datos

```
repo-target/.ai/sprint-registry.md
```

Se crea con el header al ejecutar el primer sprint. Se acumula con cada sprint posterior.

## Formato

```markdown
# Sprint Registry

| Sprint | Rama | Fecha | PR | Tickets | Keep | Discard | Rollbacks | Results |
|--------|------|-------|----|---------|------|---------|-----------|---------|
| hardening-p4 | feat/hardening-p4 | 2026-04-13 | #6 | 13 | 13 | 0 | 0 | .ai/runs/archive/hardening-p4.tsv |
```

### Columnas

1. **Sprint**: Nombre del sprint (el prefix usado en specs)
2. **Rama**: Branch de git
3. **Fecha**: Fecha de creación del PR (YYYY-MM-DD)
4. **PR**: Número del PR (con #)
5. **Tickets**: Total de tickets ejecutados
6. **Keep**: Tickets con status keep
7. **Discard**: Tickets con status discard
8. **Rollbacks**: Total de rollbacks (suma de rollback_count de results.tsv)
9. **Results**: Ruta al results.tsv archivado

## Cuándo registrar

Al terminar todos los tickets de un sprint, DESPUÉS de crear el PR y ANTES
de archivar specs. El orquestador calcula los totales leyendo results.tsv
y agrega una fila al registry.

## Primer sprint en un repo nuevo

Si `.ai/sprint-registry.md` no existe, crearlo con el header markdown antes
de agregar la primera fila.

## Relación con otros artefactos

- `results.tsv` tiene el detalle por ticket → sprint-registry tiene el resumen
- `entrega-sprint.md` define el flujo → sprint-registry es un paso dentro del flujo
- Los specs archivados en `.ai/specs/archive/[sprint]/` complementan el historial
