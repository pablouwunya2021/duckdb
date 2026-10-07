# Resultados de `sql/08_validacion_2025.sql`

Generado con `python scripts/run_sql.py sql/08_validacion_2025.sql` el 2026-10-07 02:42. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

## q8_01_archivos_por_anio

**Objetivo:** Verificar que existen los archivos de 2024, 2025 y 2026 para ambos tipos de taxi (8.1, 8.2).

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

**Resultado** (6 filas, 0.18 s):

| taxi_type | anio | archivos | primer_mes | ultimo_mes |
|---|---|---|---|---|
| green | 2024 | 12 | 2024-01 | 2024-12 |
| green | 2025 | 12 | 2025-01 | 2025-12 |
| green | 2026 | 8 | 2026-01 | 2026-08 |
| yellow | 2024 | 12 | 2024-01 | 2024-12 |
| yellow | 2025 | 12 | 2025-01 | 2025-12 |
| yellow | 2026 | 8 | 2026-01 | 2026-08 |

**Decision / interpretacion:** 12 archivos por tipo para 2024 y 2025, 8 para 2026; la segunda ejecucion de la descarga solo bajo 2025.

## q8_02_registros_metadatos_vs_escaneo

**Objetivo:** Comprobar que las vistas leen todas las filas de cada anio (8.3).

**Fuente:** `parquet_file_metadata + vista trips`

```sql
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

**Decision / interpretacion:** Coincidencia exacta para los 6 grupos tipo-anio.

## q8_03_cobertura_mensual

**Objetivo:** Consultar conjuntamente los 3 anios y ver la cobertura mes a mes (8.3).

**Fuente:** `vista trips`

```sql
PIVOT (SELECT taxi_type, file_year, 'm' || lpad(file_month::VARCHAR, 2, '0') AS mes, count(*) AS viajes
       FROM trips GROUP BY ALL)
ON mes USING sum(viajes)
GROUP BY taxi_type, file_year
ORDER BY taxi_type DESC, file_year;
```

**Resultado** (6 filas, 0.13 s):

| taxi_type | file_year | m01 | m02 | m03 | m04 | m05 | m06 | m07 | m08 | m09 | m10 | m11 | m12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 2,964,624 | 3,007,526 | 3,582,628 | 3,514,289 | 3,723,833 | 3,539,193 | 3,076,903 | 2,979,183 | 3,633,030 | 3,833,771 | 3,646,369 | 3,668,371 |
| yellow | 2025 | 3,475,226 | 3,577,543 | 4,145,257 | 3,970,553 | 4,591,845 | 4,322,960 | 3,898,963 | 3,574,091 | 4,251,015 | 4,428,699 | 4,181,444 | 4,305,006 |
| yellow | 2026 | 3,724,889 | 3,399,866 | 3,952,451 | 3,831,240 | 4,090,836 | 3,837,248 | 3,530,109 | 3,336,716 | NULL | NULL | NULL | NULL |
| green | 2024 | 56,551 | 53,577 | 57,457 | 56,471 | 61,003 | 54,748 | 51,837 | 51,771 | 54,440 | 56,147 | 52,222 | 53,994 |
| green | 2025 | 48,326 | 46,621 | 51,539 | 52,132 | 55,399 | 49,390 | 48,205 | 46,306 | 48,893 | 49,416 | 46,912 | 48,236 |
| green | 2026 | 40,272 | 37,373 | 44,208 | 44,238 | 44,921 | 44,163 | 41,252 | 40,687 | NULL | NULL | NULL | NULL |

**Decision / interpretacion:** Sin huecos: 2024 y 2025 completos, 2026 hasta agosto.

## q8_04_columnas_por_anio

**Objetivo:** Ver como evoluciona el esquema en los 3 anios (8.3).

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

**Decision / interpretacion:** cbd_congestion_fee aparece en 2025 y request_source en jun-2026; el resto es estable. Las vistas no requieren cambios.

## q8_05_calidad_por_anio

**Objetivo:** Verificar que las reglas de limpieza se comportan igual en los 3 anios (8.3).

**Fuente:** `vistas trips y trips_clean`

```sql
SELECT t.taxi_type, t.anio, t.registros, c.registros AS registros_limpios,
       round(100.0 * c.registros / t.registros, 2) AS pct_conservado,
       t.sin_taximetro_pct
FROM (SELECT taxi_type, file_year AS anio, count(*) AS registros,
             round(100.0 * count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) / count(*), 2) AS sin_taximetro_pct
      FROM trips GROUP BY ALL) t
