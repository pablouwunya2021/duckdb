# Ejercicio 5 - Incorporación de datos de 2024

- **SQL de validación:** [`sql/05_validacion_2024.sql`](../sql/05_validacion_2024.sql)
- **Resultados:** [`docs/resultados/05_validacion_2024.md`](resultados/05_validacion_2024.md)
- **Consultas de los Ejercicios 3 y 4 re-ejecutadas sobre 2024 + 2026 sin cambios:**
  [`03_exploracion_2024_2026.md`](resultados/03_exploracion_2024_2026.md),
  [`04_eda_2024_2026.md`](resultados/04_eda_2024_2026.md)
- **Notebook:** [`notebooks/03_incorporacion_anios.ipynb`](../notebooks/03_incorporacion_anios.ipynb)

## 5.1 Modificación del sistema de descarga

El único cambio necesario fue **una línea** en `scripts/download_data.py`:

```diff
-ANIOS = (2026,)
+ANIOS = (2024, 2026)
```

El script ya recibía el año como parámetro desde el Ejercicio 2, de modo que la URL
(`.../trip-data/yellow_tripdata_2024-01.parquet`) y la ruta local
(`data/raw/yellow/2024/...`) se construyen automáticamente. Alternativamente, sin tocar el código:
`python scripts/download_data.py --anio 2024 2026`. Los datos se obtienen directamente de la fuente
oficial de la TLC (CloudFront), no los entrega el docente.

## 5.2 - 5.4 Ejecución

```bash
docker exec lab8-lab python scripts/download_data.py
```

```text
=== YELLOW 2024 ===
  2024-01  listo (47.6 MiB) -> data/raw/yellow/2024/yellow_tripdata_2024-01.parquet
  ...
=== YELLOW 2026 ===
  2026-01  ya existe, se omite
  ...
RESUMEN  (anios: 2024, 2026)
  descargados   : 24        <- solo 2024 (12 yellow + 12 green)
  ya existian   : 16        <- 2026 se conserva y NO se vuelve a descargar (5.2, 5.3)
  no publicados : 8         <- sep-dic 2026
  fallidos      : 0
```

## 5.5 Verificación de los nuevos archivos

| Comprobación | Resultado |
|---|---|
| `download_data.py --verificar` (tamaño local = `Content-Length`) | 40/40 archivos `verificado` |
| `verify_data.py` (lectura de metadatos con DuckDB, huecos) | 40 archivos, 0 ilegibles, 0 meses faltantes, **71,870,407** filas |
| `q5_01_archivos_por_anio` | 2024: 12 yellow + 12 green (ene-dic); 2026: 8 + 8 (ene-ago) |
| `q5_02_registros_metadatos_vs_escaneo` | filas de metadatos = filas en la vista `trips` para cada tipo y año (`coincide = si`) |
| `q5_07_rango_fechas` | tras la limpieza, 2024 cubre 366 días (año bisiesto) del 2024-01-01 al 2024-12-31 |

| tipo | año | archivos | registros | conservados en `trips_clean` |
|---|---|---:|---:|---:|
| yellow | 2024 | 12 | 41,169,720 | 95.01% |
| yellow | 2026 | 8 | 29,703,355 | 93.88% |
| green | 2024 | 12 | 660,218 | 91.88% |
| green | 2026 | 8 | 337,114 | 91.79% |

## 5.6 Consulta conjunta 2024 + 2026

`q5_04_cobertura_mensual` y `q5_08_comparacion_mismo_periodo` consultan ambos años en la misma
sentencia, desde la misma vista y sin `UNION` manual:

| tipo | año | viajes ene-ago | viajes/día | distancia prom. | duración prom. | total prom. |
|---|---|---:|---:|---:|---:|---:|
| yellow | 2024 | 25,127,229 | 102,980 | 3.44 mi | 16.5 min | 28.33 USD |
| yellow | 2026 | 27,884,915 | **114,753** (+11.4%) | 3.55 mi | 17.7 min | **30.18 USD** (+6.5%) |
| green | 2024 | 407,649 | 1,671 | 2.95 mi | 14.6 min | 23.74 USD |
| green | 2026 | 309,437 | **1,273** (−23.8%) | 3.34 mi | 17.1 min | 25.32 USD |

