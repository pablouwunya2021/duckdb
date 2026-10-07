# Ejercicio 3 - Consultas directas sobre archivos Parquet

- **SQL:** [`sql/03_exploracion.sql`](../sql/03_exploracion.sql) (16 consultas documentadas con `-- objetivo`, `-- fuente`, `-- decision`).
- **Resultados completos** (SQL + objetivo + fuente + resultado + tiempo + decisión, 3.8):
  [`docs/resultados/03_exploracion.md`](resultados/03_exploracion.md).
- **Notebook:** [`notebooks/01_exploracion_parquet.ipynb`](../notebooks/01_exploracion_parquet.ipynb).
- **Reproducir:** `docker exec lab8-lab python scripts/run_sql.py sql/03_exploracion.sql --max-filas 60`

Ninguna consulta crea tablas: todas usan `read_parquet`, `glob`, `parquet_metadata`,
`parquet_schema` o las vistas lógicas de [`sql/00_vistas.sql`](../sql/00_vistas.sql),
que también se resuelven leyendo los Parquet en cada ejecución (3.7).

> Los resultados de esta página corresponden al estado del Ejercicio 3 (solo 2026, enero-agosto).

## Resumen de resultados

| # | Pregunta | Consulta | Resultado (2026) |
|---|---|---|---|
| 3.1 | ¿Cuántos archivos hay? | `q3_01_cantidad_archivos` | **16** archivos: 8 yellow + 8 green (2026-01 a 2026-08) |
| 3.2 | ¿Cuántos registros? | `q3_02`, `q3_03` | **30,040,469** registros: 29,703,355 yellow + 337,114 green. La suma de `num_rows` de los metadatos coincide con `COUNT(*)` |
| 3.3 | ¿Qué columnas? | `q3_04_columnas_por_archivo` | yellow: 21 columnas, green: 22. `request_source` solo existe desde **junio 2026** |
| 3.4 | ¿Qué tipos? | `q3_05`, `q3_06`, `q3_07` | `TIMESTAMP` para fechas, `DOUBLE` para montos/distancia, `INTEGER` IDs de vendor/zonas, `BIGINT` para códigos categóricos, `VARCHAR` para flags. Compresión ZSTD |
| 3.5 | Muestra | `q3_08`, `q3_09` | Muestra reproducible con `USING SAMPLE reservoir(8 ROWS) REPEATABLE (42)` |
| 3.6 | Calidad | `q3_10` a `q3_16` | Ver tabla siguiente |

### Columnas (3.3) y diferencias entre tipos de taxi

| Columna | yellow | green | Comentario |
|---|---|---|---|
| `tpep_pickup_datetime` / `tpep_dropoff_datetime` | ✔ | – | Nombre de fechas en yellow |
| `lpep_pickup_datetime` / `lpep_dropoff_datetime` | – | ✔ | Nombre de fechas en green |
| `VendorID`, `passenger_count`, `trip_distance`, `RatecodeID`, `store_and_fwd_flag`, `PULocationID`, `DOLocationID`, `payment_type` | ✔ | ✔ | Comunes |
| `fare_amount`, `extra`, `mta_tax`, `tip_amount`, `tolls_amount`, `improvement_surcharge`, `total_amount`, `congestion_surcharge`, `cbd_congestion_fee` | ✔ | ✔ | Montos comunes |
| `Airport_fee` | ✔ | – | Solo yellow |
| `ehail_fee`, `trip_type` | – | ✔ | Solo green (`ehail_fee` siempre NULL) |
| `request_source` | jun-2026+ | jun-2026+ | **Columna nueva**: origen de la solicitud (HV0003 = Uber, HV0005 = Lyft, A, CC, EH...) |

**Decisión:** se creó la vista `trips` que renombra `tpep_/lpep_` a `pickup_datetime`/`dropoff_datetime`,
agrega `taxi_type`, `file_year`, `file_month` y `duration_min`, y une ambos tipos con `UNION ALL BY NAME`.

## 3.6 Problemas de calidad identificados

