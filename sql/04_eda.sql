-- =============================================================================
-- 04_eda.sql - Ejercicio 4: analisis exploratorio con DuckDB
-- =============================================================================
-- Fuente: vistas de sql/00_vistas.sql (leen data/raw/*/*/*.parquet en cada
-- ejecucion). Las distribuciones usan trips_clean (reglas del Ejercicio 3.6);
-- los volumenes usan trips para no ocultar registros.
-- Las consultas no tienen anios fijos: funcionan igual con 1, 2 o 3 anios.
--     python scripts/run_sql.py sql/04_eda.sql
-- =============================================================================

-- name: q4_01_viajes_por_mes
-- pregunta: P1 (temporal) - Como evoluciona el volumen mensual de viajes de cada tipo de taxi?
-- objetivo: Contar viajes, ingresos y viajes promedio por dia para cada mes y tipo.
-- fuente: vista trips
SELECT taxi_type, file_year AS anio, file_month AS mes,
       count(*)                                   AS viajes,
       round(count(*) / max(day(last_day(make_date(file_year, file_month, 1)))), 0) AS viajes_por_dia,
       round(sum(total_amount) / 1e6, 2)          AS ingresos_musd
FROM trips
GROUP BY ALL
ORDER BY taxi_type, anio, mes;

-- name: q4_02_viajes_hora_dia
-- pregunta: P2 (temporal) - En que horas y dias de la semana se concentra la demanda?
-- objetivo: Matriz dia de la semana x hora con el promedio de viajes por hora (normalizado por numero de dias).
-- fuente: vista trips_clean
WITH base AS (
    SELECT taxi_type, isodow(pickup_datetime) AS dow, hour(pickup_datetime) AS hora,
           CAST(pickup_datetime AS DATE) AS fecha
    FROM trips_clean
)
SELECT taxi_type, dow, hora, round(count(*) / count(DISTINCT fecha), 1) AS viajes_promedio
FROM base
GROUP BY ALL
ORDER BY taxi_type, dow, hora;

-- name: q4_03_perfil_horario
-- pregunta: P2 (temporal) - Cual es la hora pico y la hora valle de cada tipo de taxi, entre semana y fin de semana?
-- objetivo: Resumir la matriz horaria en hora pico/valle y su participacion.
-- fuente: vista trips_clean
WITH h AS (
    SELECT taxi_type, CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END AS tipo_dia,
           hour(pickup_datetime) AS hora, count(*) AS viajes
    FROM trips_clean GROUP BY ALL
)
SELECT taxi_type, tipo_dia,
       arg_max(hora, viajes) AS hora_pico, round(100.0 * max(viajes) / sum(viajes), 2) AS pct_hora_pico,
       arg_min(hora, viajes) AS hora_valle, round(100.0 * min(viajes) / sum(viajes), 2) AS pct_hora_valle
FROM h
GROUP BY ALL
ORDER BY ALL;

-- name: q4_04_caracteristicas_viaje
-- pregunta: P3 (caracteristicas) - Como son los viajes tipicos (distancia, duracion, pasajeros, velocidad)?
-- objetivo: Percentiles de distancia, duracion, velocidad y tarifa por tipo de taxi.
-- fuente: vista trips_clean
SELECT taxi_type,
       count(*) AS viajes,
       round(quantile_cont(trip_distance, 0.5), 2) AS distancia_p50_mi,
       round(avg(trip_distance), 2)                AS distancia_prom_mi,
       round(quantile_cont(trip_distance, 0.95), 2) AS distancia_p95_mi,
       round(quantile_cont(duration_min, 0.5), 1) AS duracion_p50_min,
       round(avg(duration_min), 1)                AS duracion_prom_min,
       round(quantile_cont(duration_min, 0.95), 1) AS duracion_p95_min,
       round(avg(trip_distance / (duration_min / 60)), 1) AS velocidad_prom_mph,
       round(avg(passenger_count), 2)             AS pasajeros_prom,
       round(quantile_cont(fare_amount, 0.5), 2)  AS tarifa_p50,
       round(avg(total_amount), 2)                AS total_prom
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type DESC;

-- name: q4_05_velocidad_por_hora
-- pregunta: P4 (caracteristicas/temporal) - Como cambia la velocidad del trafico a lo largo del dia?
-- objetivo: Velocidad mediana (mph) y duracion mediana por hora del dia, entre semana.
-- fuente: vista trips_clean
SELECT hour(pickup_datetime) AS hora,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(median(duration_min), 1) AS duracion_mediana_min,
       round(median(trip_distance), 2) AS distancia_mediana_mi
FROM trips_clean
WHERE isodow(pickup_datetime) <= 5
GROUP BY hora
ORDER BY hora;

