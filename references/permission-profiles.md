# Perfiles de permiso del orquestador

Los perfiles configuran el nivel de autonomía del orquestador durante la ejecución.
El perfil se define en `.ai/plan.md` y se lee al inicio del sprint.
Si no hay perfil definido, usar `standard` como default.

## Tabla comparativa

| Aspecto | conservative | standard | aggressive |
|---------|-------------|----------|------------|
| Auto-merge si tests pasan | No — siempre pedir revisión | No | Sí |
| Rollback en scope warning | Sí — tratar warnings como errors | No — solo en violations | No — ignorar warnings |
| Max intentos de fix por ticket | 1 | 2 | 3 |
| /simplify obligatorio | Sí (todos los tickets) | Solo Media/Alta | No |
| Cleanup automático post-sprint | No — usuario confirma | Sí | Sí + borrar branches |
| Batch paralelo | No — siempre secuencial | Sí (si batch-eligible) | Sí + más agresivo en eligibilidad |
| Anti-racionalización hook | Obligatorio | Recomendado | Opcional |
| Punto de corte | Cada 2 tickets | Cada 3-4 tickets | Cada 5-6 tickets |

## Guía de selección

- **conservative**: producción, repos con CI estricto, primera ejecución en un repo nuevo
- **standard**: desarrollo activo, repos conocidos, sprints regulares
- **aggressive**: prototipos, refactorings masivos, repos experimentales

## Cómo funciona

El orquestador lee el perfil del plan de ejecución al inicio y ajusta su comportamiento
según la tabla. No requiere cambios en hooks ni settings — es puramente lógica del prompt.

### Ejemplo de uso en `.ai/plan.md`

```
Perfil de permiso: `standard`
```

### Interacción con las reglas de orquestación

- **Regla 2 (rollback):** El perfil modifica el número de intentos de fix
  y cómo se tratan los scope warnings.
- **Regla 5 (puntos de corte):** El perfil define la frecuencia de los cortes.
- **Regla 8 (/simplify):** El perfil determina si /simplify es obligatorio,
  opcional por complejidad, o desactivado.
- **Regla 9 (/batch):** El perfil controla la elegibilidad para ejecución paralela.
