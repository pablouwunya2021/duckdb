-- =============================================================================
-- 05_validacion_2024.sql - Ejercicio 5: validar la incorporacion de 2024
-- =============================================================================
-- Ninguna vista ni consulta anterior fue modificada para incluir 2024: los
-- globs data/raw/<tipo>/*/*.parquet ya lo cubren. Estas consultas verifican
-- que los nuevos archivos se integraron correctamente.
--     python scripts/run_sql.py sql/05_validacion_2024.sql
-- =============================================================================

-- name: q5_01_archivos_por_anio
-- objetivo: Verificar que existan 12 archivos por tipo para 2024 y que los de 2026 se conserven (5.2, 5.5).
-- fuente: glob('data/raw/*/*/*.parquet')
-- decision: 2024 completo (12 + 12) y los 16 archivos de 2026 siguen presentes; no hubo re-descarga.
SELECT regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 1) AS taxi_type,
       regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 2) AS anio,
       count(*) AS archivos,
       min(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS primer_mes,
       max(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY ALL;

-- name: q5_02_registros_metadatos_vs_escaneo
-- objetivo: Comprobar que el numero de filas en los metadatos coincide con lo que leen las vistas, por anio (5.5).
-- fuente: parquet_file_metadata('data/raw/*/*/*.parquet') + vista trips
-- decision: Coinciden exactamente para cada tipo y anio: la vista trips incluye todos los registros de 2024 sin cambios.
WITH meta AS (
    SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1) AS taxi_type,
           CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
           sum(num_rows) AS filas_metadatos
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
    GROUP BY ALL
), vista AS (
    SELECT taxi_type, file_year AS anio, count(*) AS filas_vista_trips
    FROM trips GROUP BY ALL
)
SELECT m.taxi_type, m.anio, m.filas_metadatos, v.filas_vista_trips,
       m.filas_metadatos = v.filas_vista_trips AS coincide
FROM meta m JOIN vista v USING (taxi_type, anio)
ORDER BY m.taxi_type DESC, m.anio;

-- name: q5_03_diferencias_esquema_por_anio
-- objetivo: Identificar columnas que existen en un anio y no en otro (5.6, 5.7).
-- fuente: parquet_schema('data/raw/*/*/*.parquet')
-- decision: 2024 no tiene cbd_congestion_fee (la cuota de congestion de Manhattan empezo el 5-ene-2025) ni request_source. Gracias a union_by_name quedan como NULL y las consultas usan coalesce(cbd_congestion_fee, 0).
WITH s AS (
    SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1) AS taxi_type,
           regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS anio,
           name AS columna, count(*) AS archivos
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE name NOT IN ('schema', 'duckdb_schema')
    GROUP BY ALL
)
PIVOT s ON anio USING max(archivos) GROUP BY taxi_type, columna
ORDER BY taxi_type DESC, columna;

-- name: q5_04_cobertura_mensual
-- objetivo: Consultar conjuntamente 2024 y 2026 y verificar la cobertura mes a mes desde la vista unificada (5.6).
-- fuente: vista trips (lee data/raw/*/*/*.parquet)
-- decision: Ambos anios aparecen en la misma consulta sin cambios en el SQL; 2024 tiene 12 meses y 2026 tiene 8.
PIVOT (SELECT taxi_type, file_year, 'm' || lpad(file_month::VARCHAR, 2, '0') AS mes, count(*) AS viajes
       FROM trips GROUP BY ALL)
ON mes USING sum(viajes)
GROUP BY taxi_type, file_year
ORDER BY taxi_type DESC, file_year;

-- name: q5_05_nulos_columnas_nuevas
-- objetivo: Medir los nulos de las columnas que dependen del anio para decidir como tratarlas (5.7).
-- fuente: vista trips
-- decision: cbd_congestion_fee es 100% NULL en 2024 (no existia), no por mala calidad. Se usa coalesce(..., 0) y los indicadores de esta cuota solo se interpretan desde 2025.
SELECT taxi_type, file_year AS anio, count(*) AS viajes,
       round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee IS NULL) / count(*), 2) AS pct_cbd_nulo,
       round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2) AS pct_pasajeros_nulo,
       round(100.0 * count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) / count(*), 2) AS pct_pago_desconocido
FROM trips
GROUP BY ALL
ORDER BY taxi_type DESC, anio;

-- name: q5_06_calidad_por_anio
-- objetivo: Verificar que las reglas de limpieza (trips_clean) funcionan igual para 2024 (5.7).
-- fuente: vistas trips y trips_clean
-- decision: El porcentaje conservado es similar entre anios: las reglas no necesitan ajustarse por anio.
SELECT t.taxi_type, t.anio, t.registros, c.registros AS registros_limpios,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado
FROM (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips GROUP BY ALL) t
JOIN (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips_clean GROUP BY ALL) c USING (taxi_type, anio)
ORDER BY t.taxi_type DESC, t.anio;

-- name: q5_07_rango_fechas
-- objetivo: Confirmar que, tras la limpieza, cada anio solo contiene fechas de su propio periodo (5.5).
-- fuente: vista trips_clean
-- decision: Sin fechas fuera de rango; las fechas anomalas de 2024 (p. ej. 2002, 2009) se descartan con la misma regla.
SELECT taxi_type, file_year AS anio, min(pickup_datetime) AS primer_pickup, max(pickup_datetime) AS ultimo_pickup,
       count(DISTINCT CAST(pickup_datetime AS DATE)) AS dias_con_viajes
FROM trips_clean
GROUP BY ALL
ORDER BY taxi_type DESC, anio;

-- name: q5_08_comparacion_mismo_periodo
-- objetivo: Comparar 2024 vs 2026 en el mismo periodo (enero-agosto) para que la comparacion sea justa (5.6, 5.7).
-- fuente: vista trips_clean
-- decision: Las consultas anteriores funcionan sin cambios, pero al mezclar anios con distinta cobertura (12 vs 8 meses) los totales anuales no son comparables; se comparan meses equivalentes o metricas por dia.
SELECT taxi_type, file_year AS anio,
       count(*) AS viajes_ene_ago,
       round(count(*) / count(DISTINCT CAST(pickup_datetime AS DATE)), 0) AS viajes_por_dia,
       round(avg(trip_distance), 2) AS distancia_prom,
       round(avg(duration_min), 1) AS duracion_prom,
       round(avg(total_amount), 2) AS total_prom,
       round(avg(fare_amount), 2) AS tarifa_prom
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY ALL
ORDER BY taxi_type DESC, anio;