-- name: q4_06_pasajeros
-- pregunta: P3 (caracteristicas) - Cuantos pasajeros viajan normalmente?
-- objetivo: Distribucion de passenger_count por tipo de taxi (incluye desconocidos).
-- fuente: vista trips
SELECT taxi_type, coalesce(passenger_count::VARCHAR, 'desconocido') AS pasajeros, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips
GROUP BY 1, 2
ORDER BY taxi_type DESC, viajes DESC;

-- name: q4_07_borough_origen
-- pregunta: P5 (yellow vs green) - En que boroughs se originan los viajes de cada tipo de taxi?
-- objetivo: Participacion de cada borough de origen por tipo, uniendo con la tabla de zonas.
-- fuente: vistas trips_clean + zones (data/raw/reference/taxi_zone_lookup.csv)
SELECT t.taxi_type, z.borough, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct
FROM trips_clean t
JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY 1, 2
ORDER BY t.taxi_type DESC, viajes DESC;

-- name: q4_08_top_zonas
-- pregunta: P5 (yellow vs green) - Cuales son las zonas de origen mas frecuentes de cada tipo?
-- objetivo: Top 8 zonas de pickup por tipo de taxi.
-- fuente: vistas trips_clean + zones
SELECT * FROM (
    SELECT t.taxi_type, z.borough, z.zone, count(*) AS viajes,
           round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct,
           row_number() OVER (PARTITION BY t.taxi_type ORDER BY count(*) DESC) AS ranking
    FROM trips_clean t JOIN zones z ON z.location_id = t.pu_location_id
    GROUP BY 1, 2, 3
)
WHERE ranking <= 8
ORDER BY taxi_type DESC, ranking;

-- name: q4_09_yellow_vs_green
-- pregunta: P6 (yellow vs green) - En que se diferencian economicamente los viajes amarillos y verdes?
-- objetivo: Comparar tarifa, costo por milla, propina, peajes y recargos por tipo.
-- fuente: vista trips_clean
SELECT taxi_type,
       round(avg(fare_amount), 2)                         AS tarifa_prom,
       round(median(fare_amount / trip_distance), 2)      AS tarifa_por_milla_mediana,
       round(avg(tip_amount), 2)                          AS propina_prom,
       round(avg(tolls_amount), 2)                        AS peajes_prom,
       round(avg(coalesce(congestion_surcharge, 0)), 2)   AS congestion_prom,
       round(avg(coalesce(cbd_congestion_fee, 0)), 2)     AS cbd_fee_prom,
       round(avg(coalesce(airport_fee, 0)), 2)            AS airport_fee_prom,
       round(avg(total_amount), 2)                        AS total_prom,
       round(100.0 * avg(CASE WHEN ratecode_id = 5 THEN 1 ELSE 0 END), 2) AS pct_tarifa_negociada,
       round(100.0 * avg(CASE WHEN trip_type = 2 THEN 1 ELSE 0 END), 2)   AS pct_despacho
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type DESC;

-- name: q4_10_tipo_pago
-- pregunta: P7 (pago) - Como se distribuyen los metodos de pago y como cambian mes a mes?
-- objetivo: Participacion mensual de cada metodo de pago por tipo de taxi.
-- fuente: vista trips
SELECT taxi_type, file_year AS anio, file_month AS mes,
       CASE payment_type WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo' WHEN 3 THEN 'sin cargo'
                         WHEN 4 THEN 'disputa' ELSE 'desconocido/flex' END AS metodo_pago,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, file_year, file_month), 2) AS pct
FROM trips
GROUP BY 1, 2, 3, 4
ORDER BY taxi_type DESC, anio, mes, viajes DESC;

-- name: q4_11_propina_por_pago
-- pregunta: P8 (pago) - Que porcentaje de propina se deja segun el metodo de pago?
-- objetivo: Porcentaje de propina sobre la tarifa y proporcion de viajes con propina, por metodo de pago.
-- fuente: vista trips_clean
SELECT taxi_type,
       CASE payment_type WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo' WHEN 3 THEN 'sin cargo'
                         WHEN 4 THEN 'disputa' ELSE 'desconocido/flex' END AS metodo_pago,
       count(*) AS viajes,
       round(100.0 * avg(CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END), 2) AS pct_con_propina,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 2)              AS propina_pct_tarifa,
       round(avg(tip_amount), 2)                                         AS propina_prom
FROM trips_clean
GROUP BY 1, 2
ORDER BY taxi_type DESC, viajes DESC;

