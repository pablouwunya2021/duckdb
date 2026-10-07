# Resultados de `sql/03_exploracion.sql`

Generado con `python scripts/run_sql.py sql/03_exploracion.sql` el 2026-10-07 01:56. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

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

**Resultado** (4 filas, 0.17 s):

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2024 | 12 | 2024-01 | 2024-12 |
| green | 2026 | 8 | 2026-01 | 2026-08 |
| yellow | 2024 | 12 | 2024-01 | 2024-12 |
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

**Resultado** (40 filas, 0.01 s):

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
| yellow | 70,873,075 |
| green | 997,332 |
| total | 71,870,407 |

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
| green | cbd_congestion_fee | 8 | 2026-01 | 2026-08 |
| green | DOLocationID | 20 | 2024-01 | 2026-08 |
| green | PULocationID | 20 | 2024-01 | 2026-08 |
| green | RatecodeID | 20 | 2024-01 | 2026-08 |
| green | VendorID | 20 | 2024-01 | 2026-08 |
| green | congestion_surcharge | 20 | 2024-01 | 2026-08 |
| green | ehail_fee | 20 | 2024-01 | 2026-08 |
| green | extra | 20 | 2024-01 | 2026-08 |
| green | fare_amount | 20 | 2024-01 | 2026-08 |
| green | improvement_surcharge | 20 | 2024-01 | 2026-08 |
| green | lpep_dropoff_datetime | 20 | 2024-01 | 2026-08 |
| green | lpep_pickup_datetime | 20 | 2024-01 | 2026-08 |
| green | mta_tax | 20 | 2024-01 | 2026-08 |
| green | passenger_count | 20 | 2024-01 | 2026-08 |
| green | payment_type | 20 | 2024-01 | 2026-08 |
| green | store_and_fwd_flag | 20 | 2024-01 | 2026-08 |
| green | tip_amount | 20 | 2024-01 | 2026-08 |
| green | tolls_amount | 20 | 2024-01 | 2026-08 |
| green | total_amount | 20 | 2024-01 | 2026-08 |
| green | trip_distance | 20 | 2024-01 | 2026-08 |
| green | trip_type | 20 | 2024-01 | 2026-08 |
| yellow | request_source | 3 | 2026-06 | 2026-08 |
| yellow | cbd_congestion_fee | 8 | 2026-01 | 2026-08 |
| yellow | Airport_fee | 20 | 2024-01 | 2026-08 |
| yellow | DOLocationID | 20 | 2024-01 | 2026-08 |
| yellow | PULocationID | 20 | 2024-01 | 2026-08 |
| yellow | RatecodeID | 20 | 2024-01 | 2026-08 |
| yellow | VendorID | 20 | 2024-01 | 2026-08 |
| yellow | congestion_surcharge | 20 | 2024-01 | 2026-08 |
| yellow | extra | 20 | 2024-01 | 2026-08 |
| yellow | fare_amount | 20 | 2024-01 | 2026-08 |
| yellow | improvement_surcharge | 20 | 2024-01 | 2026-08 |
| yellow | mta_tax | 20 | 2024-01 | 2026-08 |
| yellow | passenger_count | 20 | 2024-01 | 2026-08 |
| yellow | payment_type | 20 | 2024-01 | 2026-08 |
| yellow | store_and_fwd_flag | 20 | 2024-01 | 2026-08 |
| yellow | tip_amount | 20 | 2024-01 | 2026-08 |
| yellow | tolls_amount | 20 | 2024-01 | 2026-08 |
| yellow | total_amount | 20 | 2024-01 | 2026-08 |
| yellow | tpep_dropoff_datetime | 20 | 2024-01 | 2026-08 |
| yellow | tpep_pickup_datetime | 20 | 2024-01 | 2026-08 |
| yellow | trip_distance | 20 | 2024-01 | 2026-08 |

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

**Resultado** (20 filas, 0.00 s):

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

**Resultado** (8 filas, 0.11 s):

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

**Resultado** (8 filas, 0.01 s):

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