Primeras diferencias visibles: el taxi amarillo **creció** en 2026 mientras el verde **perdió casi
una cuarta parte** de sus viajes diarios.

## 5.7 ¿Hay que modificar las consultas anteriores?

**No fue necesario modificar ninguna consulta.** Las 16 consultas del Ejercicio 3 y las 19 del
Ejercicio 4 se volvieron a ejecutar sobre 2024 + 2026 sin errores (ver reportes `*_2024_2026.md`). Esto
se debe a que:

- las vistas usan globs (`data/raw/yellow/*/*.parquet`), no rutas por año;
- `union_by_name = true` absorbe la diferencia de esquema: 2024 **no tiene** `cbd_congestion_fee`
  (la cuota de congestión de Manhattan empezó el 5 de enero de 2025) ni `request_source`
  (`q5_03`); esas columnas quedan en NULL (`q5_05`);
- las consultas de montos ya usaban `coalesce(cbd_congestion_fee, 0)`;
- las reglas de calidad se expresan respecto a `file_year`/`file_month`, no a fechas fijas, y
  conservan una proporción similar en ambos años (`q5_06`).

Lo que **sí cambia es la interpretación**:

- Las consultas que agregan todo el período (p. ej. `q4_04`, `q4_09`) ahora mezclan años con distinta
  cobertura (12 vs 8 meses). Para comparar años hay que usar **el mismo período** (ene-ago, `q5_08`) o
  métricas por día; por eso los indicadores del Ejercicio 7 se agrupan por `file_year`/mes.
- El porcentaje de pagos desconocidos (`payment_type = 0`) pasó de 9.9% en 2024 a 26.0% en 2026
  (`q5_05`): no es un problema del sistema, sino un cambio real en cómo se registran los viajes (flex fare).
- `q3_15_request_source` filtra `data/raw/*/2026/` a propósito: la columna no existe antes de 2026.
- El perfil `SUMMARIZE` de yellow pasó de 7.8 s a 18.5 s al pasar de 29.7 M a 70.9 M filas: el costo
  crece ~linealmente con el volumen escaneado, un primer indicio para el benchmark del Ejercicio 6.

## 5.8 Consultas utilizadas para validar 2024

Ver [`sql/05_validacion_2024.sql`](../sql/05_validacion_2024.sql): `q5_01` (archivos por año),
`q5_02` (metadatos vs vista), `q5_03` (diferencias de esquema), `q5_04` (cobertura mensual conjunta),
`q5_05` (nulos de columnas nuevas), `q5_06` (calidad por año), `q5_07` (rango de fechas), `q5_08`
(comparación en el mismo período). Cada una incluye objetivo, fuente y decisión.

## 5.9 Características del diseño que permiten incorporar archivos sin cambiar el flujo

1. **Convención de rutas estable:** `data/raw/<tipo>/<anio>/<nombre-original>.parquet`; el año es
   parte de la ruta, no del código.
2. **Configuración separada de la lógica:** `ANIOS` (o `--anio`) es el único punto que cambia.
3. **Globs en una única capa de vistas** (`sql/00_vistas.sql`): todo el SQL posterior consulta
   `trips`/`trips_clean`, no archivos concretos.
4. **Metadatos derivados del nombre de archivo** (`filename = true` → `file_year`, `file_month`): el
   año/mes de origen siempre está disponible para agrupar y validar.
5. **`union_by_name`** y `coalesce` para tolerar la evolución del esquema.
6. **Descarga idempotente** con manifiesto y verificación: re-ejecutar es seguro y barato.
7. **Reportes regenerables** (`run_sql.py`): la documentación de resultados se vuelve a producir con
   un comando cuando cambian los datos.
