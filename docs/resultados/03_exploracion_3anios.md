# Resultados de `sql/03_exploracion.sql`

Generado con `python scripts/run_sql.py sql/03_exploracion.sql` el 2026-10-07 02:16. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

## q3_01_cantidad_archivos

**Objetivo:** Determinar cuantos archivos Parquet hay disponibles por tipo de taxi y anio (3.1).

**Fuente:** `glob('data/raw/*/*/*.parquet')`

```sql
SELECT regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 1) AS taxi_type,
       regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 2) AS anio,
       count(*)                               AS archivos,
       min(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS primer_mes,
       max(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY ALL;
```

**Resultado** (6 filas, 0.20 s):

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2024 | 12 | 2024-01 | 2024-12 |
| green | 2025 | 12 | 2025-01 | 2025-12 |
| green | 2026 | 8 | 2026-01 | 2026-08 |
| yellow | 2024 | 12 | 2024-01 | 2024-12 |
| yellow | 2025 | 12 | 2025-01 | 2025-12 |
| yellow | 2026 | 8 | 2026-01 | 2026-08 |

**Decision / interpretacion:** El conteo coincide con los meses publicados por la TLC reportados por download_data.py; se confirma que no falta ningun archivo antes de seguir.

## q3_02_registros_por_archivo

**Objetivo:** Determinar la cantidad de registros de cada archivo leyendo solo los metadatos del footer Parquet, sin escanear datos (3.2).

**Fuente:** `parquet_file_metadata('data/raw/*/*/*.parquet')`

```sql
SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1) AS taxi_type,
       regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1) AS mes,
       num_rows                         AS registros,
       num_row_groups                   AS row_groups
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
ORDER BY taxi_type, mes;
```

**Resultado** (64 filas, 0.01 s):

| taxi_type | mes | registros | row_groups |
|---|---|---|---|
| green | 2024-01 | 56,551 | 1 |
| green | 2024-02 | 53,577 | 1 |
| green | 2024-03 | 57,457 | 1 |
| green | 2024-04 | 56,471 | 1 |
| green | 2024-05 | 61,003 | 1 |
| green | 2024-06 | 54,748 | 1 |
| green | 2024-07 | 51,837 | 1 |
| green | 2024-08 | 51,771 | 1 |
| green | 2024-09 | 54,440 | 1 |
| green | 2024-10 | 56,147 | 1 |
| green | 2024-11 | 52,222 | 1 |
| green | 2024-12 | 53,994 | 1 |
| green | 2025-01 | 48,326 | 1 |
| green | 2025-02 | 46,621 | 1 |
| green | 2025-03 | 51,539 | 1 |
| green | 2025-04 | 52,132 | 1 |
| green | 2025-05 | 55,399 | 1 |
| green | 2025-06 | 49,390 | 1 |
| green | 2025-07 | 48,205 | 1 |
| green | 2025-08 | 46,306 | 1 |
| green | 2025-09 | 48,893 | 1 |
| green | 2025-10 | 49,416 | 1 |
| green | 2025-11 | 46,912 | 1 |
| green | 2025-12 | 48,236 | 1 |
| green | 2026-01 | 40,272 | 1 |
| green | 2026-02 | 37,373 | 1 |
| green | 2026-03 | 44,208 | 1 |
| green | 2026-04 | 44,238 | 1 |
| green | 2026-05 | 44,921 | 1 |
| green | 2026-06 | 44,163 | 1 |
| green | 2026-07 | 41,252 | 1 |
| green | 2026-08 | 40,687 | 1 |
| yellow | 2024-01 | 2,964,624 | 3 |
| yellow | 2024-02 | 3,007,526 | 3 |
| yellow | 2024-03 | 3,582,628 | 4 |
| yellow | 2024-04 | 3,514,289 | 4 |
| yellow | 2024-05 | 3,723,833 | 4 |
| yellow | 2024-06 | 3,539,193 | 4 |
| yellow | 2024-07 | 3,076,903 | 3 |
| yellow | 2024-08 | 2,979,183 | 3 |
| yellow | 2024-09 | 3,633,030 | 4 |
| yellow | 2024-10 | 3,833,771 | 4 |
| yellow | 2024-11 | 3,646,369 | 4 |
| yellow | 2024-12 | 3,668,371 | 4 |
| yellow | 2025-01 | 3,475,226 | 4 |
| yellow | 2025-02 | 3,577,543 | 4 |
| yellow | 2025-03 | 4,145,257 | 4 |
| yellow | 2025-04 | 3,970,553 | 4 |
| yellow | 2025-05 | 4,591,845 | 5 |
| yellow | 2025-06 | 4,322,960 | 5 |
| yellow | 2025-07 | 3,898,963 | 4 |
| yellow | 2025-08 | 3,574,091 | 4 |
| yellow | 2025-09 | 4,251,015 | 5 |
| yellow | 2025-10 | 4,428,699 | 5 |
| yellow | 2025-11 | 4,181,444 | 4 |
| yellow | 2025-12 | 4,305,006 | 5 |
| yellow | 2026-01 | 3,724,889 | 4 |
| yellow | 2026-02 | 3,399,866 | 4 |
| yellow | 2026-03 | 3,952,451 | 4 |
| yellow | 2026-04 | 3,831,240 | 4 |
| yellow | 2026-05 | 4,090,836 | 4 |
| yellow | 2026-06 | 3,837,248 | 4 |
| yellow | 2026-07 | 3,530,109 | 4 |
| yellow | 2026-08 | 3,336,716 | 4 |

