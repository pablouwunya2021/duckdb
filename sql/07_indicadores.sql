-- =============================================================================
-- 07_indicadores.sql - Ejercicio 7: indicadores del tablero
-- =============================================================================
-- Cada consulta con nombre `ind_*` es un indicador. scripts/build_db.py las
-- materializa como tablas pequenias dentro de data/processed/taxi.duckdb y
-- Metabase (scripts/setup_metabase.py) las grafica. Tambien pueden ejecutarse
-- directamente sobre Parquet con:
--     python scripts/run_sql.py sql/07_indicadores.sql
--
-- Todas se agrupan por periodo (anio-mes) y tipo de taxi, sin anios fijos, por
-- lo que se actualizan solas al incorporar nuevos anios (Ejercicio 8).
-- Metadatos: pregunta (7.1), justificacion (7.6), visualizacion (7.4).
-- =============================================================================

-- name: ind_demanda_mensual
-- pregunta: Q1 - Como evoluciona la demanda (viajes por dia) de cada tipo de taxi mes a mes? Q2 - Cuanto ingreso genera cada servicio?
-- objetivo: Indicador I1 Viajes promedio por dia (normalizado por dias del mes) e ingresos mensuales.
-- justificacion: Es el indicador base de volumen; se normaliza por dia para comparar meses de distinta duracion y anios con distinta cobertura.
-- visualizacion: lineas (periodo vs viajes_por_dia, una serie por tipo de taxi).
-- fuente: trips
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       count(*) AS viajes,
       round(count(*) / max(day(last_day(make_date(file_year, file_month, 1)))), 1) AS viajes_por_dia,
       round(sum(total_amount), 2) AS ingresos_usd
FROM trips
GROUP BY ALL
ORDER BY periodo, taxi_type;

-- name: ind_ingreso_por_viaje
-- pregunta: Q3 - Cuanto paga en promedio un pasajero por viaje y por milla, y como cambia en el tiempo?
-- objetivo: Indicador I2 Ingreso promedio por viaje (total_amount) y tarifa mediana por milla, por mes.
-- justificacion: Mide el precio efectivo del servicio; separa el efecto de tarifas/recargos del efecto de distancia (USD por milla).
-- visualizacion: lineas (periodo vs total_promedio_usd por tipo).
-- fuente: trips_clean
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       round(avg(total_amount), 2)                    AS total_promedio_usd,
       round(avg(fare_amount), 2)                     AS tarifa_promedio_usd,
       round(median(fare_amount / trip_distance), 2)  AS tarifa_mediana_por_milla,
       round(median(trip_distance), 2)                AS distancia_mediana_mi,
       round(median(duration_min), 1)                 AS duracion_mediana_min
FROM trips_clean
GROUP BY ALL
ORDER BY periodo, taxi_type;

-- name: ind_demanda_horaria
-- pregunta: Q4 - En que horas del dia se concentra la demanda entre semana y en fin de semana?
-- objetivo: Indicador I3 Distribucion horaria de viajes (% del dia) por tipo de dia y tipo de taxi.
-- justificacion: Permite dimensionar la oferta de taxis por franja horaria y distinguir uso laboral (pico 17-18 h) de ocio (noche de fin de semana).
-- visualizacion: lineas (hora vs pct_viajes, series por tipo de dia y taxi).
-- fuente: trips_clean
SELECT taxi_type, CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END AS tipo_dia,
       hour(pickup_datetime) AS hora,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type,
             CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END), 2) AS pct_viajes
FROM trips_clean
GROUP BY 1, 2, 3
ORDER BY taxi_type, tipo_dia, hora;

-- name: ind_velocidad_horaria
-- pregunta: Q5 - Que tan congestionado esta el trafico a cada hora y como cambio entre anios?
-- objetivo: Indicador I4 Velocidad mediana (mph) por hora del dia entre semana, por anio.
-- justificacion: La velocidad es un proxy directo de congestion; compararla entre anios muestra el efecto de politicas como la cuota de congestion (2025).
-- visualizacion: lineas (hora vs velocidad_mediana_mph, una serie por anio).
-- fuente: trips_clean
SELECT file_year AS anio, hour(pickup_datetime) AS hora,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(median(duration_min), 1) AS duracion_mediana_min,
       count(*) AS viajes
FROM trips_clean
WHERE isodow(pickup_datetime) <= 5 AND taxi_type = 'yellow'
GROUP BY ALL
ORDER BY anio, hora;

