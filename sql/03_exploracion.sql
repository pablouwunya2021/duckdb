-- =============================================================================
-- 03_exploracion.sql - Ejercicio 3: consultas directas sobre archivos Parquet
-- =============================================================================
-- Todas las consultas leen los Parquet directamente con read_parquet / glob /
-- parquet_metadata; no se crea ninguna tabla. Se ejecutan y documentan con:
--     python scripts/run_sql.py sql/03_exploracion.sql
-- =============================================================================

-- name: q3_01_cantidad_archivos
-- objetivo: Determinar cuantos archivos Parquet hay disponibles por tipo de taxi y anio (3.1).
-- fuente: glob('data/raw/*/*/*.parquet')
-- decision: El conteo coincide con los meses publicados por la TLC reportados por download_data.py; se confirma que no falta ningun archivo antes de seguir.
SELECT regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 1) AS taxi_type,
       regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 2) AS anio,
       count(*)                               AS archivos,
       min(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS primer_mes,
       max(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY ALL;

-- name: q3_02_registros_por_archivo
-- objetivo: Determinar la cantidad de registros de cada archivo leyendo solo los metadatos del footer Parquet, sin escanear datos (3.2).
-- fuente: parquet_file_metadata('data/raw/*/*/*.parquet')
-- decision: Yellow aporta ~99% de los registros; green es ~90 veces mas pequeno, por lo que las comparaciones entre ambos deben usar proporciones/promedios y no totales absolutos.
SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1) AS taxi_type,
       regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1) AS mes,
       num_rows                         AS registros,
       num_row_groups                   AS row_groups
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
ORDER BY taxi_type, mes;

-- name: q3_03_registros_totales
-- objetivo: Total de registros disponibles por tipo, contando con un escaneo real (COUNT(*)) para contrastarlo con los metadatos (3.2).
-- fuente: read_parquet('data/raw/yellow/*/*.parquet'), read_parquet('data/raw/green/*/*.parquet')
-- decision: COUNT(*) coincide exactamente con la suma de num_rows de los metadatos: los archivos estan completos y DuckDB resuelve el conteo usando los metadatos (muy rapido).
SELECT 'yellow' AS taxi_type, count(*) AS registros FROM read_parquet('data/raw/yellow/*/*.parquet')
UNION ALL
SELECT 'green', count(*) FROM read_parquet('data/raw/green/*/*.parquet')
UNION ALL
SELECT 'total', count(*) FROM read_parquet('data/raw/*/*/*.parquet', union_by_name = true);

-- name: q3_04_columnas_por_archivo
-- objetivo: Identificar las columnas presentes y si estan en todos los archivos (evolucion del esquema) (3.3).
-- fuente: parquet_schema('data/raw/*/*/*.parquet')
-- decision: El esquema NO es constante: request_source aparece a partir de junio 2026 y yellow/green difieren (tpep_ vs lpep_, Airport_fee solo yellow, ehail_fee/trip_type solo green). Por eso todas las lecturas usan union_by_name=true y se creo la vista normalizada `trips`.
SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1)  AS taxi_type,
       name                           AS columna,
       count(DISTINCT file_name)      AS archivos_con_columna,
       min(regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1)) AS desde,
       max(regexp_extract(file_name, '(\d{4}-\d{2})\.parquet$', 1)) AS hasta
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE name NOT IN ('schema', 'duckdb_schema')
GROUP BY ALL
ORDER BY taxi_type, archivos_con_columna, columna;

-- name: q3_05_tipos_yellow
-- objetivo: Determinar los tipos de datos (DuckDB) de las columnas de taxis amarillos (3.4).
-- fuente: read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
-- decision: Fechas ya vienen como TIMESTAMP (no hay que parsear texto); montos DOUBLE; passenger_count, RatecodeID y payment_type son BIGINT aunque son categoricos/pequenos. store_and_fwd_flag es VARCHAR (Y/N).
DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);

-- name: q3_06_tipos_green
-- objetivo: Determinar los tipos de datos (DuckDB) de las columnas de taxis verdes (3.4).
-- fuente: read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
-- decision: Mismos tipos que yellow para las columnas comunes; se pueden unir con UNION ALL BY NAME tras renombrar lpep_* -> pickup/dropoff.
DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);

-- name: q3_07_tipos_fisicos_parquet
-- objetivo: Ver los tipos fisicos/logicos y la compresion con que estan guardadas las columnas en un archivo (3.4).
-- fuente: parquet_metadata('data/raw/yellow/2026/yellow_tripdata_2026-01.parquet')
-- decision: Columnas comprimidas con ZSTD y codificacion por diccionario; esto explica el tamano pequeno (~60 MB por 3.7 M filas) y por que leer solo algunas columnas es barato.
SELECT path_in_schema AS columna, type AS tipo_fisico, compression,
       sum(total_compressed_size)   AS bytes_comprimidos,
       sum(total_uncompressed_size) AS bytes_sin_comprimir,
       round(sum(total_uncompressed_size) / sum(total_compressed_size), 1) AS ratio
FROM parquet_metadata('data/raw/yellow/2026/yellow_tripdata_2026-01.parquet')
GROUP BY ALL
ORDER BY bytes_comprimidos DESC;