**Decision / interpretacion:** Yellow aporta ~99% de los registros; green es ~90 veces mas pequeno, por lo que las comparaciones entre ambos deben usar proporciones/promedios y no totales absolutos.

## q3_03_registros_totales

**Objetivo:** Total de registros disponibles por tipo, contando con un escaneo real (COUNT(*)) para contrastarlo con los metadatos (3.2).

**Fuente:** `read_parquet('data/raw/yellow/*/*.parquet'), read_parquet('data/raw/green/*/*.parquet')`

```sql
SELECT 'yellow' AS taxi_type, count(*) AS registros FROM read_parquet('data/raw/yellow/*/*.parquet')
UNION ALL
SELECT 'green', count(*) FROM read_parquet('data/raw/green/*/*.parquet')
UNION ALL
SELECT 'total', count(*) FROM read_parquet('data/raw/*/*/*.parquet', union_by_name = true);
```

**Resultado** (3 filas, 0.02 s):

| taxi_type | registros |
|---|---|
| yellow | 119,595,677 |
| green | 1,588,707 |
| total | 121,184,384 |

**Decision / interpretacion:** COUNT(*) coincide exactamente con la suma de num_rows de los metadatos: los archivos estan completos y DuckDB resuelve el conteo usando los metadatos (muy rapido).

## q3_04_columnas_por_archivo

**Objetivo:** Identificar las columnas presentes y si estan en todos los archivos (evolucion del esquema) (3.3).

**Fuente:** `parquet_schema('data/raw/*/*/*.parquet')`

```sql
SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1)  AS taxi_type,
       name                           AS columna,
       count(DISTINCT file_name)      AS archivos_con_columna,
       min(regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1)) AS desde,
       max(regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1)) AS hasta
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE name NOT IN ('schema', 'duckdb_schema')
GROUP BY ALL
ORDER BY taxi_type, archivos_con_columna, columna;
```

**Resultado** (43 filas, 0.01 s):

| taxi_type | columna | archivos_con_columna | desde | hasta |
|---|---|---|---|---|
| green | request_source | 3 | 2026-06 | 2026-08 |
| green | cbd_congestion_fee | 20 | 2025-01 | 2026-08 |
| green | DOLocationID | 32 | 2024-01 | 2026-08 |
| green | PULocationID | 32 | 2024-01 | 2026-08 |
| green | RatecodeID | 32 | 2024-01 | 2026-08 |
| green | VendorID | 32 | 2024-01 | 2026-08 |
| green | congestion_surcharge | 32 | 2024-01 | 2026-08 |
| green | ehail_fee | 32 | 2024-01 | 2026-08 |
| green | extra | 32 | 2024-01 | 2026-08 |
| green | fare_amount | 32 | 2024-01 | 2026-08 |
| green | improvement_surcharge | 32 | 2024-01 | 2026-08 |
| green | lpep_dropoff_datetime | 32 | 2024-01 | 2026-08 |
| green | lpep_pickup_datetime | 32 | 2024-01 | 2026-08 |
| green | mta_tax | 32 | 2024-01 | 2026-08 |
| green | passenger_count | 32 | 2024-01 | 2026-08 |
| green | payment_type | 32 | 2024-01 | 2026-08 |
| green | store_and_fwd_flag | 32 | 2024-01 | 2026-08 |
| green | tip_amount | 32 | 2024-01 | 2026-08 |
| green | tolls_amount | 32 | 2024-01 | 2026-08 |
| green | total_amount | 32 | 2024-01 | 2026-08 |
| green | trip_distance | 32 | 2024-01 | 2026-08 |
| green | trip_type | 32 | 2024-01 | 2026-08 |
| yellow | request_source | 3 | 2026-06 | 2026-08 |
| yellow | cbd_congestion_fee | 20 | 2025-01 | 2026-08 |
| yellow | Airport_fee | 32 | 2024-01 | 2026-08 |
| yellow | DOLocationID | 32 | 2024-01 | 2026-08 |
| yellow | PULocationID | 32 | 2024-01 | 2026-08 |
| yellow | RatecodeID | 32 | 2024-01 | 2026-08 |
| yellow | VendorID | 32 | 2024-01 | 2026-08 |
| yellow | congestion_surcharge | 32 | 2024-01 | 2026-08 |
| yellow | extra | 32 | 2024-01 | 2026-08 |
| yellow | fare_amount | 32 | 2024-01 | 2026-08 |
| yellow | improvement_surcharge | 32 | 2024-01 | 2026-08 |
| yellow | mta_tax | 32 | 2024-01 | 2026-08 |
| yellow | passenger_count | 32 | 2024-01 | 2026-08 |
| yellow | payment_type | 32 | 2024-01 | 2026-08 |
| yellow | store_and_fwd_flag | 32 | 2024-01 | 2026-08 |
| yellow | tip_amount | 32 | 2024-01 | 2026-08 |
| yellow | tolls_amount | 32 | 2024-01 | 2026-08 |
| yellow | total_amount | 32 | 2024-01 | 2026-08 |
| yellow | tpep_dropoff_datetime | 32 | 2024-01 | 2026-08 |
| yellow | tpep_pickup_datetime | 32 | 2024-01 | 2026-08 |
| yellow | trip_distance | 32 | 2024-01 | 2026-08 |

**Decision / interpretacion:** El esquema NO es constante: request_source aparece a partir de junio 2026 y yellow/green difieren (tpep_ vs lpep_, Airport_fee solo yellow, ehail_fee/trip_type solo green). Por eso todas las lecturas usan union_by_name=true y se creo la vista normalizada `trips`.