-- name: ind_mix_pago
-- pregunta: Q6 - Como pagan los pasajeros y esta desapareciendo el efectivo?
-- objetivo: Indicador I5 Participacion mensual de cada metodo de pago.
-- justificacion: El metodo de pago condiciona que propinas se registran y refleja la digitalizacion del servicio; el aumento de 'desconocido/flex' es un problema de calidad que debe monitorearse.
-- visualizacion: barras apiladas 100% (periodo vs pct por metodo), solo taxis amarillos.
-- fuente: trips
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       CASE coalesce(payment_type, 0) WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo'
            WHEN 0 THEN 'desconocido/flex' ELSE 'otros (sin cargo/disputa)' END AS metodo_pago,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, file_year, file_month), 2) AS pct
FROM trips
GROUP BY 1, 2, 3, 4, 5
ORDER BY periodo, taxi_type, metodo_pago;

-- name: ind_propina_tarjeta
-- pregunta: Q7 - Cuanta propina dejan los pasajeros que pagan con tarjeta y como evoluciona?
-- objetivo: Indicador I6 Propina como % de la tarifa y % de viajes con propina (solo tarjeta, donde se registra).
-- justificacion: La propina en efectivo no se registra (EDA, P8); restringir a tarjeta evita subestimar. Es un indicador del ingreso del conductor y de satisfaccion.
-- visualizacion: lineas (periodo vs propina_pct_tarifa por tipo).
-- fuente: trips_clean
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       count(*) AS viajes_tarjeta,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 2) AS propina_pct_tarifa,
       round(100.0 * avg(CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END), 2) AS pct_con_propina,
       round(avg(tip_amount), 2) AS propina_promedio_usd
FROM trips_clean
WHERE payment_type = 1
GROUP BY ALL
ORDER BY periodo, taxi_type;

-- name: ind_aeropuertos
-- pregunta: Q8 - Que peso tienen los viajes de aeropuerto en la demanda y en los ingresos?
-- objetivo: Indicador I7 % de viajes y % de ingresos de viajes que tocan JFK, LaGuardia o Newark, por anio.
-- justificacion: En el EDA 8% de los viajes genera 21% de los ingresos; es un segmento estrategico y sensible a tarifas fijas.
-- visualizacion: barras agrupadas (anio vs pct_viajes y pct_ingresos), taxis amarillos.
-- fuente: trips_clean + zones
WITH a AS (
    SELECT t.file_year, t.taxi_type,
           CASE WHEN zp.zone ILIKE '%airport%' OR zd.zone ILIKE '%airport%' THEN 'aeropuerto' ELSE 'resto' END AS segmento,
           count(*) AS viajes, sum(t.total_amount) AS ingresos, avg(t.total_amount) AS total_promedio
    FROM trips_clean t
    JOIN zones zp ON zp.location_id = t.pu_location_id
    JOIN zones zd ON zd.location_id = t.do_location_id
    GROUP BY ALL
)
SELECT file_year AS anio, taxi_type, segmento, viajes,
       round(100.0 * viajes / sum(viajes) OVER (PARTITION BY file_year, taxi_type), 2) AS pct_viajes,
       round(100.0 * ingresos / sum(ingresos) OVER (PARTITION BY file_year, taxi_type), 2) AS pct_ingresos,
       round(total_promedio, 2) AS total_promedio_usd
FROM a
ORDER BY anio, taxi_type, segmento;

-- name: ind_borough_origen
-- pregunta: Q9 - Donde se originan los viajes de cada tipo de taxi y esta cambiando esa distribucion?
-- objetivo: Indicador I8 Participacion de cada borough de origen por anio y tipo de taxi.
-- justificacion: Verifica si cada servicio cumple su rol (green = fuera del centro de Manhattan) y detecta desplazamientos geograficos.
-- visualizacion: barras horizontales apiladas (tipo-anio vs pct por borough).
-- fuente: trips_clean + zones
SELECT t.file_year AS anio, t.taxi_type, t.taxi_type || ' ' || t.file_year AS serie,
       CASE WHEN z.borough IN ('Manhattan', 'Queens', 'Brooklyn', 'Bronx') THEN z.borough ELSE 'Otros/Desconocido' END AS borough,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.file_year, t.taxi_type), 2) AS pct
FROM trips_clean t JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY 1, 2, 3, 4
ORDER BY anio, taxi_type, viajes DESC;

