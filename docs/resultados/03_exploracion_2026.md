# Resultados de `sql/03_exploracion.sql`

Generado con `python scripts/run_sql.py sql/03_exploracion.sql` el 2026-10-07 01:52. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

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

**Resultado** (2 filas, 0.19 s):

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2026 | 8 | 2026-01 | 2026-08 |
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

**Resultado** (16 filas, 0.01 s):

| taxi_type | mes | registros | row_groups |
|---|---|---|---|
| green | 2026-01 | 40,272 | 1 |
| green | 2026-02 | 37,373 | 1 |
| green | 2026-03 | 44,208 | 1 |
| green | 2026-04 | 44,238 | 1 |
| green | 2026-05 | 44,921 | 1 |
| green | 2026-06 | 44,163 | 1 |
| green | 2026-07 | 41,252 | 1 |
| green | 2026-08 | 40,687 | 1 |
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

**Resultado** (3 filas, 0.01 s):

| taxi_type | registros |
|---|---|
| yellow | 29,703,355 |
| green | 337,114 |
| total | 30,040,469 |

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
| green | DOLocationID | 8 | 2026-01 | 2026-08 |
| green | PULocationID | 8 | 2026-01 | 2026-08 |
| green | RatecodeID | 8 | 2026-01 | 2026-08 |
| green | VendorID | 8 | 2026-01 | 2026-08 |
| green | cbd_congestion_fee | 8 | 2026-01 | 2026-08 |
| green | congestion_surcharge | 8 | 2026-01 | 2026-08 |
| green | ehail_fee | 8 | 2026-01 | 2026-08 |
| green | extra | 8 | 2026-01 | 2026-08 |
| green | fare_amount | 8 | 2026-01 | 2026-08 |
| green | improvement_surcharge | 8 | 2026-01 | 2026-08 |
| green | lpep_dropoff_datetime | 8 | 2026-01 | 2026-08 |
| green | lpep_pickup_datetime | 8 | 2026-01 | 2026-08 |
| green | mta_tax | 8 | 2026-01 | 2026-08 |
| green | passenger_count | 8 | 2026-01 | 2026-08 |
| green | payment_type | 8 | 2026-01 | 2026-08 |
| green | store_and_fwd_flag | 8 | 2026-01 | 2026-08 |
| green | tip_amount | 8 | 2026-01 | 2026-08 |
| green | tolls_amount | 8 | 2026-01 | 2026-08 |
| green | total_amount | 8 | 2026-01 | 2026-08 |
| green | trip_distance | 8 | 2026-01 | 2026-08 |
| green | trip_type | 8 | 2026-01 | 2026-08 |
| yellow | request_source | 3 | 2026-06 | 2026-08 |
| yellow | Airport_fee | 8 | 2026-01 | 2026-08 |
| yellow | DOLocationID | 8 | 2026-01 | 2026-08 |
| yellow | PULocationID | 8 | 2026-01 | 2026-08 |
| yellow | RatecodeID | 8 | 2026-01 | 2026-08 |
| yellow | VendorID | 8 | 2026-01 | 2026-08 |
| yellow | cbd_congestion_fee | 8 | 2026-01 | 2026-08 |
| yellow | congestion_surcharge | 8 | 2026-01 | 2026-08 |
| yellow | extra | 8 | 2026-01 | 2026-08 |
| yellow | fare_amount | 8 | 2026-01 | 2026-08 |
| yellow | improvement_surcharge | 8 | 2026-01 | 2026-08 |
| yellow | mta_tax | 8 | 2026-01 | 2026-08 |
| yellow | passenger_count | 8 | 2026-01 | 2026-08 |
| yellow | payment_type | 8 | 2026-01 | 2026-08 |
| yellow | store_and_fwd_flag | 8 | 2026-01 | 2026-08 |
| yellow | tip_amount | 8 | 2026-01 | 2026-08 |
| yellow | tolls_amount | 8 | 2026-01 | 2026-08 |
| yellow | total_amount | 8 | 2026-01 | 2026-08 |
| yellow | tpep_dropoff_datetime | 8 | 2026-01 | 2026-08 |
| yellow | tpep_pickup_datetime | 8 | 2026-01 | 2026-08 |
| yellow | trip_distance | 8 | 2026-01 | 2026-08 |

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