**Resultado** (21 filas, 18.48 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 7 | 4 | 1.8151568420024107 | 0.5687845418932025 | 2 | 2 | 2 | 70,873,075 | 0 |
| tpep_pickup_datetime | TIMESTAMP | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 | 41,962,329 | 2025-04-10 09:08:07.177432 | NULL | 2024-06-09 06:40:56.355401 | 2024-11-14 22:10:21.857855 | 2026-04-07 20:53:17.238068 | 70,873,075 | 0 |
| tpep_dropoff_datetime | TIMESTAMP | 2001-01-01 16:09:38 | 2026-09-01 20:16:00 | 44,326,272 | 2025-04-10 09:25:39.691221 | NULL | 2024-06-10 12:00:37.849408 | 2024-11-15 06:44:12.592413 | 2026-04-08 20:57:55.929558 | 70,873,075 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.3024764431753375 | 0.7603765421670503 | 1 | 1 | 1 | 70,873,075 | 16.66 |
| trip_distance | DOUBLE | 0.0 | 398608.62 | 9,128 | 5.2178578194908924 | 478.7212052238807 | 1.018975228665586 | 1.7944007066296466 | 3.538228815722947 | 70,873,075 | 0 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 3.143068311595898 | 14.025835079929308 | 1 | 1 | 1 | 70,873,075 | 16.66 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 70,873,075 | 16.66 |
| PULocationID | INTEGER | 1 | 265 | 298 | 163.12592827388963 | 65.37301320360986 | 128 | 161 | 233 | 70,873,075 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 298 | 162.44324911823003 | 70.08392240165534 | 112 | 162 | 234 | 70,873,075 | 0 |
| payment_type | BIGINT | 0 | 5 | 6 | 1.0045423597043024 | 0.6605099300579501 | 1 | 1 | 1 | 70,873,075 | 0 |
| fare_amount | DOUBLE | -2555.2 | 335544.44 | 24,784 | 20.10404811105485 | 59.7553614361137 | 9.3406202362841 | 14.506444138391922 | 24.131559216381664 | 70,873,075 | 0 |
| extra | DOUBLE | -9.25 | 244.35 | 464 | 1.2714311202103141 | 1.7939209318549747 | 0.0 | 0.007744135103003368 | 2.5 | 70,873,075 | 0 |
| mta_tax | DOUBLE | -0.5 | 41.3 | 38 | 0.48332890494733083 | 0.11576779498489907 | 0.5 | 0.5 | 0.5 | 70,873,075 | 0 |
| tip_amount | DOUBLE | -300.0 | 999.99 | 7,653 | 3.108067107857742 | 4.045884042502701 | 0.0 | 2.4344999809493806 | 4.113413040237146 | 70,873,075 | 0 |
| tolls_amount | DOUBLE | -140.63 | 1702.88 | 4,565 | 0.5508590940890471 | 2.2349268150065393 | 0.0 | 0.0 | 0.0 | 70,873,075 | 0 |
| improvement_surcharge | DOUBLE | -1.0 | 4.0 | 10 | 0.9642495432854998 | 0.23644926315353695 | 1.0 | 1.0 | 1.0 | 70,873,075 | 0 |
| total_amount | DOUBLE | -2560.2 | 335550.94 | 50,956 | 28.77030904918586 | 61.29609702372776 | 16.37324550231251 | 22.027683834844936 | 32.30349942532899 | 70,873,075 | 0 |
| congestion_surcharge | DOUBLE | -2.5 | 2.75 | 11 | 2.226476273024256 | 0.8606608247041208 | 2.5 | 2.5 | 2.5 | 70,873,075 | 16.66 |
| Airport_fee | DOUBLE | -2.0 | 27.0 | 16 | 0.15447461790289047 | 0.5317496060548357 | 0.0 | 0.0 | 0.0 | 70,873,075 | 16.66 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.5355387211309968 | 0.344705269915557 | 0.0 | 0.75 | 0.75 | 70,873,075 | 58.09 |
| request_source | VARCHAR | A | HV0005 | 3 | NULL | NULL | NULL | NULL | NULL | 70,873,075 | 95.9 |

**Decision / interpretacion:** Se detectan minimos negativos en montos, maximos absurdos en trip_distance y total_amount, fechas desde 2001 y ~26% de nulos en passenger_count/RatecodeID/congestion_surcharge/Airport_fee.

## q3_11_perfil_green

**Objetivo:** Perfil estadistico de las columnas de taxis verdes (3.6).

**Fuente:** `read_parquet('data/raw/green/*/*.parquet', union_by_name = true)`

```sql
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado** (22 filas, 0.28 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 6 | 3 | 2.030322901501205 | 0.8170451025850339 | 2 | 2 | 2 | 997,332 | 0 |
| lpep_pickup_datetime | TIMESTAMP | 2008-12-31 00:00:00 | 2026-08-31 23:58:28 | 1,035,093 | 2025-02-11 15:07:53.76982 | NULL | 2024-05-14 05:29:16.554458 | 2024-09-29 08:28:47.4636 | 2026-03-08 04:14:34.009022 | 997,332 | 0 |
| lpep_dropoff_datetime | TIMESTAMP | 2008-12-31 00:00:00 | 2026-09-02 09:39:37 | 1,290,902 | 2025-02-11 15:27:55.083787 | NULL | 2024-05-15 15:05:02.761495 | 2024-10-01 06:57:36.589998 | 2026-03-07 03:04:07.118205 | 997,332 | 0 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 997,332 | 7.33 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 1.2272694321428996 | 1.2960121666703373 | 1 | 1 | 1 | 997,332 | 7.33 |
| PULocationID | INTEGER | 1 | 265 | 266 | 96.70922822089334 | 57.022355121341036 | 74 | 75 | 103 | 997,332 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 266 | 141.82127415945743 | 76.84107286162029 | 74 | 140 | 227 | 997,332 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.3118859070641584 | 0.9705271926655927 | 1 | 1 | 1 | 997,332 | 7.33 |
| trip_distance | DOUBLE | 0.0 | 233972.43 | 3,072 | 15.779716874621576 | 969.0617511794616 | 1.175299016956849 | 1.9283686522087875 | 3.4170418575226096 | 997,332 | 0 |
| fare_amount | DOUBLE | -500.0 | 1676.7 | 6,569 | 17.902603646528924 | 17.540088603720562 | 9.300945348450622 | 13.558447153750011 | 20.42486791731944 | 997,332 | 0 |
| extra | DOUBLE | -7.5 | 12.0 | 27 | 0.8929476743952867 | 1.3892603289634484 | 0.0 | 0.0 | 1.0004308401428843 | 997,332 | 0 |
| mta_tax | DOUBLE | -0.5 | 5.0 | 9 | 0.5659712613252157 | 0.3472997898440147 | 0.5 | 0.5 | 0.5 | 997,332 | 0 |
| tip_amount | DOUBLE | -65.0 | 495.0 | 2,509 | 2.5899862332703143 | 4.2019199078653795 | 0.0 | 2.0155726204445235 | 3.8372469283331325 | 997,332 | 0 |
| tolls_amount | DOUBLE | -24.5 | 85.0 | 147 | 0.2531391251859841 | 1.4145422564587782 | 0.0 | 0.0 | 0.0 | 997,332 | 0 |
| ehail_fee | DOUBLE | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL | 997,332 | 100 |
| improvement_surcharge | DOUBLE | -1.0 | 1.0 | 5 | 0.9582444963162751 | 0.19404178257934301 | 1.0 | 1.0 | 1.0 | 997,332 | 0 |
| total_amount | DOUBLE | -501.5 | 1678.2 | 11,049 | 24.67977087870415 | 19.85554688362604 | 14.168220601908684 | 19.721683738953846 | 28.765954501820417 | 997,332 | 0 |
| payment_type | BIGINT | 1 | 5 | 5 | 1.2819203898600888 | 0.48106949258502596 | 1 | 1 | 2 | 997,332 | 7.33 |
| trip_type | BIGINT | 1 | 2 | 2 | 1.0475466512289737 | 0.21280511316468487 | 1 | 1 | 1 | 997,332 | 7.34 |
| congestion_surcharge | DOUBLE | -2.75 | 2.75 | 6 | 0.8348482897636841 | 1.2637901318318399 | 0.0 | 0.0 | 2.75 | 997,332 | 7.33 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.06234018759232782 | 0.20713685724463024 | 0.0 | 0.0 | 0.0 | 997,332 | 66.2 |
| request_source | VARCHAR | A | HV0005 | 2 | NULL | NULL | NULL | NULL | NULL | 997,332 | 98.07 |

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

**Resultado** (30 filas, 1.18 s):

| taxi_type | problema | registros |
|---|---|---|
| green | distancia_cero | 46,786 |
| yellow | distancia_cero | 1,728,536 |
| green | distancia_mayor_100mi | 307 |
| yellow | distancia_mayor_100mi | 2,836 |
| green | duracion_cero_o_negativa | 896 |
| yellow | duracion_cero_o_negativa | 385,193 |
| green | duracion_mayor_3h | 4,266 |
| yellow | duracion_mayor_3h | 35,476 |
| green | passenger_count_cero | 11,320 |
| yellow | passenger_count_cero | 492,713 |
| green | passenger_count_mayor_6 | 247 |
| yellow | passenger_count_mayor_6 | 312 |
| green | passenger_count_nulo | 73,103 |
| yellow | passenger_count_nulo | 11,807,920 |
| green | payment_type_desconocido | 73,103 |
| yellow | payment_type_desconocido | 11,807,920 |
| green | pickup_fuera_del_mes_del_archivo | 262 |
| yellow | pickup_fuera_del_mes_del_archivo | 566 |
| green | propina_negativa | 128 |
| yellow | propina_negativa | 2,214 |
| green | ratecode_99_invalido | 84 |
| yellow | ratecode_99_invalido | 1,236,667 |
| green | tarifa_negativa | 3,143 |
| yellow | tarifa_negativa | 888,388 |
| green | total_mayor_1000 | 2 |
| yellow | total_mayor_1000 | 106 |
| green | total_negativo | 3,197 |
| yellow | total_negativo | 771,179 |
| green | total_registros | 997,332 |
| yellow | total_registros | 70,873,075 |

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

**Resultado** (20 filas, 0.24 s):

| taxi_type | mes_pickup | mes_archivo | registros |
|---|---|---|---|
| yellow | 2024-05 | 2024-06 | 42 |
| yellow | 2026-08 | 2026-07 | 38 |
| yellow | 2024-10 | 2024-11 | 34 |
| yellow | 2024-09 | 2024-08 | 32 |
| yellow | 2024-08 | 2024-09 | 31 |
| green | 2024-08 | 2024-09 | 30 |
| yellow | 2024-08 | 2024-07 | 29 |
| yellow | 2024-11 | 2024-10 | 27 |
| yellow | 2024-11 | 2024-12 | 26 |
| green | 2024-08 | 2024-07 | 25 |
| yellow | 2024-02 | 2024-03 | 19 |
| green | 2026-02 | 2026-01 | 18 |
| yellow | 2024-07 | 2024-08 | 17 |
| yellow | 2024-06 | 2024-07 | 15 |
| yellow | 2026-02 | 2026-03 | 15 |
| yellow | 2024-10 | 2024-09 | 15 |
| yellow | 2026-04 | 2026-06 | 15 |
| yellow | 2026-07 | 2026-08 | 14 |
| yellow | 2024-12 | 2024-11 | 13 |
| green | 2024-05 | 2024-06 | 13 |

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

**Resultado** (35 filas, 0.89 s):

| taxi_type | columna | codigo | registros | pct |
|---|---|---|---|---|
| green | payment_type | 1 | 674,667 | 67.65 |
| green | payment_type | 2 | 240,934 | 24.16 |
| green | payment_type | NULL | 73,103 | 7.33 |
| green | payment_type | 3 | 6,288 | 0.63 |
| green | payment_type | 4 | 2,311 | 0.23 |
| green | payment_type | 5 | 29 | 0 |
| green | ratecode_id | 1 | 871,065 | 87.34 |
| green | ratecode_id | NULL | 73,103 | 7.33 |
| green | ratecode_id | 5 | 48,641 | 4.88 |
| green | ratecode_id | 2 | 2,728 | 0.27 |
| green | ratecode_id | 4 | 1,085 | 0.11 |
| green | ratecode_id | 3 | 620 | 0.06 |
| green | ratecode_id | 99 | 84 | 0.01 |
| green | ratecode_id | 6 | 6 | 0 |
| green | vendor_id | 2 | 853,339 | 85.56 |
| green | vendor_id | 1 | 109,146 | 10.94 |
| green | vendor_id | 6 | 34,847 | 3.49 |
| yellow | payment_type | 1 | 49,393,167 | 69.69 |
| yellow | payment_type | 0 | 11,807,920 | 16.66 |
| yellow | payment_type | 2 | 8,248,119 | 11.64 |
| yellow | payment_type | 4 | 1,033,982 | 1.46 |
| yellow | payment_type | 3 | 389,881 | 0.55 |
| yellow | payment_type | 5 | 6 | 0 |
| yellow | ratecode_id | 1 | 54,753,099 | 77.26 |
| yellow | ratecode_id | NULL | 11,807,920 | 16.66 |
| yellow | ratecode_id | 2 | 2,101,806 | 2.97 |
| yellow | ratecode_id | 99 | 1,236,667 | 1.74 |
| yellow | ratecode_id | 5 | 584,562 | 0.82 |
| yellow | ratecode_id | 3 | 220,003 | 0.31 |
| yellow | ratecode_id | 4 | 168,927 | 0.24 |
| yellow | ratecode_id | 6 | 91 | 0 |
| yellow | vendor_id | 2 | 55,261,277 | 77.97 |
| yellow | vendor_id | 1 | 15,182,989 | 21.42 |
| yellow | vendor_id | 7 | 367,350 | 0.52 |
| yellow | vendor_id | 6 | 61,459 | 0.09 |

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

**Resultado** (2 filas, 0.90 s):

| taxi_type | registros_originales | registros_limpios | descartados | pct_conservado |
|---|---|---|---|---|
| yellow | 70,873,075 | 66,998,959 | 3,874,116 | 94.53 |
| green | 997,332 | 916,025 | 81,307 | 91.85 |

**Decision / interpretacion:** Se conserva ~94% de yellow y ~91% de green; la perdida es aceptable y elimina valores imposibles. Los analisis de distribuciones usan trips_clean; los conteos de volumen pueden usar trips.