-- name: ind_cuota_congestion
-- pregunta: Q10 - Cuantos viajes pagan la nueva cuota de congestion de Manhattan (CBD) y cuanto recauda?
-- objetivo: Indicador I9 % de viajes con cbd_congestion_fee > 0 y monto mensual recaudado (desde enero 2025).
-- justificacion: La cuota CBD (5-ene-2025) es el cambio regulatorio mas importante del periodo; afecta precio, demanda y trafico.
-- visualizacion: barras (periodo vs recaudacion) + linea (% de viajes con cuota).
-- fuente: trips
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       round(100.0 * avg(CASE WHEN coalesce(cbd_congestion_fee, 0) > 0 THEN 1 ELSE 0 END), 2) AS pct_viajes_con_cuota,
       round(sum(coalesce(cbd_congestion_fee, 0)), 2) AS recaudacion_usd,
       round(avg(coalesce(congestion_surcharge, 0)), 3) AS recargo_congestion_prom
FROM trips
GROUP BY ALL
ORDER BY periodo, taxi_type;

-- name: ind_calidad_datos
-- pregunta: Q11 - Que tan confiables son los datos de cada mes?
-- objetivo: Indicador I10 % de registros validos (trips_clean) y % de viajes sin datos de taximetro (payment_type 0/NULL).
-- justificacion: Todos los demas indicadores dependen de la calidad; un aumento de registros invalidos o desconocidos debe leerse junto con ellos.
-- visualizacion: lineas (periodo vs pct_validos y pct_sin_datos_taximetro).
-- fuente: trips + trips_clean
WITH t AS (
    SELECT file_year, file_month, taxi_type, count(*) AS registros,
           count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) AS sin_taximetro
    FROM trips GROUP BY ALL
), c AS (
    SELECT file_year, file_month, taxi_type, count(*) AS validos FROM trips_clean GROUP BY ALL
)
SELECT make_date(t.file_year, t.file_month, 1) AS periodo, t.file_year AS anio, t.file_month AS mes, t.taxi_type,
       t.registros, c.validos,
       round(100.0 * c.validos / t.registros, 2) AS pct_validos,
       round(100.0 * t.sin_taximetro / t.registros, 2) AS pct_sin_datos_taximetro
FROM t JOIN c USING (file_year, file_month, taxi_type)
ORDER BY periodo, t.taxi_type;

-- name: ind_plataformas
-- pregunta: Q12 - Que proporcion de viajes de taxi se solicita a traves de plataformas (Uber/Lyft) desde que existe el dato?
-- objetivo: Indicador I11 Participacion de request_source por mes (solo meses en que la columna existe, jun-2026 en adelante).
-- justificacion: Es una tendencia nueva de 2026 (taxis amarillos despachados por apps de alto volumen) que cambia la naturaleza del servicio.
-- visualizacion: barras apiladas (periodo vs pct por origen), taxis amarillos.
-- fuente: trips
WITH meses AS (
    SELECT DISTINCT file_year, file_month, taxi_type FROM trips WHERE request_source IS NOT NULL
)
SELECT make_date(t.file_year, t.file_month, 1) AS periodo, t.file_year AS anio, t.file_month AS mes, t.taxi_type,
       CASE WHEN t.request_source = 'HV0003' THEN 'Uber (HV0003)' WHEN t.request_source = 'HV0005' THEN 'Lyft (HV0005)'
            WHEN t.request_source IS NULL THEN 'calle/sin dato' ELSE 'otras apps/despacho' END AS origen,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type, t.file_year, t.file_month), 2) AS pct
FROM trips t
JOIN meses m USING (file_year, file_month, taxi_type)
GROUP BY 1, 2, 3, 4, 5
ORDER BY periodo, t.taxi_type, origen;

-- name: ind_resumen_anual
-- pregunta: Q13 - Como se comparan los anios en sus metricas principales (mismos meses)?
-- objetivo: Tabla resumen por anio y tipo de taxi, restringida a enero-agosto para comparar periodos equivalentes.
-- justificacion: Resume en una sola tabla los KPI del tablero y evita comparar anios con distinta cobertura.
-- visualizacion: tabla.
-- fuente: trips_clean
SELECT file_year AS anio, taxi_type,
       count(*) AS viajes_ene_ago,
       round(count(*) / count(DISTINCT CAST(pickup_datetime AS DATE)), 0) AS viajes_por_dia,
       round(avg(total_amount), 2) AS total_promedio_usd,
       round(median(trip_distance), 2) AS distancia_mediana_mi,
       round(median(duration_min), 1) AS duracion_mediana_min,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(100.0 * avg(CASE WHEN payment_type = 1 THEN 1 ELSE 0 END), 2) AS pct_tarjeta,
       round(100.0 * sum(tip_amount) FILTER (WHERE payment_type = 1) / sum(fare_amount) FILTER (WHERE payment_type = 1), 2) AS propina_pct_tarjeta
FROM trips_clean
WHERE file_month BETWEEN 1 AND 8
GROUP BY ALL
ORDER BY anio, taxi_type DESC;