**Resultado** (8 filas, 0.08 s):

| VendorID | tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | RatecodeID | store_and_fwd_flag | PULocationID | DOLocationID | payment_type | fare_amount | extra | mta_tax | tip_amount | tolls_amount | improvement_surcharge | total_amount | congestion_surcharge | Airport_fee | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2026-01-01 00:24:41 | 2026-01-01 00:36:23 | 1 | 4.8 | 1 | N | 87 | 162 | 2 | 21.2 | 1 | 0.5 | 0 | 0 | 1 | 26.95 | 2.5 | 0 | 0.75 | NULL |
| 1 | 2026-01-01 02:08:35 | 2026-01-01 02:21:22 | 2 | 2.3 | 1 | N | 90 | 229 | 1 | 14.2 | 4.25 | 0.5 | 1.4 | 0 | 1 | 21.35 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-01-01 02:01:56 | 2026-01-01 02:17:20 | 1 | 5.69 | 1 | N | 80 | 95 | 2 | 26.1 | 1 | 0.5 | 0 | 0 | 1 | 28.6 | 0 | 0 | 0 | NULL |
| 2 | 2026-01-01 04:36:54 | 2026-01-01 04:48:35 | 1 | 2.56 | 1 | N | 68 | 79 | 1 | 14.2 | 1 | 0.5 | 3.99 | 0 | 1 | 23.94 | 2.5 | 0 | 0.75 | NULL |
| 1 | 2026-01-01 09:37:17 | 2026-01-01 09:42:10 | 1 | 0.8 | 1 | N | 239 | 142 | 1 | 6.5 | 2.5 | 0.5 | 2.1 | 0 | 1 | 12.6 | 2.5 | 0 | 0 | NULL |
| 2 | 2026-01-01 11:29:34 | 2026-01-01 11:36:19 | 1 | 0.74 | 1 | N | 161 | 163 | 1 | 7.9 | 0 | 0.5 | 3.16 | 0 | 1 | 15.81 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-01-01 11:42:55 | 2026-01-01 11:49:37 | 1 | 1.03 | 1 | N | 163 | 186 | 2 | 7.9 | 0 | 0.5 | 0 | 0 | 1 | 12.65 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-01-01 13:36:51 | 2026-01-01 13:45:33 | 1 | 0.8 | 1 | N | 186 | 48 | 2 | 8.6 | 0 | 0.5 | 0 | 0 | 1 | 13.35 | 2.5 | 0 | 0.75 | NULL |

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
| 2 | 2026-01-03 17:06:05 | 2026-01-03 17:11:27 | N | 1 | 74 | 41 | 1 | 1.15 | 7.2 | 0 | 0.5 | 4 | 0 | NULL | 1 | 12.7 | 1 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-11 22:28:43 | 2026-01-11 22:32:53 | N | 1 | 74 | 42 | 2 | 0 | 5.8 | 1 | 0.5 | 1.66 | 0 | NULL | 1 | 9.96 | 1 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-13 18:36:59 | 2026-01-13 18:41:12 | N | 1 | 43 | 238 | 1 | 1.08 | 7.2 | 2.5 | 0.5 | 3.49 | 0 | NULL | 1 | 17.44 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-01-16 15:15:45 | 2026-01-16 15:43:34 | N | 1 | 244 | 233 | 1 | 9.39 | 38 | 0 | 0.5 | 0 | 0 | NULL | 1 | 43 | 2 | 1 | 2.75 | 0.75 | NULL |
| 2 | 2026-01-20 15:12:55 | 2026-01-20 15:24:05 | N | 1 | 82 | 82 | 1 | 1.4 | 11.4 | 0 | 0.5 | 0 | 0 | NULL | 1 | 12.9 | 2 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-23 10:19:05 | 2026-01-23 10:37:24 | N | 1 | 74 | 238 | 1 | 3.02 | 18.4 | 0 | 0.5 | 4.53 | 0 | NULL | 1 | 27.18 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-01-24 15:40:48 | 2026-01-24 15:52:07 | N | 1 | 65 | 40 | 1 | 1.05 | 10.7 | 0 | 0.5 | 1.59 | 0 | NULL | 1 | 13.79 | 1 | 1 | 0 | 0 | NULL |
| 2 | 2026-01-30 00:16:28 | 2026-01-30 00:23:47 | N | 1 | 75 | 238 | 1 | 1.36 | 9.3 | 1 | 0.5 | 1.77 | 0 | NULL | 1 | 13.57 | 1 | 1 | 0 | 0 | NULL |