-- name: q4_12_composicion_total
-- pregunta: P9 (pago) - Que componentes forman el monto total pagado?
-- objetivo: Participacion de tarifa, propina, peajes, recargos y cuotas en el total cobrado.
-- fuente: vista trips_clean
SELECT taxi_type,
       round(100 * sum(fare_amount) / sum(total_amount), 2)                    AS pct_tarifa,
       round(100 * sum(tip_amount) / sum(total_amount), 2)                     AS pct_propina,
       round(100 * sum(tolls_amount) / sum(total_amount), 2)                   AS pct_peajes,
       round(100 * sum(coalesce(congestion_surcharge, 0)) / sum(total_amount), 2) AS pct_congestion,
       round(100 * sum(coalesce(cbd_congestion_fee, 0)) / sum(total_amount), 2)   AS pct_cbd_fee,
       round(100 * sum(coalesce(airport_fee, 0)) / sum(total_amount), 2)         AS pct_aeropuerto,
       round(100 * sum(extra + mta_tax + improvement_surcharge) / sum(total_amount), 2) AS pct_otros
FROM trips_clean
GROUP BY taxi_type
ORDER BY taxi_type DESC;

-- name: q4_13_distribucion_distancia
-- pregunta: P10 (distribuciones) - Como se distribuye la distancia de los viajes?
-- objetivo: Histograma de distancia por rangos (millas), por tipo de taxi.
-- fuente: vista trips_clean
SELECT taxi_type,
       CASE WHEN trip_distance < 1 THEN '0-1' WHEN trip_distance < 2 THEN '1-2'
            WHEN trip_distance < 3 THEN '2-3' WHEN trip_distance < 5 THEN '3-5'
            WHEN trip_distance < 10 THEN '5-10' WHEN trip_distance < 20 THEN '10-20'
            ELSE '20+' END AS rango_millas,
       min(trip_distance) AS orden,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips_clean
GROUP BY 1, 2
ORDER BY taxi_type DESC, orden;

-- name: q4_14_distribucion_tarifa
-- pregunta: P10 (distribuciones) - Como se distribuye el monto total pagado?
-- objetivo: Histograma del total por intervalos de 10 USD (hasta 150) usando trips_clean.
-- fuente: vista trips_clean
SELECT taxi_type, least(floor(total_amount / 10) * 10, 150)::INTEGER AS desde_usd,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips_clean
GROUP BY 1, 2
ORDER BY taxi_type DESC, desde_usd;

-- name: q4_15_atipicos_iqr
-- pregunta: P11 (atipicos) - Cuantos viajes limpios siguen siendo atipicos segun el criterio IQR?
-- objetivo: Calcular limites de Tukey (Q1 - 1.5 IQR, Q3 + 1.5 IQR) para distancia, duracion, total y costo por milla.
-- fuente: vista trips_clean
WITH q AS (
    SELECT taxi_type,
           quantile_cont(trip_distance, [0.25, 0.75]) AS qd,
           quantile_cont(duration_min, [0.25, 0.75]) AS qm,
           quantile_cont(total_amount, [0.25, 0.75]) AS qt,
           quantile_cont(fare_amount / trip_distance, [0.25, 0.75]) AS qf
    FROM trips_clean GROUP BY taxi_type
)
SELECT t.taxi_type,
       round(q.qd[2] + 1.5 * (q.qd[2] - q.qd[1]), 2) AS lim_sup_distancia,
       round(100.0 * avg(CASE WHEN trip_distance > q.qd[2] + 1.5 * (q.qd[2] - q.qd[1]) THEN 1 ELSE 0 END), 2) AS pct_atip_distancia,
       round(q.qm[2] + 1.5 * (q.qm[2] - q.qm[1]), 1) AS lim_sup_duracion,
       round(100.0 * avg(CASE WHEN duration_min > q.qm[2] + 1.5 * (q.qm[2] - q.qm[1]) THEN 1 ELSE 0 END), 2) AS pct_atip_duracion,
       round(q.qt[2] + 1.5 * (q.qt[2] - q.qt[1]), 2) AS lim_sup_total,
       round(100.0 * avg(CASE WHEN total_amount > q.qt[2] + 1.5 * (q.qt[2] - q.qt[1]) THEN 1 ELSE 0 END), 2) AS pct_atip_total,
       round(q.qf[2] + 1.5 * (q.qf[2] - q.qf[1]), 2) AS lim_sup_usd_milla,
       round(100.0 * avg(CASE WHEN fare_amount / trip_distance > q.qf[2] + 1.5 * (q.qf[2] - q.qf[1]) THEN 1 ELSE 0 END), 2) AS pct_atip_usd_milla
FROM trips_clean t JOIN q USING (taxi_type)
GROUP BY t.taxi_type, q.qd, q.qm, q.qt, q.qf
ORDER BY t.taxi_type DESC;

