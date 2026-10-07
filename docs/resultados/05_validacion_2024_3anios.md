# Resultados de `sql/05_validacion_2024.sql`

Generado con `python scripts/run_sql.py sql/05_validacion_2024.sql` el 2026-10-07 02:42. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

## q5_01_archivos_por_anio

**Objetivo:** Verificar que existan 12 archivos por tipo para 2024 y que los de 2026 se conserven (5.2, 5.5).

**Fuente:** `glob('data/raw/*/*/*.parquet')`

```sql
SELECT regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 1) AS taxi_type,
       regexp_extract(file, '(yellow|green)_tripdata_(\d{4})', 2) AS anio,
       count(*) AS archivos,
       min(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS primer_mes,
       max(regexp_extract(file, '(\d{4}-\d{2})\.parquet$', 1)) AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY ALL;
```

**Resultado** (6 filas, 0.34 s):

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2024 | 12 | 2024-01 | 2024-12 |
| green | 2025 | 12 | 2025-01 | 2025-12 |
| green | 2026 | 8 | 2026-01 | 2026-08 |
| yellow | 2024 | 12 | 2024-01 | 2024-12 |
| yellow | 2025 | 12 | 2025-01 | 2025-12 |
| yellow | 2026 | 8 | 2026-01 | 2026-08 |

**Decision / interpretacion:** 2024 completo (12 + 12) y los 16 archivos de 2026 siguen presentes; no hubo re-descarga.

## q5_02_registros_metadatos_vs_escaneo

**Objetivo:** Comprobar que el numero de filas en los metadatos coincide con lo que leen las vistas, por anio (5.5).

**Fuente:** `parquet_file_metadata('data/raw/*/*/*.parquet') + vista trips`

```sql
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
```

**Resultado** (6 filas, 0.06 s):

| taxi_type | anio | filas_metadatos | filas_vista_trips | coincide |
|---|---|---|---|---|
| yellow | 2024 | 41,169,720 | 41,169,720 | si |
| yellow | 2025 | 48,722,602 | 48,722,602 | si |
| yellow | 2026 | 29,703,355 | 29,703,355 | si |
| green | 2024 | 660,218 | 660,218 | si |
| green | 2025 | 591,375 | 591,375 | si |
| green | 2026 | 337,114 | 337,114 | si |

**Decision / interpretacion:** Coinciden exactamente para cada tipo y anio: la vista trips incluye todos los registros de 2024 sin cambios.

## q5_03_diferencias_esquema_por_anio

**Objetivo:** Identificar columnas que existen en un anio y no en otro (5.6, 5.7).

**Fuente:** `parquet_schema('data/raw/*/*/*.parquet')`

```sql
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
```

**Resultado** (43 filas, 0.02 s):

| taxi_type | columna | 2024 | 2025 | 2026 |
|---|---|---|---|---|
| yellow | Airport_fee | 12 | 12 | 8 |
| yellow | DOLocationID | 12 | 12 | 8 |
| yellow | PULocationID | 12 | 12 | 8 |
| yellow | RatecodeID | 12 | 12 | 8 |
| yellow | VendorID | 12 | 12 | 8 |
| yellow | cbd_congestion_fee | <NA> | 12 | 8 |
| yellow | congestion_surcharge | 12 | 12 | 8 |
| yellow | extra | 12 | 12 | 8 |
| yellow | fare_amount | 12 | 12 | 8 |
| yellow | improvement_surcharge | 12 | 12 | 8 |
| yellow | mta_tax | 12 | 12 | 8 |
| yellow | passenger_count | 12 | 12 | 8 |
| yellow | payment_type | 12 | 12 | 8 |
| yellow | request_source | <NA> | <NA> | 3 |
| yellow | store_and_fwd_flag | 12 | 12 | 8 |
| yellow | tip_amount | 12 | 12 | 8 |
| yellow | tolls_amount | 12 | 12 | 8 |
| yellow | total_amount | 12 | 12 | 8 |
| yellow | tpep_dropoff_datetime | 12 | 12 | 8 |
| yellow | tpep_pickup_datetime | 12 | 12 | 8 |
| yellow | trip_distance | 12 | 12 | 8 |
| green | DOLocationID | 12 | 12 | 8 |
| green | PULocationID | 12 | 12 | 8 |
| green | RatecodeID | 12 | 12 | 8 |
| green | VendorID | 12 | 12 | 8 |
| green | cbd_congestion_fee | <NA> | 12 | 8 |
| green | congestion_surcharge | 12 | 12 | 8 |
| green | ehail_fee | 12 | 12 | 8 |
| green | extra | 12 | 12 | 8 |
| green | fare_amount | 12 | 12 | 8 |
| green | improvement_surcharge | 12 | 12 | 8 |
| green | lpep_dropoff_datetime | 12 | 12 | 8 |
| green | lpep_pickup_datetime | 12 | 12 | 8 |
| green | mta_tax | 12 | 12 | 8 |
| green | passenger_count | 12 | 12 | 8 |
| green | payment_type | 12 | 12 | 8 |
| green | request_source | <NA> | <NA> | 3 |
| green | store_and_fwd_flag | 12 | 12 | 8 |
| green | tip_amount | 12 | 12 | 8 |
| green | tolls_amount | 12 | 12 | 8 |
| green | total_amount | 12 | 12 | 8 |
| green | trip_distance | 12 | 12 | 8 |
| green | trip_type | 12 | 12 | 8 |