-- name: q3_08_muestra_yellow
-- objetivo: Obtener una muestra reproducible de registros de taxis amarillos (3.5).
-- fuente: read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
-- decision: Se observan registros con passenger_count/RatecodeID NULL y payment_type 0, que hay que tratar como "desconocido".
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);

-- name: q3_09_muestra_green
-- objetivo: Obtener una muestra reproducible de registros de taxis verdes (3.5).
-- fuente: read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
-- decision: Green incluye trip_type (1 = calle, 2 = despacho) y ehail_fee (siempre NULL).
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(8 ROWS) REPEATABLE (42);

-- name: q3_10_perfil_yellow
-- objetivo: Perfil estadistico de todas las columnas (min, max, promedio, % nulos, cardinalidad aproximada) para detectar problemas de calidad (3.6).
-- fuente: read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
-- decision: Se detectan minimos negativos en montos, maximos absurdos en trip_distance y total_amount, fechas desde 2001 y ~26% de nulos en passenger_count/RatecodeID/congestion_surcharge/Airport_fee.
SUMMARIZE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);

-- name: q3_11_perfil_green
-- objetivo: Perfil estadistico de las columnas de taxis verdes (3.6).
-- fuente: read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
-- decision: ehail_fee es 100% NULL (columna inutil); green tambien tiene montos negativos y distancias extremas.
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);

-- name: q3_12_problemas_calidad
-- objetivo: Cuantificar cada problema de calidad detectado, por tipo de taxi (3.6).
-- fuente: vista trips (lee data/raw/*/*/*.parquet)
-- decision: Con estos conteos se definieron las reglas de la vista trips_clean (sql/00_vistas.sql). Ninguna regla elimina mas de ~4% de los datos excepto la combinacion de distancia 0 y duracion invalida; los nulos de passenger_count NO se eliminan porque representan 26% de yellow.
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

-- name: q3_13_fechas_fuera_de_rango
-- objetivo: Ver de que fechas son los registros cuyo pickup no corresponde al mes del archivo (3.6).
-- fuente: vista trips (lee data/raw/*/*/*.parquet)
-- decision: Son pocos (cientos) pero llegan hasta 2001/2008: errores de reloj del taximetro. Se descartan en trips_clean filtrando pickup dentro del anio/mes del archivo, asi las series temporales no tienen puntos fantasma.
SELECT taxi_type, strftime(pickup_datetime, '%Y-%m') AS mes_pickup,
       file_year || '-' || lpad(file_month::VARCHAR, 2, '0') AS mes_archivo, count(*) AS registros
FROM trips
WHERE year(pickup_datetime) <> file_year OR month(pickup_datetime) <> file_month
GROUP BY ALL
ORDER BY registros DESC
LIMIT 20;

-- name: q3_14_codigos_categoricos
-- objetivo: Revisar los valores de las columnas categoricas contra el diccionario de datos de la TLC (3.6).
-- fuente: vista trips (lee data/raw/*/*/*.parquet)
-- decision: payment_type 0 (no documentado en el diccionario historico; corresponde a "Flex Fare"/desconocido) concentra 26% de yellow, exactamente los registros con passenger_count NULL. RatecodeID 99 no existe en el diccionario. Se trataran como categoria "desconocido".
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

-- name: q3_15_request_source
-- objetivo: Explorar la nueva columna request_source que aparece a mitad de 2026 (3.3 / 3.6).
-- fuente: read_parquet('data/raw/*/2026/*.parquet', union_by_name = true, filename = true)
-- decision: Es NULL en todos los archivos anteriores a junio 2026 (no existia). Desde junio identifica el origen del viaje (HV0003 = Uber, HV0005 = Lyft, A/CC/EH = apps y despacho). Solo se puede analizar desde junio 2026.
SELECT regexp_extract(filename, '(yellow|green)_tripdata_(\d{4}-\d{2})', 1) AS taxi_type,
       regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)               AS mes,
       coalesce(request_source, 'NULL') AS request_source,
       count(*) AS registros
FROM read_parquet('data/raw/*/2026/*.parquet', union_by_name = true, filename = true)
WHERE regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1) >= '2026-05'
GROUP BY ALL
ORDER BY taxi_type, mes, registros DESC;

-- name: q3_16_impacto_limpieza
-- objetivo: Medir cuantos registros conserva la vista trips_clean despues de aplicar las reglas de calidad (3.6).
-- fuente: vistas trips y trips_clean (leen data/raw/*/*/*.parquet)
-- decision: Se conserva ~94% de yellow y ~91% de green; la perdida es aceptable y elimina valores imposibles. Los analisis de distribuciones usan trips_clean; los conteos de volumen pueden usar trips.
SELECT t.taxi_type, t.registros AS registros_originales, c.registros AS registros_limpios,
       t.registros - c.registros AS descartados,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado
FROM (SELECT taxi_type, count(*) AS registros FROM trips GROUP BY 1) t
JOIN (SELECT taxi_type, count(*) AS registros FROM trips_clean GROUP BY 1) c USING (taxi_type)
ORDER BY t.taxi_type DESC;