| Problema | yellow | green | Evidencia | Tratamiento |
|---|---:|---:|---|---|
| `passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge`, `Airport_fee` nulos | 7,716,688 (26.0%) | 48,775 (14.5%) | `q3_10`, `q3_12` | Son los mismos registros que `payment_type = 0` (yellow) / NULL (green): viajes "flex fare"/de plataforma sin datos del taxímetro. **No se eliminan** (son 1/4 de los viajes); se tratan como categoría "desconocido" |
| `payment_type = 0` (fuera del diccionario histórico) | 25.98% | – | `q3_14` | Categoría "desconocido / flex fare" |
| `RatecodeID = 99` (código inexistente) | 769,693 (2.6%) | 2 | `q3_14` | Se conserva pero se agrupa como "desconocido" |
| Pickup fuera del mes del archivo (incluye 2001, 2008, 2009) | 146 | 98 | `q3_13` | Se excluyen en `trips_clean` |
| Duración ≤ 0 minutos (dropoff antes o igual al pickup) | 371,683 | 234 | `q3_12` | Excluidos (`duration_min BETWEEN 1 AND 180`) |
| Duración > 3 horas | 10,127 | 1,287 | `q3_12` | Excluidos (taxímetro no cerrado) |
| Distancia = 0 | 952,231 | 12,212 | `q3_12` | Excluidos (viajes cancelados / error GPS) |
| Distancia > 100 millas (máx. 328,522 mi) | 1,223 | 72 | `q3_10`, `q3_12` | Excluidos (imposible dentro de NYC) |
| Montos negativos (`fare`, `total`, `tip`, `tolls`, recargos) | 161,835 (total) | 1,023 | `q3_10`, `q3_12` | Excluidos: son reversos/reembolsos, no viajes |
| `total_amount ≥ 1000` (máx. 7,053.50) | 54 | 1 | `q3_12` | Excluidos (errores de digitación) |
| `passenger_count = 0` o > 6 | 91,387 | 4,626 | `q3_12` | Excluidos (capacidad máx. de un taxi) |
| Esquema cambiante (`request_source` desde jun-2026) | – | – | `q3_04`, `q3_15` | `union_by_name = true`; análisis de `request_source` solo desde jun-2026 |
| `ehail_fee` 100% NULL | – | 100% | `q3_11` | Columna ignorada |

**Resultado de la limpieza (`q3_16`)**: la vista `trips_clean` conserva **93.88%** de yellow (27.9 M)
y **91.79%** de green (309 K). Las reglas están documentadas en `sql/00_vistas.sql` y no se modificó
ningún archivo original: la limpieza es una transformación declarativa y reproducible.

### Hallazgo adicional: viajes de taxi amarillo solicitados por Uber/Lyft
`request_source` (nueva en junio 2026) muestra que en agosto 2026 **628,774** viajes amarillos se
solicitaron vía `HV0003` (Uber) y **181,233** vía `HV0005` (Lyft): ~24% de los viajes amarillos ya se
originan en una plataforma de alto volumen.

## 3.9 ¿Qué significa consultar directamente un archivo Parquet?

Significa que DuckDB ejecuta SQL **sobre el archivo tal como está en disco**, sin un paso previo de
`CREATE TABLE`/`INSERT`/importación. `read_parquet('data/raw/yellow/*/*.parquet')` se comporta como
una tabla; DuckDB lee el *footer* del archivo (esquema, estadísticas min/max por row group, número de
filas) y luego solo los bloques que la consulta necesita.

Por qué es útil con grandes volúmenes:

1. **Formato columnar:** solo se leen las columnas usadas. `SELECT avg(tip_amount)` lee ~3 MB de los
   ~60 MB de un archivo mensual (`q3_07` muestra el tamaño por columna).
2. **Metadatos y estadísticas:** `COUNT(*)` se resolvió en **0.01 s** para 30 M de filas (`q3_03`) porque
   el número de filas está en los metadatos; los filtros usan min/max por row group para saltarse
   bloques completos (*predicate pushdown*).
3. **Sin duplicar datos ni tiempo de carga:** no hay que importar 30 M de filas para empezar; los
   archivos nuevos que se descargan quedan disponibles inmediatamente gracias a los globs.
4. **Compresión:** ZSTD + diccionario reducen I/O; el Parquet ocupa mucho menos que un CSV equivalente.
5. **Procesamiento fuera de memoria y en paralelo:** DuckDB procesa por bloques en todos los núcleos,
   así que el conjunto puede ser mayor que la RAM (a diferencia de cargarlo completo en pandas).
6. **Una sola fuente de verdad:** los archivos originales se mantienen inmutables; todas las
   transformaciones quedan en SQL versionado.