**Decision / interpretacion:** Green incluye trip_type (1 = calle, 2 = despacho) y ehail_fee (siempre NULL).

## q3_10_perfil_yellow

**Objetivo:** Perfil estadistico de todas las columnas (min, max, promedio, % nulos, cardinalidad aproximada) para detectar problemas de calidad (3.6).

**Fuente:** `read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)`

```sql
SUMMARIZE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
```

**Resultado** (21 filas, 7.93 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 7 | 4 | 1.885739809526567 | 0.7155277514022325 | 2 | 2 | 2 | 29,703,355 | 0 |
| tpep_pickup_datetime | TIMESTAMP | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 | 16,867,928 | 2026-04-30 15:29:29.519432 | NULL | 2026-03-03 22:28:49.154883 | 2026-05-01 00:02:10.120663 | 2026-06-25 20:36:45.111781 | 29,703,355 | 0 |
| tpep_dropoff_datetime | TIMESTAMP | 2001-01-01 16:09:38 | 2026-09-01 20:16:00 | 16,587,125 | 2026-04-30 15:47:08.186216 | NULL | 2026-03-03 15:48:11.371295 | 2026-05-01 09:18:36.145155 | 2026-06-25 23:01:57.009205 | 29,703,355 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.2494318488564 | 0.6529195072996774 | 1 | 1 | 1 | 29,703,355 | 25.98 |
| trip_distance | DOUBLE | 0.0 | 328522.2 | 7,217 | 5.55294014968999 | 550.6497893231013 | 1.023018968047314 | 1.8552800957667952 | 3.813268656440593 | 29,703,355 | 0 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 4.527471444398553 | 18.000926540066924 | 1 | 1 | 1 | 29,703,355 | 25.98 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 29,703,355 | 25.98 |
| PULocationID | INTEGER | 1 | 265 | 290 | 161.57793013617484 | 66.7465670325177 | 117 | 161 | 233 | 29,703,355 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 298 | 161.05139342003622 | 70.72548569211264 | 109 | 162 | 234 | 29,703,355 | 0 |
| payment_type | BIGINT | 0 | 5 | 6 | 0.8621735154160195 | 0.6463324345961675 | 0 | 1 | 1 | 29,703,355 | 0 |
| fare_amount | DOUBLE | -2555.2 | 7045.0 | 18,028 | 21.26212877906758 | 18.958296845957538 | 10.011765850716502 | 15.771025856371988 | 26.492713552586242 | 29,703,355 | 0 |
| extra | DOUBLE | -7.5 | 244.35 | 360 | 1.1127003451293658 | 1.7506914816701427 | 0.0 | 0.0 | 2.4999080282699593 | 29,703,355 | 0 |
| mta_tax | DOUBLE | -0.5 | 11.5 | 21 | 0.48825138305083715 | 0.09190423736483601 | 0.5 | 0.5 | 0.5 | 29,703,355 | 0 |
| tip_amount | DOUBLE | -222.0 | 766.0 | 6,049 | 2.8311150171416926 | 3.966576420508221 | 0.0 | 2.052882486593157 | 3.971090426698177 | 29,703,355 | 0 |
| tolls_amount | DOUBLE | -129.48 | 1400.0 | 3,451 | 0.5360736017854391 | 2.2270316740850857 | 0.0 | 0.0 | 0.0 | 29,703,355 | 0 |
| improvement_surcharge | DOUBLE | -1.0 | 4.0 | 6 | 0.9659906263113318 | 0.20791287266870812 | 1.0 | 1.0 | 1.0 | 29,703,355 | 0 |
| total_amount | DOUBLE | -2560.2 | 7053.5 | 38,649 | 30.069705772320734 | 22.7534080457322 | 17.39234756066503 | 23.604332249326657 | 34.544322098791746 | 29,703,355 | 0 |
| congestion_surcharge | DOUBLE | -2.5 | 2.75 | 7 | 2.216917730186208 | 0.8364476657907136 | 2.5 | 2.5 | 2.5 | 29,703,355 | 25.98 |
| Airport_fee | DOUBLE | -2.0 | 27.0 | 15 | 0.16706982008687357 | 0.5781861746411228 | 0.0 | 0.0 | 0.0 | 29,703,355 | 25.98 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.5355387211309968 | 0.3447052699155562 | 0.0 | 0.75 | 0.75 | 29,703,355 | 0 |
| request_source | VARCHAR | A | HV0005 | 3 | NULL | NULL | NULL | NULL | NULL | 29,703,355 | 90.23 |

**Decision / interpretacion:** Se detectan minimos negativos en montos, maximos absurdos en trip_distance y total_amount, fechas desde 2001 y ~26% de nulos en passenger_count/RatecodeID/congestion_surcharge/Airport_fee.

## q3_11_perfil_green

**Objetivo:** Perfil estadistico de las columnas de taxis verdes (3.6).

**Fuente:** `read_parquet('data/raw/green/*/*.parquet', union_by_name = true)`

```sql
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado** (22 filas, 0.11 s):

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 6 | 3 | 2.328351833504393 | 1.2771882973738604 | 2 | 2 | 2 | 337,114 | 0 |
| lpep_pickup_datetime | TIMESTAMP | 2008-12-31 17:35:31 | 2026-08-31 23:58:28 | 332,702 | 2026-05-02 13:25:51.096427 | NULL | 2026-03-06 05:12:47.4196 | 2026-05-05 07:15:34.597614 | 2026-06-27 09:16:27.96263 | 337,114 | 0 |
| lpep_dropoff_datetime | TIMESTAMP | 2008-12-31 23:16:26 | 2026-09-02 09:39:37 | 396,286 | 2026-05-02 13:46:38.833759 | NULL | 2026-03-06 05:47:19.691271 | 2026-05-03 20:35:12.633875 | 2026-06-28 06:19:34.557148 | 337,114 | 0 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 337,114 | 14.47 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 1.2549672434183374 | 1.0015327424296085 | 1 | 1 | 1 | 337,114 | 14.47 |
| PULocationID | INTEGER | 1 | 265 | 263 | 97.32761024460568 | 56.57830275002365 | 74 | 75 | 104 | 337,114 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 266 | 142.8768458147689 | 77.24476821098119 | 75 | 140 | 229 | 337,114 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.3006461144694266 | 0.9481007387491747 | 1 | 1 | 1 | 337,114 | 14.47 |
| trip_distance | DOUBLE | 0.0 | 179830.92 | 2,472 | 13.349507644298376 | 880.4035093234568 | 1.2539912998121256 | 2.067159680181641 | 3.6930247136163645 | 337,114 | 0 |
| fare_amount | DOUBLE | -500.0 | 1676.7 | 4,808 | 17.014101995170655 | 17.958627635270645 | 8.607198518913442 | 13.215621070131531 | 19.671286766303865 | 337,114 | 0 |
| extra | DOUBLE | -7.5 | 10.0 | 21 | 0.8195284087875319 | 1.3603053200356505 | 0.0 | 0.0 | 1.0 | 337,114 | 0 |
| mta_tax | DOUBLE | -0.5 | 5.0 | 7 | 0.5467816524973748 | 0.30968692134078063 | 0.5 | 0.5 | 0.5 | 337,114 | 0 |
| tip_amount | DOUBLE | -14.0 | 495.0 | 2,212 | 2.6208176165926957 | 5.399358172149612 | 0.0 | 2.0100905463126004 | 3.8565457157563636 | 337,114 | 0 |
| tolls_amount | DOUBLE | -24.5 | 85.0 | 75 | 0.2941987576902671 | 1.55521689955519 | 0.0 | 0.0 | 0.0 | 337,114 | 0 |
| ehail_fee | DOUBLE | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL | 337,114 | 100 |
| improvement_surcharge | DOUBLE | -1.0 | 1.0 | 5 | 0.9152746548647911 | 0.25186030830555645 | 1.0 | 1.0 | 1.0 | 337,114 | 0 |
| total_amount | DOUBLE | -501.5 | 1678.2 | 8,186 | 25.492562070990623 | 20.552777231768655 | 14.94504954341301 | 20.459621966801244 | 29.683980308863156 | 337,114 | 0 |
| payment_type | BIGINT | 1 | 4 | 4 | 1.2481350077512927 | 0.4624714451219807 | 1 | 1 | 1 | 337,114 | 14.47 |
| trip_type | BIGINT | 1 | 2 | 2 | 1.0518525197945459 | 0.22172957965580276 | 1 | 1 | 1 | 337,114 | 14.47 |
| congestion_surcharge | DOUBLE | -2.75 | 2.75 | 5 | 0.8831271524143456 | 1.2846843025235135 | 0.0 | 0.0 | 2.75 | 337,114 | 14.47 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.06234018759232782 | 0.20713685724463024 | 0.0 | 0.0 | 0.0 | 337,114 | 0 |
| request_source | VARCHAR | A | HV0005 | 2 | NULL | NULL | NULL | NULL | NULL | 337,114 | 94.3 |

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

**Resultado** (30 filas, 0.51 s):

| taxi_type | problema | registros |
|---|---|---|
| green | distancia_cero | 12,212 |
| yellow | distancia_cero | 952,231 |
| green | distancia_mayor_100mi | 72 |
| yellow | distancia_mayor_100mi | 1,223 |
| green | duracion_cero_o_negativa | 234 |
| yellow | duracion_cero_o_negativa | 371,683 |
| green | duracion_mayor_3h | 1,287 |
| yellow | duracion_mayor_3h | 10,127 |
| green | passenger_count_cero | 4,527 |
| yellow | passenger_count_cero | 91,359 |
| green | passenger_count_mayor_6 | 99 |
| yellow | passenger_count_mayor_6 | 28 |
| green | passenger_count_nulo | 48,775 |
| yellow | passenger_count_nulo | 7,716,688 |
| green | payment_type_desconocido | 48,775 |
| yellow | payment_type_desconocido | 7,716,688 |
| green | pickup_fuera_del_mes_del_archivo | 98 |
| yellow | pickup_fuera_del_mes_del_archivo | 146 |
| green | propina_negativa | 69 |
| yellow | propina_negativa | 883 |
| green | ratecode_99_invalido | 2 |
| yellow | ratecode_99_invalido | 769,693 |
| green | tarifa_negativa | 999 |
| yellow | tarifa_negativa | 157,364 |
| green | total_mayor_1000 | 1 |
| yellow | total_mayor_1000 | 54 |
| green | total_negativo | 1,023 |
| yellow | total_negativo | 161,835 |
| green | total_registros | 337,114 |
| yellow | total_registros | 29,703,355 |

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

**Resultado** (20 filas, 0.10 s):

| taxi_type | mes_pickup | mes_archivo | registros |
|---|---|---|---|
| yellow | 2026-08 | 2026-07 | 38 |
| green | 2026-02 | 2026-01 | 18 |
| yellow | 2026-02 | 2026-03 | 15 |
| yellow | 2026-04 | 2026-06 | 15 |
| yellow | 2026-07 | 2026-08 | 14 |
| green | 2026-05 | 2026-06 | 12 |
| yellow | 2026-01 | 2026-02 | 12 |
| green | 2026-07 | 2026-08 | 12 |
| yellow | 2026-04 | 2026-05 | 11 |
| green | 2026-02 | 2026-03 | 8 |
| green | 2026-04 | 2026-05 | 8 |
| green | 2026-01 | 2026-02 | 8 |
| yellow | 2026-06 | 2026-07 | 7 |
| yellow | 2026-03 | 2026-04 | 7 |
| green | 2026-06 | 2026-07 | 6 |
| yellow | 2025-12 | 2026-01 | 6 |
| green | 2026-08 | 2026-07 | 5 |
| green | 2025-12 | 2026-01 | 4 |
| yellow | 2026-03 | 2026-02 | 4 |
| green | 2009-01 | 2026-07 | 3 |

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

**Resultado** (34 filas, 0.41 s):

| taxi_type | columna | codigo | registros | pct |
|---|---|---|---|---|
| green | payment_type | 1 | 219,980 | 65.25 |
| green | payment_type | 2 | 65,921 | 19.55 |
| green | payment_type | NULL | 48,775 | 14.47 |
| green | payment_type | 3 | 1,688 | 0.5 |
| green | payment_type | 4 | 750 | 0.22 |
| green | ratecode_id | 1 | 269,152 | 79.84 |
| green | ratecode_id | NULL | 48,775 | 14.47 |
| green | ratecode_id | 5 | 17,739 | 5.26 |
| green | ratecode_id | 2 | 887 | 0.26 |
| green | ratecode_id | 4 | 354 | 0.11 |
| green | ratecode_id | 3 | 203 | 0.06 |
| green | ratecode_id | 6 | 2 | 0 |
| green | ratecode_id | 99 | 2 | 0 |
| green | vendor_id | 2 | 273,571 | 81.15 |
| green | vendor_id | 6 | 34,847 | 10.34 |
| green | vendor_id | 1 | 28,696 | 8.51 |
| yellow | payment_type | 1 | 18,941,008 | 63.77 |
| yellow | payment_type | 0 | 7,716,688 | 25.98 |
| yellow | payment_type | 2 | 2,708,031 | 9.12 |
| yellow | payment_type | 4 | 239,488 | 0.81 |
| yellow | payment_type | 3 | 98,138 | 0.33 |
| yellow | payment_type | 5 | 2 | 0 |
| yellow | ratecode_id | 1 | 20,102,072 | 67.68 |
| yellow | ratecode_id | NULL | 7,716,688 | 25.98 |
| yellow | ratecode_id | 99 | 769,693 | 2.59 |
| yellow | ratecode_id | 2 | 694,936 | 2.34 |
| yellow | ratecode_id | 5 | 262,614 | 0.88 |
| yellow | ratecode_id | 3 | 90,052 | 0.3 |
| yellow | ratecode_id | 4 | 67,285 | 0.23 |
| yellow | ratecode_id | 6 | 15 | 0 |
| yellow | vendor_id | 2 | 23,809,774 | 80.16 |
| yellow | vendor_id | 1 | 5,467,071 | 18.41 |
| yellow | vendor_id | 7 | 367,120 | 1.24 |
| yellow | vendor_id | 6 | 59,390 | 0.2 |

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

**Resultado** (2 filas, 0.39 s):

| taxi_type | registros_originales | registros_limpios | descartados | pct_conservado |
|---|---|---|---|---|
| yellow | 29,703,355 | 27,884,915 | 1,818,440 | 93.88 |
| green | 337,114 | 309,437 | 27,677 | 91.79 |

**Decision / interpretacion:** Se conserva ~94% de yellow y ~91% de green; la perdida es aceptable y elimina valores imposibles. Los analisis de distribuciones usan trips_clean; los conteos de volumen pueden usar trips.