JOIN (SELECT taxi_type, file_year AS anio, count(*) AS registros FROM trips_clean GROUP BY ALL) c USING (taxi_type, anio)
ORDER BY t.taxi_type DESC, t.anio;
```

**Resultado** (6 filas, 2.03 s):

| taxi_type | anio | registros | registros_limpios | pct_conservado | sin_taximetro_pct |
|---|---|---|---|---|---|
| yellow | 2024 | 41,169,720 | 39,114,044 | 95.01 | 9.94 |
| yellow | 2025 | 48,722,602 | 43,570,037 | 89.42 | 23.83 |
| yellow | 2026 | 29,703,355 | 27,884,915 | 93.88 | 25.98 |
| green | 2024 | 660,218 | 606,588 | 91.88 | 3.68 |
| green | 2025 | 591,375 | 542,323 | 91.71 | 8.43 |
| green | 2026 | 337,114 | 309,437 | 91.79 | 14.47 |

**Decision / interpretacion:** Se conserva 92-95% de los registros cada anio.

## q8_06_evolucion_anual_mismo_periodo

**Objetivo:** Comparar los principales indicadores de los 3 anios en el mismo periodo (enero-agosto) (8.5).

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (6 filas, 5.36 s):

| taxi_type | anio | viajes_por_dia | total_prom | tarifa_prom | cbd_prom | distancia_mediana | duracion_mediana | velocidad_mediana | pct_tarjeta | pct_efectivo |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2024 | 102,980 | 28.33 | 19.53 | 0 | 1.8 | 12.8 | 9.53 | 76.04 | 13.68 |
| yellow | 2025 | 116,482 | 28.32 | 19.55 | 0.55 | 1.9 | 13.1 | 9.69 | 68.99 | 9.94 |
| yellow | 2026 | 114,753 | 30.18 | 21.22 | 0.54 | 1.95 | 14.2 | 9.31 | 65.72 | 9 |
| green | 2024 | 1,671 | 23.74 | 17.72 | 0 | 1.98 | 12 | 10.4 | 68.01 | 27.61 |
| green | 2025 | 1,493 | 24.83 | 17.96 | 0.07 | 2.04 | 12.5 | 10.31 | 70.08 | 23.14 |
| green | 2026 | 1,273 | 25.32 | 16.9 | 0.06 | 2.15 | 13.3 | 10.06 | 66.55 | 19.52 |

**Decision / interpretacion:** Base para identificar los cambios entre 2024, 2025 y 2026.

## q8_07_velocidad_zona_cbd

**Objetivo:** Medir si la velocidad dentro de Manhattan al sur de la calle 60 (zona CBD) cambio tras la cuota de congestion (ene-2025) (8.6).

**Fuente:** `vistas trips_clean + zones`

```sql
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
```

**Resultado** (3 filas, 4.86 s):

| anio | viajes | velocidad_mediana_mph | duracion_mediana_min | distancia_mediana_mi |
|---|---|---|---|---|
| 2024 | 12,872,997 | 8.35 | 13.2 | 1.63 |
| 2025 | 13,584,933 | 8.34 | 13.2 | 1.64 |
| 2026 | 13,050,702 | 7.94 | 14.2 | 1.66 |

**Decision / interpretacion:** Se usan viajes yellow con origen y destino en Manhattan entre semana de 7 a 19 h; los viajes con cuota CBD > 0 en 2025-2026 identifican la zona. Para 2024 se aproxima con las mismas zonas.

## q8_08_cambio_mensual_interanual

**Objetivo:** Variacion interanual (%) de los viajes por dia de cada mes, para separar tendencia de estacionalidad (8.5, 8.6).

**Fuente:** `vista trips`

```sql
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
```

**Resultado** (24 filas, 0.13 s):

| taxi_type | mes | v2024 | v2025 | v2026 | var_25_vs_24 | var_26_vs_25 |
|---|---|---|---|---|---|---|
| yellow | 1 | 95,633 | 112,104 | 120,158 | 17.2 | 7.2 |
| yellow | 2 | 103,708 | 127,769 | 121,424 | 23.2 | -5 |
| yellow | 3 | 115,569 | 133,718 | 127,498 | 15.7 | -4.7 |
| yellow | 4 | 117,143 | 132,352 | 127,708 | 13 | -3.5 |
| yellow | 5 | 120,124 | 148,124 | 131,962 | 23.3 | -10.9 |
| yellow | 6 | 117,973 | 144,099 | 127,908 | 22.1 | -11.2 |
| yellow | 7 | 99,255 | 125,773 | 113,874 | 26.7 | -9.5 |
| yellow | 8 | 96,103 | 115,293 | 107,636 | 20 | -6.6 |
| yellow | 9 | 121,101 | 141,701 | NULL | 17 | NULL |
| yellow | 10 | 123,670 | 142,861 | NULL | 15.5 | NULL |
| yellow | 11 | 121,546 | 139,381 | NULL | 14.7 | NULL |
| yellow | 12 | 118,335 | 138,871 | NULL | 17.4 | NULL |
| green | 1 | 1,824 | 1,559 | 1,299 | -14.5 | -16.7 |
| green | 2 | 1,847 | 1,665 | 1,335 | -9.9 | -19.8 |
| green | 3 | 1,853 | 1,663 | 1,426 | -10.3 | -14.2 |
| green | 4 | 1,882 | 1,738 | 1,475 | -7.7 | -15.1 |
| green | 5 | 1,968 | 1,787 | 1,449 | -9.2 | -18.9 |
| green | 6 | 1,825 | 1,646 | 1,472 | -9.8 | -10.6 |
| green | 7 | 1,672 | 1,555 | 1,331 | -7 | -14.4 |
| green | 8 | 1,670 | 1,494 | 1,312 | -10.6 | -12.1 |
| green | 9 | 1,815 | 1,630 | NULL | -10.2 | NULL |
| green | 10 | 1,811 | 1,594 | NULL | -12 | NULL |
| green | 11 | 1,741 | 1,564 | NULL | -10.2 | NULL |
| green | 12 | 1,742 | 1,556 | NULL | -10.7 | NULL |

**Decision / interpretacion:** Comparar el mismo mes entre anios elimina la estacionalidad; muestra si el crecimiento es sostenido.