**Decision / interpretacion:** 2024 no tiene cbd_congestion_fee (la cuota de congestion de Manhattan empezo el 5-ene-2025) ni request_source. Gracias a union_by_name quedan como NULL y las consultas usan coalesce(cbd_congestion_fee, 0).

## q5_04_cobertura_mensual

**Objetivo:** Consultar conjuntamente 2024 y 2026 y verificar la cobertura mes a mes desde la vista unificada (5.6).

**Fuente:** `vista trips (lee data/raw/*/*/*.parquet)`

```sql
PIVOT (SELECT taxi_type, file_year, 'm' || lpad(file_month::VARCHAR, 2, '0') AS mes, count(*) AS viajes
       FROM trips GROUP BY ALL)
ON mes USING sum(viajes)
GROUP BY taxi_type, file_year
ORDER BY taxi_type DESC, file_year;
```

**Resultado** (6 filas, 0.14 s):

| taxi_type | file_year | m01 | m02 | m03 | m04 | m05 | m06 | m07 | m08 | m09 | m10 | m11 | m12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 2,964,624 | 3,007,526 | 3,582,628 | 3,514,289 | 3,723,833 | 3,539,193 | 3,076,903 | 2,979,183 | 3,633,030 | 3,833,771 | 3,646,369 | 3,668,371 |
| yellow | 2025 | 3,475,226 | 3,577,543 | 4,145,257 | 3,970,553 | 4,591,845 | 4,322,960 | 3,898,963 | 3,574,091 | 4,251,015 | 4,428,699 | 4,181,444 | 4,305,006 |
| yellow | 2026 | 3,724,889 | 3,399,866 | 3,952,451 | 3,831,240 | 4,090,836 | 3,837,248 | 3,530,109 | 3,336,716 | NULL | NULL | NULL | NULL |
| green | 2024 | 56,551 | 53,577 | 57,457 | 56,471 | 61,003 | 54,748 | 51,837 | 51,771 | 54,440 | 56,147 | 52,222 | 53,994 |
| green | 2025 | 48,326 | 46,621 | 51,539 | 52,132 | 55,399 | 49,390 | 48,205 | 46,306 | 48,893 | 49,416 | 46,912 | 48,236 |
| green | 2026 | 40,272 | 37,373 | 44,208 | 44,238 | 44,921 | 44,163 | 41,252 | 40,687 | NULL | NULL | NULL | NULL |

**Decision / interpretacion:** Ambos anios aparecen en la misma consulta sin cambios en el SQL; 2024 tiene 12 meses y 2026 tiene 8.

## q5_05_nulos_columnas_nuevas

**Objetivo:** Medir los nulos de las columnas que dependen del anio para decidir como tratarlas (5.7).

**Fuente:** `vista trips`

```sql
SELECT taxi_type, file_year AS anio, count(*) AS viajes,
       round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee IS NULL) / count(*), 2) AS pct_cbd_nulo,
       round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2) AS pct_pasajeros_nulo,
       round(100.0 * count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) / count(*), 2) AS pct_pago_desconocido
FROM trips
GROUP BY ALL
ORDER BY taxi_type DESC, anio;
```

**Resultado** (6 filas, 0.27 s):

| taxi_type | anio | viajes | pct_cbd_nulo | pct_pasajeros_nulo | pct_pago_desconocido |
|---|---|---|---|---|---|
| yellow | 2024 | 41,169,720 | 100 | 9.94 | 9.94 |
| yellow | 2025 | 48,722,602 | 0 | 23.83 | 23.83 |
| yellow | 2026 | 29,703,355 | 0 | 25.98 | 25.98 |
| green | 2024 | 660,218 | 100 | 3.68 | 3.68 |
| green | 2025 | 591,375 | 0.65 | 8.43 | 8.43 |
| green | 2026 | 337,114 | 0 | 14.47 | 14.47 |

