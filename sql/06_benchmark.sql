-- =============================================================================
-- 06_benchmark.sql - Ejercicio 6: consultas representativas para el benchmark
-- =============================================================================
-- El MISMO texto SQL se ejecuta en dos estrategias (scripts/benchmark.py):
--   * parquet : trips / trips_clean / zones son vistas que leen los archivos
--               Parquet en cada ejecucion (sql/00_vistas.sql);
--   * tabla   : trips y zones son tablas materializadas en una base DuckDB y
--               trips_clean es una vista con las mismas reglas sobre la tabla.
-- Como el texto es identico y ambas fuentes contienen exactamente las mismas
-- filas, la comparacion es valida (el script verifica que los resultados
-- coincidan).
-- =============================================================================

-- name: b1_conteo_total
-- objetivo: Conteo simple de todos los viajes (caso mas favorable a Parquet: se resuelve con metadatos).
-- origen: Ejercicio 3 (q3_03)
SELECT count(*) AS viajes FROM trips;

-- name: b2_viajes_ingresos_por_mes
-- objetivo: Agregacion temporal de volumen e ingresos (escanea pocas columnas).
-- origen: Ejercicio 4 (q4_01)
SELECT taxi_type, file_year, file_month, count(*) AS viajes, sum(total_amount) AS ingresos
FROM trips
GROUP BY ALL
ORDER BY ALL;

-- name: b3_heatmap_hora_dia
-- objetivo: Agregacion por dos dimensiones derivadas de la fecha, con filtros de calidad (trips_clean).
-- origen: Ejercicio 4 (q4_02)
SELECT taxi_type, isodow(pickup_datetime) AS dow, hour(pickup_datetime) AS hora, count(*) AS viajes
FROM trips_clean
GROUP BY ALL
ORDER BY ALL;

-- name: b4_percentiles_viaje
-- objetivo: Calculo de percentiles (operacion costosa que requiere ordenar/muestrear muchas filas).
-- origen: Ejercicio 4 (q4_04)
SELECT taxi_type,
       quantile_cont(trip_distance, 0.5) AS distancia_p50,
       quantile_cont(duration_min, 0.5)  AS duracion_p50,
       quantile_cont(total_amount, 0.95) AS total_p95,
       avg(trip_distance / (duration_min / 60)) AS velocidad_prom
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type;

-- name: b5_join_zonas
-- objetivo: JOIN con la tabla de zonas y agregacion por borough.
-- origen: Ejercicio 4 (q4_07)
SELECT t.taxi_type, z.borough, count(*) AS viajes, avg(t.total_amount) AS total_prom
FROM trips_clean t
JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY ALL
ORDER BY ALL;

-- name: b6_filtro_selectivo
-- objetivo: Consulta selectiva: viajes desde JFK (zona 132) un domingo en la noche; pocas filas de resultado.
-- origen: Ejercicio 4 (q4_17)
SELECT file_year, file_month, count(*) AS viajes, avg(total_amount) AS total_prom
FROM trips
WHERE pu_location_id = 132 AND isodow(pickup_datetime) = 7 AND hour(pickup_datetime) BETWEEN 20 AND 23
GROUP BY ALL
ORDER BY ALL;

-- name: b7_propina_por_pago
-- objetivo: Agregacion con CASE y filtros condicionales sobre columnas de pago.
-- origen: Ejercicio 4 (q4_11)
SELECT taxi_type, payment_type,
       count(*) AS viajes,
       avg(CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END) AS pct_con_propina,
       sum(tip_amount) / sum(fare_amount) AS propina_sobre_tarifa
FROM trips_clean
GROUP BY ALL
ORDER BY ALL;

-- name: b8_muchas_columnas
-- objetivo: Agregacion que lee muchas columnas a la vez (peor caso del formato columnar).
-- origen: Ejercicio 4 (q4_16)
SELECT taxi_type, vendor_id,
       sum(fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge
           + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0) + coalesce(cbd_congestion_fee, 0)) AS componentes,
       sum(total_amount) AS total, avg(passenger_count) AS pasajeros, avg(trip_distance) AS distancia
FROM trips
GROUP BY ALL
ORDER BY ALL;