## q3_05_tipos_yellow

**Objetivo:** Determinar los tipos de datos (DuckDB) de las columnas de taxis amarillos (3.4).

**Fuente:** `read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)`

```sql
DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
```

**Resultado** (21 filas, 0.00 s):

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| tpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| tpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| Airport_fee | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

**Decision / interpretacion:** Fechas ya vienen como TIMESTAMP (no hay que parsear texto); montos DOUBLE; passenger_count, RatecodeID y payment_type son BIGINT aunque son categoricos/pequenos. store_and_fwd_flag es VARCHAR (Y/N).

## q3_06_tipos_green

**Objetivo:** Determinar los tipos de datos (DuckDB) de las columnas de taxis verdes (3.4).

**Fuente:** `read_parquet('data/raw/green/*/*.parquet', union_by_name = true)`

```sql
DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado** (22 filas, 0.00 s):

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| lpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| lpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| ehail_fee | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| trip_type | BIGINT | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

**Decision / interpretacion:** Mismos tipos que yellow para las columnas comunes; se pueden unir con UNION ALL BY NAME tras renombrar lpep_* -> pickup/dropoff.

## q3_07_tipos_fisicos_parquet

**Objetivo:** Ver los tipos fisicos/logicos y la compresion con que estan guardadas las columnas en un archivo (3.4).

**Fuente:** `parquet_metadata('data/raw/yellow/2026/yellow_tripdata_2026-01.parquet')`

```sql
SELECT path_in_schema AS columna, type AS tipo_fisico, compression,
       sum(total_compressed_size)   AS bytes_comprimidos,
       sum(total_uncompressed_size) AS bytes_sin_comprimir,
       round(sum(total_uncompressed_size) / sum(total_compressed_size), 1) AS ratio
