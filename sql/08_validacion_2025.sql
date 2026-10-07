-- =============================================================================
-- 08_validacion_2025.sql - Ejercicio 8: incorporacion de 2025 y analisis de 3 anios
-- =============================================================================
--     python scripts/run_sql.py sql/08_validacion_2025.sql
-- =============================================================================

-- name: q8_01_archivos_por_anio
-- objetivo: Verificar que existen los archivos de 2024, 2025 y 2026 para ambos tipos de taxi (8.1, 8.2).
-- fuente: glob('data/raw/*/*/*.parquet')
-- decision: 12 archivos por tipo para 2024 y 2025, 8 para 2026; la segunda ejecucion de la descarga solo bajo 2025.
SELECT regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 1) AS taxi_type,
       regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 2) AS anio,
       count(*) AS archivos,
       min(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS primer_mes,
       max(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY ALL;

-- name: q8_02_registros_metadatos_vs_escaneo
-- objetivo: Comprobar que las vistas leen todas las filas de cada anio (8.3).
-- fuente: parquet_file_metadata + vista trips
-- decision: Coincidencia exacta para los 6 grupos tipo-anio.
WITH meta AS (
    SELECT regexp_extract(file_name, '(yellow|green)_tripdata', 1) AS taxi_type,
           CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
           sum(num_rows) AS filas_metadatos
    FROM parquet_file_metadata('data/raw/*/*/*.parquet') GROUP BY ALL
), vista AS (
    SELECT taxi_type, file_year AS anio, count(*) AS filas_vista_trips FROM trips GROUP BY ALL
)
SELECT m.taxi_type, m.anio, m.filas_metadatos, v.filas_vista_trips,
       m.filas_metadatos = v.filas_vista_trips AS coincide
FROM meta m JOIN vista v USING (taxi_type, anio)
ORDER BY m.taxi_type DESC, m.anio;

-- name: q8_03_cobertura_mensual
-- objetivo: Consultar conjuntamente los 3 anios y ver la cobertura mes a mes (8.3).
-- fuente: vista trips
-- decision: Sin huecos: 2024 y 2025 completos, 2026 hasta agosto.
PIVOT (SELECT taxi_type, file_year, 'm' || lpad(file_month::VARCHAR, 2, '0') AS mes, count(*) AS viajes
       FROM trips GROUP BY ALL)
ON mes USING sum(viajes)
GROUP BY taxi_type, file_year
ORDER BY taxi_type DESC, file_year;

-- name: q8_04_columnas_por_anio
-- objetivo: Ver como evoluciona el esquema en los 3 anios (8.3).
-- fuente: parquet_schema('data/raw/*/*/*.parquet')
-- decision: cbd_congestion_fee aparece en 2025 y request_source en jun-2026; el resto es estable. Las vistas no requieren cambios.
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

-- name: q8_05_calidad_por_anio
-- objetivo: Verificar que las reglas de limpieza se comportan igual en los 3 anios (8.3).
-- fuente: vistas trips y trips_clean
-- decision: Se conserva 92-95% de los registros cada anio.
SELECT t.taxi_type, t.anio, t.registros, c.registros AS registros_limpios,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado,
       t.sin_taximetro_pct
FROM (SELECT taxi_type, file_year AS anio, count(*) AS registros,
             round(100.0 * count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) / count(*), 2) AS sin_taximetro_pct
      FROM trips GROUP BY ALL) t
JOIN (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips_clean GROUP BY ALL) c USING (taxi_type, anio)
ORDER BY t.taxi_type DESC, t.anio;

-- name: q8_06_evolucion_anual_mismo_periodo
-- objetivo: Comparar los principales indicadores de los 3 anios en el mismo periodo (enero-agosto) (8.5).
-- fuente: vista trips_clean
-- decision: Base para identificar los cambios entre 2024, 2025 y 2026.
SELECT taxi_type, file_year AS anio,
       round(count(*) / count(DISTINCT CAST(pickup_datetime AS DATE)), 0) AS viajes_por_dia,
       round(avg(total_amount), 2) AS total_prom,
       round(avg(fare_amount), 2) AS tarifa_prom,
       round(avg(coalesce(cbd_congestion_fee, 0)), 2) AS cbd_prom,
       round(median(trip_distance), 2) AS distancia_mediana,
       round(median(duration_min), 1) AS duracion_mediana,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana,
       round(100.0 * avg(CASE WHEN payment_type = 1 THEN 1 ELSE 0 END), 2) AS pct_tarjeta,
       round(100.0 * avg(CASE WHEN payment_type = 2 THEN 1 ELSE 0 END), 2) AS pct_efectivo
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY ALL
ORDER BY taxi_type DESC, anio;

-- name: q8_07_velocidad_zona_cbd
-- objetivo: Medir si la velocidad dentro de Manhattan al sur de la calle 60 (zona CBD) cambio tras la cuota de congestion (ene-2025) (8.6).
-- fuente: vistas trips_clean + zones
-- decision: Se usan viajes yellow con origen y destino en Manhattan entre semana de 7 a 19 h; los viajes con cuota CBD > 0 en 2025-2026 identifican la zona. Para 2024 se aproxima con las mismas zonas.
WITH zonas_cbd AS (
    SELECT DISTINCT pu_location_id AS location_id
    FROM trips_clean
    WHERE file_year = 2025 AND taxi_type = 'yellow' AND cbd_congestion_fee > 0 AND pu_location_id = do_location_id
)
SELECT file_year AS anio,
       count(*) AS viajes,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(median(duration_min), 1) AS duracion_mediana_min,
       round(median(trip_distance), 2) AS distancia_mediana_mi
FROM trips_clean
WHERE taxi_type = 'yellow' AND file_month BETWEEN 1 AND 8
  AND isodow(pickup_datetime) <= 5 AND hour(pickup_datetime) BETWEEN 7 AND 19
  AND pu_location_id IN (SELECT location_id FROM zonas_cbd)
  AND do_location_id IN (SELECT location_id FROM zonas_cbd)
GROUP BY ALL
ORDER BY anio;

-- name: q8_08_cambio_mensual_interanual
-- objetivo: Variacion interanual (%) de los viajes por dia de cada mes, para separar tendencia de estacionalidad (8.5, 8.6).
-- fuente: vista trips
-- decision: Comparar el mismo mes entre anios elimina la estacionalidad; muestra si el crecimiento es sostenido.
WITH m AS (
    SELECT taxi_type, file_year AS anio, file_month AS mes,
           count(*) / max(day(last_day(make_date(file_year, file_month, 1)))) AS viajes_por_dia
    FROM trips GROUP BY ALL
)
SELECT taxi_type, mes,
       round(max(viajes_por_dia) FILTER (WHERE anio = 2024), 0) AS v2024,
       round(max(viajes_por_dia) FILTER (WHERE anio = 2025), 0) AS v2025,
       round(max(viajes_por_dia) FILTER (WHERE anio = 2026), 0) AS v2026,
       round(100.0 * (max(viajes_por_dia) FILTER (WHERE anio = 2025) / max(viajes_por_dia) FILTER (WHERE anio = 2024) - 1), 1) AS var_25_vs_24,
       round(100.0 * (max(viajes_por_dia) FILTER (WHERE anio = 2026) / max(viajes_por_dia) FILTER (WHERE anio = 2025) - 1), 1) AS var_26_vs_25
FROM m
GROUP BY ALL
ORDER BY taxi_type DESC, mes;