-- name: q4_16_inconsistencias_monto
-- pregunta: P11 (inconsistencias) - El total cobrado coincide con la suma de sus componentes?
-- objetivo: Detectar viajes donde total_amount difiere de la suma de componentes en mas de 0.05 USD.
-- fuente: vista trips
SELECT taxi_type,
       count(*) AS viajes,
       count(*) FILTER (WHERE abs(total_amount - (fare_amount + extra + mta_tax + tip_amount + tolls_amount
             + improvement_surcharge + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0)
             + coalesce(cbd_congestion_fee, 0))) > 0.05) AS total_no_cuadra,
       round(100.0 * count(*) FILTER (WHERE abs(total_amount - (fare_amount + extra + mta_tax + tip_amount + tolls_amount
             + improvement_surcharge + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0)
             + coalesce(cbd_congestion_fee, 0))) > 0.05) / count(*), 3) AS pct_no_cuadra,
       count(*) FILTER (WHERE payment_type = 2 AND tip_amount > 0) AS efectivo_con_propina_registrada,
       count(*) FILTER (WHERE trip_distance > 0 AND duration_min > 0
                          AND trip_distance / (duration_min / 60) > 80) AS velocidad_mayor_80mph
FROM trips
GROUP BY taxi_type
ORDER BY taxi_type DESC;

-- name: q4_17_aeropuertos
-- pregunta: P12 (caracteristicas) - Que peso tienen los viajes a/desde aeropuertos y cuanto cuestan?
-- objetivo: Viajes, distancia y monto promedio de los viajes que tocan JFK, LaGuardia o Newark versus el resto.
-- fuente: vistas trips_clean + zones
SELECT t.taxi_type,
       CASE WHEN zp.zone ILIKE '%airport%' OR zd.zone ILIKE '%airport%' THEN 'aeropuerto' ELSE 'otros' END AS categoria,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct_viajes,
       round(avg(trip_distance), 2) AS distancia_prom,
       round(avg(total_amount), 2) AS total_prom,
       round(100.0 * sum(total_amount) / sum(sum(total_amount)) OVER (PARTITION BY t.taxi_type), 2) AS pct_ingresos
FROM trips_clean t
JOIN zones zp ON zp.location_id = t.pu_location_id
JOIN zones zd ON zd.location_id = t.do_location_id
GROUP BY 1, 2
ORDER BY t.taxi_type DESC, categoria;

-- name: q4_18_fin_de_semana_vs_semana
-- pregunta: P2 (temporal) - Cambian las caracteristicas del viaje entre semana y fin de semana?
-- objetivo: Comparar volumen diario, distancia, duracion y propina por tipo de dia.
-- fuente: vista trips_clean
SELECT taxi_type,
       CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END AS tipo_dia,
       round(count(*) / count(DISTINCT CAST(pickup_datetime AS DATE)), 0) AS viajes_por_dia,
       round(avg(trip_distance), 2) AS distancia_prom,
       round(avg(duration_min), 1) AS duracion_prom,
       round(avg(trip_distance / (duration_min / 60)), 1) AS velocidad_prom,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 2) AS propina_pct_tarifa
FROM trips_clean
GROUP BY 1, 2
ORDER BY taxi_type DESC, tipo_dia;

-- name: q4_19_inconsistencia_por_proveedor
-- pregunta: P11 (inconsistencias) - La diferencia entre el total y sus componentes depende del proveedor del taximetro?
-- objetivo: Diferencia mediana (total - suma de componentes) por proveedor y metodo de pago, solo en viajes que no cuadran.
-- fuente: vista trips
WITH d AS (
    SELECT taxi_type, vendor_id, payment_type,
           total_amount - (fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge
               + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0) + coalesce(cbd_congestion_fee, 0)) AS diferencia
    FROM trips
)
SELECT taxi_type,
       CASE vendor_id WHEN 1 THEN '1 Creative Mobile' WHEN 2 THEN '2 Curb Mobility' WHEN 6 THEN '6 Myle'
                      WHEN 7 THEN '7 Helix' ELSE vendor_id::VARCHAR END AS proveedor,
       CASE coalesce(payment_type, 0) WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo' WHEN 0 THEN 'flex/desconocido'
                         ELSE 'otro' END AS pago,
       count(*) AS viajes,
       round(100.0 * count(*) FILTER (WHERE abs(diferencia) > 0.05) / count(*), 1) AS pct_no_cuadra,
       round(median(diferencia) FILTER (WHERE abs(diferencia) > 0.05), 2) AS diferencia_mediana_usd
FROM d
GROUP BY 1, 2, 3
HAVING count(*) > 1000
ORDER BY taxi_type DESC, viajes DESC;