FROM parquet_metadata('data/raw/yellow/2026/yellow_tripdata_2026-01.parquet')
GROUP BY ALL
ORDER BY bytes_comprimidos DESC;
```

**Resultado** (20 filas, 0.01 s):

| columna | tipo_fisico | compression | bytes_comprimidos | bytes_sin_comprimir | ratio |
|---|---|---|---|---|---|
| tpep_dropoff_datetime | INT64 | ZSTD | 16,957,868 | 29,064,509 | 1.7 |
| tpep_pickup_datetime | INT64 | ZSTD | 16,673,149 | 29,056,729 | 1.7 |
| total_amount | DOUBLE | ZSTD | 6,368,044 | 6,977,226 | 1.1 |
| trip_distance | DOUBLE | ZSTD | 5,135,846 | 5,703,597 | 1.1 |
| fare_amount | DOUBLE | ZSTD | 4,713,386 | 6,208,661 | 1.3 |
| DOLocationID | INT32 | ZSTD | 3,725,745 | 4,202,515 | 1.1 |
| tip_amount | DOUBLE | ZSTD | 3,427,783 | 4,825,406 | 1.4 |
| PULocationID | INT32 | ZSTD | 3,019,314 | 3,867,567 | 1.3 |
| extra | DOUBLE | ZSTD | 817,671 | 1,683,173 | 2.1 |
| cbd_congestion_fee | DOUBLE | ZSTD | 503,363 | 931,716 | 1.9 |
| tolls_amount | DOUBLE | ZSTD | 468,440 | 1,999,894 | 4.3 |
| VendorID | INT32 | ZSTD | 447,269 | 845,070 | 1.9 |
| passenger_count | INT64 | ZSTD | 432,701 | 986,851 | 2.3 |
| payment_type | INT64 | ZSTD | 331,973 | 646,739 | 1.9 |
| RatecodeID | INT64 | ZSTD | 284,444 | 579,991 | 2 |
| congestion_surcharge | DOUBLE | ZSTD | 273,105 | 531,114 | 1.9 |
| Airport_fee | DOUBLE | ZSTD | 254,702 | 603,074 | 2.4 |
| improvement_surcharge | DOUBLE | ZSTD | 171,718 | 341,470 | 2 |
| mta_tax | DOUBLE | ZSTD | 132,491 | 298,232 | 2.3 |
| store_and_fwd_flag | BYTE_ARRAY | ZSTD | 5,961 | 9,699 | 1.6 |

**Decision / interpretacion:** Columnas comprimidas con ZSTD y codificacion por diccionario; esto explica el tamano pequeno (~60 MB por 3.7 M filas) y por que leer solo algunas columnas es barato.

## q3_08_muestra_yellow

**Objetivo:** Obtener una muestra reproducible de registros de taxis amarillos (3.5).

**Fuente:** `read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)`

```sql
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
```

**Resultado** (8 filas, 0.28 s):

| VendorID | tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | RatecodeID | store_and_fwd_flag | PULocationID | DOLocationID | payment_type | fare_amount | extra | mta_tax | tip_amount | tolls_amount | improvement_surcharge | total_amount | congestion_surcharge | Airport_fee | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2024-01-01 00:21:18 | 2024-01-01 00:28:37 | 2 | 0.93 | 1 | N | 114 | 234 | 1 | 8.6 | 1 | 0.5 | 0 | 0 | 1 | 13.6 | 2.5 | 0 | NULL | NULL |
| 1 | 2024-01-01 02:41:59 | 2024-01-01 02:56:19 | 1 | 2.3 | 1 | N | 90 | 233 | 1 | 14.9 | 3.5 | 0.5 | 3 | 0 | 1 | 22.9 | 2.5 | 0 | NULL | NULL |
| 1 | 2024-01-01 02:24:26 | 2024-01-01 02:30:49 | 0 | 1 | 1 | N | 233 | 264 | 2 | 8.6 | 3.5 | 0.5 | 0 | 0 | 1 | 13.6 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 03:52:42 | 2024-01-01 04:11:32 | 1 | 5.11 | 1 | N | 186 | 151 | 1 | 24.7 | 1 | 0.5 | 5.94 | 0 | 1 | 35.64 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 04:26:01 | 2024-01-01 04:34:31 | 1 | 2.4 | 1 | N | 249 | 48 | 1 | 12.1 | 1 | 0.5 | 3.42 | 0 | 1 | 20.52 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 07:31:23 | 2024-01-01 07:46:58 | 2 | 11.7 | 1 | N | 132 | 138 | 1 | 44.3 | 0 | 0.5 | 11.45 | 0 | 1 | 59 | 0 | 1.75 | NULL | NULL |
| 2 | 2024-01-01 09:50:41 | 2024-01-01 10:13:04 | 1 | 4.84 | 1 | N | 100 | 88 | 1 | 26.1 | 0 | 0.5 | 6.02 | 0 | 1 | 36.12 | 2.5 | 0 | NULL | NULL |
| 2 | 2024-01-01 11:44:16 | 2024-01-01 11:58:40 | 6 | 6.2 | 1 | N | 209 | 141 | 1 | 26.1 | 0 | 0.5 | 6.02 | 0 | 1 | 36.12 | 2.5 | 0 | NULL | NULL |

**Decision / interpretacion:** Se observan registros con passenger_count/RatecodeID NULL y payment_type 0, que hay que tratar como "desconocido".

## q3_09_muestra_green

**Objetivo:** Obtener una muestra reproducible de registros de taxis verdes (3.5).

**Fuente:** `read_parquet('data/raw/green/*/*.parquet', union_by_name = true)`

```sql
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);
```

**Resultado** (8 filas, 0.02 s):

| VendorID | lpep_pickup_datetime | lpep_dropoff_datetime | store_and_fwd_flag | RatecodeID | PULocationID | DOLocationID | passenger_count | trip_distance | fare_amount | extra | mta_tax | tip_amount | tolls_amount | ehail_fee | improvement_surcharge | total_amount | payment_type | trip_type | congestion_surcharge | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2024-01-02 19:19:54 | 2024-01-02 19:20:53 | N | 1 | 75 | 75 | 1 | 0 | 3 | 2.5 | 0.5 | 0 | 0 | NULL | 1 | 7 | 2 | 1 | 0 | NULL | NULL |
| 1 | 2024-01-08 11:30:12 | 2024-01-08 11:31:26 | N | 5 | 166 | 166 | 2 | 0.1 | 70 | 0 | 0 | 0 | 0 | NULL | 0 | 70 | 1 | 2 | 0 | NULL | NULL |
| 2 | 2024-01-09 15:34:56 | 2024-01-09 15:35:11 | N | 1 | 74 | 74 | 1 | 0 | -3 | 0 | -0.5 | 0 | 0 | NULL | -1 | -4.5 | 3 | 1 | 0 | NULL | NULL |
| 2 | 2024-01-11 14:09:59 | 2024-01-11 14:18:57 | N | 1 | 75 | 74 | 1 | 0.91 | 9.3 | 0 | 0.5 | 0 | 0 | NULL | 1 | 10.8 | 2 | 1 | 0 | NULL | NULL |
| 2 | 2024-01-13 18:39:53 | 2024-01-13 18:58:25 | N | 1 | 74 | 238 | 1 | 2.58 | 19.1 | 0 | 0.5 | 2 | 0 | NULL | 1 | 22.6 | 1 | 1 | 0 | NULL | NULL |
| 2 | 2024-01-16 11:39:25 | 2024-01-16 11:49:14 | N | 1 | 74 | 166 | 2 | 1.54 | 10.7 | 0 | 0.5 | 2.44 | 0 | NULL | 1 | 14.64 | 1 | 1 | 0 | NULL | NULL |
| 1 | 2024-01-17 10:07:09 | 2024-01-17 10:11:36 | N | 1 | 75 | 75 | 1 | 0.7 | 6.5 | 0 | 1.5 | 0 | 0 | NULL | 1 | 8 | 2 | 1 | 0 | NULL | NULL |
| 2 | 2024-01-20 03:16:12 | 2024-01-20 03:24:26 | N | 1 | 129 | 7 | 2 | 1.19 | 10 | 1 | 0.5 | 0 | 0 | NULL | 1 | 12.5 | 2 | 1 | 0 | NULL | NULL |

**Decision / interpretacion:** Green incluye trip_type (1 = calle, 2 = despacho) y ehail_fee (siempre NULL).

## q3_10_perfil_yellow

**Objetivo:** Perfil estadistico de todas las columnas (min, max, promedio, % nulos, cardinalidad aproximada) para detectar problemas de calidad (3.6).

**Fuente:** `read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)`

```sql
SUMMARIZE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
```

**Resultado** (21 filas, 32.59 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 7 | 4 | 1.8335070004244385 | 0.6161473518861214 | 2 | 2 | 2 | 119,595,677 | 0 |
| tpep_pickup_datetime | TIMESTAMP | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 | 59,913,128 | 2025-05-15 18:14:36.687007 | NULL | 2024-09-28 21:25:30.951049 | 2025-05-24 19:42:48.586141 | 2026-01-02 05:14:39.061007 | 119,595,677 | 0 |
| tpep_dropoff_datetime | TIMESTAMP | 2001-01-01 16:09:38 | 2026-09-01 20:16:00 | 57,216,129 | 2025-05-15 18:32:04.653367 | NULL | 2024-09-30 17:29:23.21872 | 2025-05-25 03:46:41.145058 | 2025-12-31 03:16:55.084682 | 119,595,677 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.2997810895650606 | 0.7484946933744986 | 1 | 1 | 1 | 119,595,677 | 19.58 |
| trip_distance | DOUBLE | 0.0 | 398608.62 | 10,523 | 5.879887555050379 | 554.6138004037712 | 1.0251886687535234 | 1.8153143417460142 | 3.6075211783698093 | 119,595,677 | 0 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 3.174698541566505 | 14.118714317547617 | 1 | 1 | 1 | 119,595,677 | 19.58 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 119,595,677 | 19.58 |
| PULocationID | INTEGER | 1 | 265 | 298 | 162.46523230935847 | 65.71491450004207 | 123 | 161 | 233 | 119,595,677 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 298 | 161.89985110414986 | 70.23822645090894 | 111 | 162 | 234 | 119,595,677 | 0 |
| payment_type | BIGINT | 0 | 5 | 6 | 0.9771172916225057 | 0.6976295922851065 | 1 | 1 | 1 | 119,595,677 | 0 |
| fare_amount | DOUBLE | -2555.2 | 863372.12 | 26,624 | 19.417722070546585 | 102.12534044445314 | 9.28580860830735 | 14.218964438356306 | 23.594747629688015 | 119,595,677 | 0 |
| extra | DOUBLE | -17.39 | 244.35 | 496 | 1.2278120382227478 | 1.806202609135178 | 0.0 | 0.0 | 2.5 | 119,595,677 | 0 |
| mta_tax | DOUBLE | -21.74 | 5243.38 | 113 | 0.48102933988157487 | 0.4955166873878938 | 0.5 | 0.5 | 0.5 | 119,595,677 | 0 |
| tip_amount | DOUBLE | -333.33 | 999.99 | 8,438 | 2.999775045219561 | 4.015961336360891 | 0.0 | 2.302255811523094 | 4.044463022999459 | 119,595,677 | 0 |
| tolls_amount | DOUBLE | -148.17 | 1702.88 | 5,456 | 0.5296646904716777 | 2.189367595575672 | 0.0 | 0.0 | 0.0 | 119,595,677 | 0 |
| improvement_surcharge | DOUBLE | -1.0 | 4.0 | 11 | 0.9585691165914076 | 0.25657096867734747 | 1.0 | 1.0 | 1.0 | 119,595,677 | 0 |
| total_amount | DOUBLE | -2560.2 | 863380.37 | 61,116 | 28.011940930007736 | 103.02656691302835 | 16.092658338788784 | 21.748797934644383 | 31.6745750088827 | 119,595,677 | 0 |
| congestion_surcharge | DOUBLE | -2.5 | 2.75 | 11 | 2.209760147096367 | 0.8971724750188141 | 2.5 | 2.5 | 2.5 | 119,595,677 | 19.58 |
| Airport_fee | DOUBLE | -2.0 | 27.0 | 19 | 0.15089219942845744 | 0.5292986196296628 | 0.0 | 0.0 | 0.0 | 119,595,677 | 19.58 |
| cbd_congestion_fee | DOUBLE | -0.75 | 1.75 | 7 | 0.5317629563640518 | 0.3533649102520791 | 0.0 | 0.75 | 0.75 | 119,595,677 | 34.42 |
| request_source | VARCHAR | A | HV0005 | 3 | NULL | NULL | NULL | NULL | NULL | 119,595,677 | 97.57 |

**Decision / interpretacion:** Se detectan minimos negativos en montos, maximos absurdos en trip_distance y total_amount, fechas desde 2001 y ~26% de nulos en passenger_count/RatecodeID/congestion_surcharge/Airport_fee.

## q3_11_perfil_green

**Objetivo:** Perfil estadistico de las columnas de taxis verdes (3.6).

**Fuente:** `read_parquet('data/raw/green/*/*.parquet', union_by_name = true)`

```sql
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado** (22 filas, 0.50 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 6 | 3 | 2.0460078541858255 | 0.8552945522798996 | 2 | 2 | 2 | 1,588,707 | 0 |
| lpep_pickup_datetime | TIMESTAMP | 2008-12-31 00:00:00 | 2026-08-31 23:58:28 | 1,571,774 | 2025-04-04 05:19:26.264852 | NULL | 2024-08-04 11:37:46.781888 | 2025-03-24 17:47:55.548166 | 2025-11-24 21:34:15.020842 | 1,588,707 | 0 |
| lpep_dropoff_datetime | TIMESTAMP | 2008-12-31 00:00:00 | 2026-09-02 09:39:37 | 1,740,542 | 2025-04-04 05:39:49.432621 | NULL | 2024-08-04 19:04:26.08644 | 2025-03-25 12:15:19.120927 | 2025-11-22 20:09:05.257837 | 1,588,707 | 0 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 1,588,707 | 7.74 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 1.2536759990284665 | 1.8724714003995053 | 1 | 1 | 1 | 1,588,707 | 7.74 |
| PULocationID | INTEGER | 1 | 265 | 266 | 96.73649640871476 | 56.767371148127815 | 74 | 75 | 104 | 1,588,707 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 266 | 142.1635468339977 | 76.99613522856887 | 74 | 140 | 228 | 1,588,707 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.3039139701608216 | 0.9577964773685873 | 1 | 1 | 1 | 1,588,707 | 7.74 |
| trip_distance | DOUBLE | 0.0 | 262315.94 | 3,609 | 16.987296688439105 | 1050.5286543934656 | 1.1903539664777727 | 1.9469763834950709 | 3.454269823857068 | 1,588,707 | 0 |
| fare_amount | DOUBLE | -500.0 | 1676.7 | 7,254 | 17.971704329368592 | 17.66704271806287 | 9.301280303177958 | 13.57821322369382 | 20.389563998088864 | 1,588,707 | 0 |
| extra | DOUBLE | -7.5 | 12.5 | 32 | 0.8900914643165795 | 1.3875834923747712 | 0.0 | 0.0 | 1.0249783954002354 | 1,588,707 | 0 |
| mta_tax | DOUBLE | -0.5 | 61.5 | 10 | 0.5693664722318212 | 0.34812948675085553 | 0.5 | 0.5 | 0.5 | 1,588,707 | 0 |
| tip_amount | DOUBLE | -100.0 | 495.0 | 2,526 | 2.616680684355206 | 3.997549097159663 | 0.0 | 2.0369141074839985 | 3.8676633670512266 | 1,588,707 | 0 |
| tolls_amount | DOUBLE | -24.5 | 108.0 | 208 | 0.2575251509560779 | 1.4246022717682936 | 0.0 | 0.0 | 0.0 | 1,588,707 | 0 |
| ehail_fee | DOUBLE | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL | 1,588,707 | 100 |
| improvement_surcharge | DOUBLE | -1.0 | 1.0 | 5 | 0.957681309391541 | 0.19422081336032695 | 1.0 | 1.0 | 1.0 | 1,588,707 | 0 |
| total_amount | DOUBLE | -501.5 | 1678.2 | 11,049 | 24.87594713184936 | 19.94705388459323 | 14.337967054926246 | 19.823061785031204 | 28.918915396345326 | 1,588,707 | 0 |
| payment_type | BIGINT | 1 | 5 | 5 | 1.2741191383916755 | 0.4771788278093357 | 1 | 1 | 2 | 1,588,707 | 7.74 |
| trip_type | BIGINT | 1 | 2 | 2 | 1.050303187856383 | 0.2185699195774674 | 1 | 1 | 1 | 1,588,707 | 7.75 |
| congestion_surcharge | DOUBLE | -2.75 | 2.75 | 6 | 0.849158334038332 | 1.270158873377385 | 0.0 | 0.0 | 2.75 | 1,588,707 | 7.74 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.06690071539422385 | 0.21384927720410885 | 0.0 | 0.0 | 0.0 | 1,588,707 | 41.8 |
| request_source | VARCHAR | A | HV0005 | 2 | NULL | NULL | NULL | NULL | NULL | 1,588,707 | 98.79 |

**Decision / interpretacion:** ehail_fee es 100% NULL (columna inutil); green tambien tiene montos negativos y distancias extremas.

## q3_12_problemas_calidad

**Objetivo:** Cuantificar cada problema de calidad detectado, por tipo de taxi (3.6).

**Fuente:** `vista trips (lee data/raw/*/*/*.parquet)`

```sql
UNPIVOT (
    SELECT taxi_type,
           count(*)                                                                    AS total_registros,
           count(*) FILTER (WHERE passenger_count IS NULL)                             AS passenger_count_nulo,
           count(*) FILTER (WHERE passenger_count = 0)                                 AS passenger_count_cero,
           count(*) FILTER (WHERE passenger_count > 6)                                 AS passenger_count_mayor_6,
           count(*) FILTER (WHERE year(pickup_datetime) <> file_year
                              OR month(pickup_datetime) <> file_month)                 AS pickup_fuera_del_mes_del_archivo,
           count(*) FILTER (WHERE duration_min <= 0)                                   AS duracion_cero_o_negativa,
           count(*) FILTER (WHERE duration_min > 180)                                  AS duracion_mayor_3h,
           count(*) FILTER (WHERE trip_distance = 0)                                   AS distancia_cero,
           count(*) FILTER (WHERE trip_distance > 100)                                 AS distancia_mayor_100mi,
           count(*) FILTER (WHERE fare_amount < 0)                                     AS tarifa_negativa,
           count(*) FILTER (WHERE total_amount < 0)                                    AS total_negativo,
           count(*) FILTER (WHERE total_amount >= 1000)                                AS total_mayor_1000,
           count(*) FILTER (WHERE tip_amount < 0)                                      AS propina_negativa,
           count(*) FILTER (WHERE ratecode_id = 99)                                    AS ratecode_99_invalido,
           count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL)            AS payment_type_desconocido
    FROM trips
    GROUP BY taxi_type
)
ON COLUMNS(* EXCLUDE (taxi_type))
INTO NAME problema VALUE registros
ORDER BY problema, taxi_type;
```

**Resultado** (30 filas, 2.23 s):

| taxi_type | problema | registros |
|---|---|---|
| green | distancia_cero | 71,224 |
| yellow | distancia_cero | 3,131,494 |
| green | distancia_mayor_100mi | 516 |
| yellow | distancia_mayor_100mi | 5,706 |
| green | duracion_cero_o_negativa | 2,806 |
| yellow | duracion_cero_o_negativa | 931,497 |
| green | duracion_mayor_3h | 6,973 |
| yellow | duracion_mayor_3h | 53,877 |
| green | passenger_count_cero | 19,575 |
| yellow | passenger_count_cero | 752,775 |
| green | passenger_count_mayor_6 | 469 |
| yellow | passenger_count_mayor_6 | 458 |
| green | passenger_count_nulo | 122,983 |
| yellow | passenger_count_nulo | 23,419,814 |
| green | payment_type_desconocido | 122,983 |
| yellow | payment_type_desconocido | 23,419,814 |
| green | pickup_fuera_del_mes_del_archivo | 510 |
| yellow | pickup_fuera_del_mes_del_archivo | 780 |
| green | propina_negativa | 196 |
| yellow | propina_negativa | 3,907 |
| green | ratecode_99_invalido | 409 |
| yellow | ratecode_99_invalido | 2,041,064 |
| green | tarifa_negativa | 4,879 |
| yellow | tarifa_negativa | 3,737,008 |
| green | total_mayor_1000 | 3 |
| yellow | total_mayor_1000 | 199 |
| green | total_negativo | 4,971 |
| yellow | total_negativo | 1,744,900 |
| green | total_registros | 1,588,707 |
| yellow | total_registros | 119,595,677 |

**Decision / interpretacion:** Con estos conteos se definieron las reglas de la vista trips_clean (sql/00_vistas.sql). Ninguna regla elimina mas de ~4% de los datos excepto la combinacion de distancia 0 y duracion invalida; los nulos de passenger_count NO se eliminan porque representan 26% de yellow.

## q3_13_fechas_fuera_de_rango

**Objetivo:** Ver de que fechas son los registros cuyo pickup no corresponde al mes del archivo (3.6).

**Fuente:** `vista trips (lee data/raw/*/*/*.parquet)`

```sql
SELECT taxi_type, strftime(pickup_datetime, '%Y-%m') AS mes_pickup,
       file_year || '-' || lpad(file_month::VARCHAR, 2, '0') AS mes_archivo, count(*) AS registros
FROM trips
WHERE year(pickup_datetime) <> file_year OR month(pickup_datetime) <> file_month
GROUP BY ALL
ORDER BY registros DESC
LIMIT 20;
```

**Resultado** (20 filas, 0.37 s):

| taxi_type | mes_pickup | mes_archivo | registros |
|---|---|---|---|
| yellow | 2024-05 | 2024-06 | 42 |
| yellow | 2026-08 | 2026-07 | 38 |
| green | 2025-02 | 2025-01 | 37 |
| yellow | 2024-10 | 2024-11 | 34 |
| yellow | 2024-09 | 2024-08 | 32 |
| yellow | 2024-08 | 2024-09 | 31 |
| green | 2024-08 | 2024-09 | 30 |
| yellow | 2025-01 | 2025-02 | 30 |
| yellow | 2024-08 | 2024-07 | 29 |
| yellow | 2025-02 | 2025-03 | 29 |
| yellow | 2024-11 | 2024-10 | 27 |
| yellow | 2024-11 | 2024-12 | 26 |
| green | 2024-08 | 2024-07 | 25 |
| yellow | 2024-12 | 2025-01 | 21 |
| yellow | 2025-10 | 2025-11 | 21 |
| yellow | 2025-05 | 2025-06 | 20 |
| yellow | 2025-04 | 2025-05 | 20 |
| green | 2025-08 | 2025-09 | 19 |
| yellow | 2024-02 | 2024-03 | 19 |
| green | 2026-02 | 2026-01 | 18 |

**Decision / interpretacion:** Son pocos (cientos) pero llegan hasta 2001/2008: errores de reloj del taximetro. Se descartan en trips_clean filtrando pickup dentro del anio/mes del archivo, asi las series temporales no tienen puntos fantasma.

## q3_14_codigos_categoricos

**Objetivo:** Revisar los valores de las columnas categoricas contra el diccionario de datos de la TLC (3.6).

**Fuente:** `vista trips (lee data/raw/*/*/*.parquet)`

```sql
SELECT taxi_type, 'payment_type' AS columna, payment_type::VARCHAR AS codigo, count(*) AS registros,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips GROUP BY 1, 2, 3
UNION ALL
SELECT taxi_type, 'ratecode_id', ratecode_id::VARCHAR, count(*),
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2)
FROM trips GROUP BY 1, 2, 3
UNION ALL
SELECT taxi_type, 'vendor_id', vendor_id::VARCHAR, count(*),
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2)
FROM trips GROUP BY 1, 2, 3
ORDER BY taxi_type, columna, registros DESC;
```

**Resultado** (35 filas, 1.60 s):

| taxi_type | columna | codigo | registros | pct |
|---|---|---|---|---|
| green | payment_type | 1 | 1,081,279 | 68.06 |
| green | payment_type | 2 | 370,766 | 23.34 |
| green | payment_type | NULL | 122,983 | 7.74 |
| green | payment_type | 3 | 10,072 | 0.63 |
| green | payment_type | 4 | 3,555 | 0.22 |
| green | payment_type | 5 | 52 | 0 |
| green | ratecode_id | 1 | 1,378,324 | 86.76 |
| green | ratecode_id | NULL | 122,983 | 7.74 |
| green | ratecode_id | 5 | 80,074 | 5.04 |
| green | ratecode_id | 2 | 4,188 | 0.26 |
| green | ratecode_id | 4 | 1,762 | 0.11 |
| green | ratecode_id | 3 | 956 | 0.06 |
| green | ratecode_id | 99 | 409 | 0.03 |
| green | ratecode_id | 6 | 11 | 0 |
| green | vendor_id | 2 | 1,352,140 | 85.11 |
| green | vendor_id | 1 | 174,635 | 10.99 |
| green | vendor_id | 6 | 61,932 | 3.9 |
| yellow | payment_type | 1 | 80,447,167 | 67.27 |
| yellow | payment_type | 0 | 23,419,814 | 19.58 |
| yellow | payment_type | 2 | 12,902,464 | 10.79 |
| yellow | payment_type | 4 | 2,128,195 | 1.78 |
| yellow | payment_type | 3 | 698,028 | 0.58 |
| yellow | payment_type | 5 | 9 | 0 |
| yellow | ratecode_id | 1 | 89,046,084 | 74.46 |
| yellow | ratecode_id | NULL | 23,419,814 | 19.58 |
| yellow | ratecode_id | 2 | 3,399,740 | 2.84 |
| yellow | ratecode_id | 99 | 2,041,064 | 1.71 |
| yellow | ratecode_id | 5 | 1,032,983 | 0.86 |
| yellow | ratecode_id | 3 | 370,695 | 0.31 |
| yellow | ratecode_id | 4 | 285,155 | 0.24 |
| yellow | ratecode_id | 6 | 142 | 0 |
| yellow | vendor_id | 2 | 93,837,123 | 78.46 |
| yellow | vendor_id | 1 | 24,769,862 | 20.71 |
| yellow | vendor_id | 7 | 903,251 | 0.76 |
| yellow | vendor_id | 6 | 85,441 | 0.07 |

**Decision / interpretacion:** payment_type 0 (no documentado en el diccionario historico; corresponde a "Flex Fare"/desconocido) concentra 26% de yellow, exactamente los registros con passenger_count NULL. RatecodeID 99 no existe en el diccionario. Se trataran como categoria "desconocido".

## q3_15_request_source

**Objetivo:** Explorar la nueva columna request_source que aparece a mitad de 2026 (3.3 / 3.6).

**Fuente:** `read_parquet('data/raw/*/2026/*.parquet', union_by_name = true, filename = true)`

```sql
SELECT regexp_extract(filename, '(yellow|green)_tripdata_(\d{4}-\d{2})', 1) AS taxi_type,
       regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)               AS mes,
       coalesce(request_source, 'NULL') AS request_source,
       count(*) AS registros
FROM read_parquet('data/raw/*/2026/*.parquet', union_by_name = true, filename = true)
WHERE regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1) >= '2026-05'
GROUP BY ALL
ORDER BY taxi_type, mes, registros DESC;
```

**Resultado** (29 filas, 0.05 s):

| taxi_type | mes | request_source | registros |
|---|---|---|---|
| green | 2026-05 | NULL | 44,921 |
| green | 2026-06 | NULL | 37,692 |
| green | 2026-06 | A | 6,471 |
| green | 2026-07 | NULL | 34,822 |
| green | 2026-07 | A | 6,428 |
| green | 2026-07 | CC | 2 |
| green | 2026-08 | NULL | 34,377 |
| green | 2026-08 | A | 5,130 |
| green | 2026-08 | HV0005 | 1,179 |
| green | 2026-08 | CC | 1 |
| yellow | 2026-05 | NULL | 4,090,836 |
| yellow | 2026-06 | NULL | 2,824,068 |
| yellow | 2026-06 | HV0003 | 927,698 |
| yellow | 2026-06 | A | 76,711 |
| yellow | 2026-06 | EH0004 | 8,107 |
| yellow | 2026-06 | CC | 664 |
| yellow | 2026-07 | NULL | 2,560,692 |
| yellow | 2026-07 | HV0003 | 739,048 |
| yellow | 2026-07 | A | 223,309 |
| yellow | 2026-07 | EH0004 | 6,409 |
| yellow | 2026-07 | CC | 642 |
| yellow | 2026-07 | EH0010 | 9 |
| yellow | 2026-08 | NULL | 2,415,867 |
| yellow | 2026-08 | HV0003 | 628,774 |
| yellow | 2026-08 | HV0005 | 181,233 |
| yellow | 2026-08 | A | 103,753 |
| yellow | 2026-08 | EH0004 | 6,253 |
| yellow | 2026-08 | CC | 573 |
| yellow | 2026-08 | EH0010 | 263 |

**Decision / interpretacion:** Es NULL en todos los archivos anteriores a junio 2026 (no existia). Desde junio identifica el origen del viaje (HV0003 = Uber, HV0005 = Lyft, A/CC/EH = apps y despacho). Solo se puede analizar desde junio 2026.

## q3_16_impacto_limpieza

**Objetivo:** Medir cuantos registros conserva la vista trips_clean despues de aplicar las reglas de calidad (3.6).

**Fuente:** `vistas trips y trips_clean (leen data/raw/*/*/*.parquet)`

```sql
SELECT t.taxi_type, t.registros AS registros_originales, c.registros AS registros_limpios,
       t.registros - c.registros AS descartados,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado
FROM (SELECT taxi_type, count(*) AS registros FROM trips GROUP BY 1) t
JOIN (SELECT taxi_type, count(*) AS registros FROM trips_clean GROUP BY 1) c USING (taxi_type)
ORDER BY t.taxi_type DESC;
```

**Resultado** (2 filas, 1.54 s):

| taxi_type | registros_originales | registros_limpios | descartados | pct_conservado |
|---|---|---|---|---|
| yellow | 119,595,677 | 110,568,996 | 9,026,681 | 92.45 |
| green | 1,588,707 | 1,458,348 | 130,359 | 91.79 |

**Decision / interpretacion:** Se conserva ~94% de yellow y ~91% de green; la perdida es aceptable y elimina valores imposibles. Los analisis de distribuciones usan trips_clean; los conteos de volumen pueden usar trips.