**Decision / interpretacion:** cbd_congestion_fee es 100% NULL en 2024 (no existia), no por mala calidad. Se usa coalesce(..., 0) y los indicadores de esta cuota solo se interpretan desde 2025.

## q5_06_calidad_por_anio

**Objetivo:** Verificar que las reglas de limpieza (trips_clean) funcionan igual para 2024 (5.7).

**Fuente:** `vistas trips y trips_clean`

```sql
SELECT t.taxi_type, t.anio, t.registros, c.registros AS registros_limpios,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado
FROM (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips GROUP BY ALL) t
JOIN (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips_clean GROUP BY ALL) c USING (taxi_type, anio)
ORDER BY t.taxi_type DESC, t.anio;
```

**Resultado** (6 filas, 2.11 s):

| taxi_type | anio | registros | registros_limpios | pct_conservado |
|---|---|---|---|---|
| yellow | 2024 | 41,169,720 | 39,114,044 | 95.01 |
| yellow | 2025 | 48,722,602 | 43,570,037 | 89.42 |
| yellow | 2026 | 29,703,355 | 27,884,915 | 93.88 |
| green | 2024 | 660,218 | 606,588 | 91.88 |
| green | 2025 | 591,375 | 542,323 | 91.71 |
| green | 2026 | 337,114 | 309,437 | 91.79 |

**Decision / interpretacion:** El porcentaje conservado es similar entre anios: las reglas no necesitan ajustarse por anio.

## q5_07_rango_fechas

**Objetivo:** Confirmar que, tras la limpieza, cada anio solo contiene fechas de su propio periodo (5.5).

**Fuente:** `vista trips_clean`

```sql
SELECT taxi_type, file_year AS anio, min(pickup_datetime) AS primer_pickup, max(pickup_datetime) AS ultimo_pickup,
       count(DISTINCT CAST(pickup_datetime AS DATE)) AS dias_con_viajes
FROM trips_clean
GROUP BY ALL
ORDER BY taxi_type DESC, anio;
```

**Resultado** (6 filas, 2.01 s):

| taxi_type | anio | primer_pickup | ultimo_pickup | dias_con_viajes |
|---|---|---|---|---|
| yellow | 2024 | 2024-01-01 00:00:00 | 2024-12-31 23:59:58 | 366 |
| yellow | 2025 | 2025-01-01 00:00:00 | 2025-12-31 23:59:57 | 365 |
| yellow | 2026 | 2026-01-01 00:00:00 | 2026-08-31 23:59:59 | 243 |
| green | 2024 | 2024-01-01 00:03:57 | 2024-12-31 23:56:49 | 366 |
| green | 2025 | 2025-01-01 00:01:11 | 2025-12-31 23:59:09 | 365 |
| green | 2026 | 2026-01-01 00:03:27 | 2026-08-31 23:58:28 | 243 |

**Decision / interpretacion:** Sin fechas fuera de rango; las fechas anomalas de 2024 (p. ej. 2002, 2009) se descartan con la misma regla.

## q5_08_comparacion_mismo_periodo

**Objetivo:** Comparar 2024 vs 2026 en el mismo periodo (enero-agosto) para que la comparacion sea justa (5.6, 5.7).

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (6 filas, 2.06 s):

| taxi_type | anio | viajes_ene_ago | viajes_por_dia | distancia_prom | duracion_prom | total_prom | tarifa_prom |
|---|---|---|---|---|---|---|---|
| yellow | 2024 | 25,127,229 | 102,980 | 3.44 | 16.5 | 28.33 | 19.53 |
| yellow | 2025 | 28,305,202 | 116,482 | 3.48 | 16.5 | 28.32 | 19.55 |
| yellow | 2026 | 27,884,915 | 114,753 | 3.55 | 17.7 | 30.18 | 21.22 |
| green | 2024 | 407,649 | 1,671 | 2.95 | 14.6 | 23.74 | 17.72 |
| green | 2025 | 362,901 | 1,493 | 3.13 | 15.5 | 24.83 | 17.96 |
| green | 2026 | 309,437 | 1,273 | 3.34 | 17.1 | 25.32 | 16.9 |

**Decision / interpretacion:** Las consultas anteriores funcionan sin cambios, pero al mezclar anios con distinta cobertura (12 vs 8 meses) los totales anuales no son comparables; se comparan meses equivalentes o metricas por dia.
