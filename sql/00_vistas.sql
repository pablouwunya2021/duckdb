-- =============================================================================
-- 00_vistas.sql - Vistas logicas sobre los archivos Parquet (sin materializar)
-- =============================================================================
-- Estas vistas NO copian datos: cada consulta que las usa lee directamente los
-- archivos Parquet de data/raw. Se usan globs (*) en el anio y el mes, por lo
-- que cualquier archivo nuevo descargado (2024, 2025, meses nuevos de 2026)
-- queda incluido automaticamente sin modificar este archivo.
--
-- union_by_name = true: los archivos de distintos meses/anios no tienen
-- exactamente las mismas columnas (p. ej. cbd_congestion_fee aparece en 2025,
-- request_source a mitad de 2026); se alinean por nombre y las columnas
-- ausentes quedan en NULL.
--
-- filename = true: agrega la columna `filename` para saber de que archivo
-- (y por lo tanto de que anio/mes publicado) proviene cada registro.
-- =============================================================================

-- Taxis amarillos, columnas originales
CREATE OR REPLACE VIEW yellow_raw AS
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true);

-- Taxis verdes, columnas originales
CREATE OR REPLACE VIEW green_raw AS
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true);

-- Vista unificada y normalizada (amarillos + verdes).
-- Transformaciones registradas:
--   * tpep_/lpep_ pickup/dropoff -> pickup_datetime / dropoff_datetime
--   * taxi_type: 'yellow' | 'green'
--   * file_year / file_month: anio y mes del archivo de origen (desde el nombre)
--   * duration_min: duracion del viaje en minutos
--   * airport_fee: solo existe en amarillos (NULL en verdes)
--   * trip_type / ehail_fee: solo existen en verdes (NULL en amarillos)
CREATE OR REPLACE VIEW trips AS
WITH unidos AS (
    SELECT 'yellow' AS taxi_type,
           VendorID, tpep_pickup_datetime AS pickup_datetime, tpep_dropoff_datetime AS dropoff_datetime,
           passenger_count, trip_distance, RatecodeID, store_and_fwd_flag,
           PULocationID, DOLocationID, payment_type,
           fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge,
           total_amount, congestion_surcharge, Airport_fee AS airport_fee, cbd_congestion_fee,
           CAST(NULL AS BIGINT) AS trip_type, filename
    FROM yellow_raw
    UNION ALL BY NAME
    SELECT 'green' AS taxi_type,
           VendorID, lpep_pickup_datetime AS pickup_datetime, lpep_dropoff_datetime AS dropoff_datetime,
           passenger_count, trip_distance, RatecodeID, store_and_fwd_flag,
           PULocationID, DOLocationID, payment_type,
           fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge,
           total_amount, congestion_surcharge, CAST(NULL AS DOUBLE) AS airport_fee, cbd_congestion_fee,
           trip_type, filename
    FROM green_raw
)
SELECT taxi_type,
       CAST(regexp_extract(filename, '_(\d{4})-(\d{2})\.parquet$', 1) AS INTEGER) AS file_year,
       CAST(regexp_extract(filename, '_(\d{4})-(\d{2})\.parquet$', 2) AS INTEGER) AS file_month,
       VendorID AS vendor_id, pickup_datetime, dropoff_datetime,
       date_diff('second', pickup_datetime, dropoff_datetime) / 60.0 AS duration_min,
       passenger_count, trip_distance, RatecodeID AS ratecode_id, store_and_fwd_flag,
       PULocationID AS pu_location_id, DOLocationID AS do_location_id, payment_type,
       fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge,
       total_amount, congestion_surcharge, airport_fee, cbd_congestion_fee, trip_type
FROM unidos;

-- Vista "limpia": aplica las reglas de calidad definidas en el Ejercicio 3.6.
-- Un viaje se considera valido si:
--   1. la fecha de pickup cae en el mismo anio/mes del archivo publicado
--      (elimina fechas de 2008, 2009, 2002 o del mes siguiente);
--   2. la duracion esta entre 1 y 180 minutos;
--   3. la distancia esta entre 0.1 y 100 millas;
--   4. la tarifa base es positiva y el total esta entre 0 y 1000 USD;
--   5. si se informa passenger_count, esta entre 1 y 6.
CREATE OR REPLACE VIEW trips_clean AS
SELECT *
FROM trips
WHERE year(pickup_datetime) = file_year
  AND month(pickup_datetime) = file_month
  AND duration_min BETWEEN 1 AND 180
  AND trip_distance BETWEEN 0.1 AND 100
  AND fare_amount > 0
  AND total_amount > 0 AND total_amount < 1000
  AND (passenger_count IS NULL OR passenger_count BETWEEN 1 AND 6);
