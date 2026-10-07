# Resultados de `sql/07_indicadores.sql`

Generado con `python scripts/run_sql.py sql/07_indicadores.sql` el 2026-10-07 02:11. Origen de datos: base `data/processed/taxi.duckdb`.

## ind_demanda_mensual

**Pregunta:** Q1 - Como evoluciona la demanda (viajes por dia) de cada tipo de taxi mes a mes? Q2 - Cuanto ingreso genera cada servicio?

**Objetivo:** Indicador I1 Viajes promedio por dia (normalizado por dias del mes) e ingresos mensuales.

**Fuente:** `trips`

```sql
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       count(*) AS viajes,
       round(count(*) / max(day(last_day(make_date(file_year, file_month, 1)))), 1) AS viajes_por_dia,
       round(sum(total_amount), 2) AS ingresos_usd
FROM trips
GROUP BY ALL
ORDER BY periodo, taxi_type;
```

**Resultado** (40 filas, 0.59 s):

| periodo | anio | mes | taxi_type | viajes | viajes_por_dia | ingresos_usd |
|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | 56,551 | 1,824.2 | 1,266,922.59 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | 2,964,624 | 95,633 | 79,456,384.28 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | 53,577 | 1,847.5 | 1,212,653.08 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | 3,007,526 | 103,707.8 | 80,073,615.28 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | 57,457 | 1,853.5 | 1,316,042.93 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | 3,582,628 | 115,568.6 | 97,162,913.97 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | 56,471 | 1,882.4 | 1,319,373.05 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | 3,514,289 | 117,143 | 96,619,892.35 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | 61,003 | 1,967.8 | 1,499,019.37 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | 3,723,833 | 120,123.6 | 105,662,803.2 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | 54,748 | 1,824.9 | 1,361,122.19 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | 3,539,193 | 117,973.1 | 98,854,638.37 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | 51,837 | 1,672.2 | 1,284,042.47 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | 3,076,903 | 99,254.9 | 86,418,496.54 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | 51,771 | 1,670 | 1,344,011.27 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | 2,979,183 | 96,102.7 | 84,225,045 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | 54,440 | 1,814.7 | 1,452,430.58 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | 3,633,030 | 121,101 | 103,683,398.86 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | 56,147 | 1,811.2 | 1,405,461.14 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | 3,833,771 | 123,670 | 108,992,686.43 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | 52,222 | 1,740.7 | 1,263,335.5 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | 3,646,369 | 121,545.6 | 100,829,464.98 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | 53,994 | 1,741.7 | 1,295,611.51 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | 3,668,371 | 118,334.5 | 103,889,786.46 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | 40,272 | 1,299.1 | 974,399.62 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | 3,724,889 | 120,157.7 | 108,686,768.73 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | 37,373 | 1,334.8 | 906,258.02 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | 3,399,866 | 121,423.8 | 102,381,021.74 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | 44,208 | 1,426.1 | 1,101,097.2 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | 3,952,451 | 127,498.4 | 118,958,457.18 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | 44,238 | 1,474.6 | 1,123,908.24 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | 3,831,240 | 127,708 | 114,938,587.08 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | 44,921 | 1,449.1 | 1,164,525.45 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | 4,090,836 | 131,962.5 | 124,709,721.43 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | 44,163 | 1,472.1 | 1,160,071.03 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | 3,837,248 | 127,908.3 | 117,093,902.13 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | 41,252 | 1,330.7 | 1,081,886.33 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | 3,530,109 | 113,874.5 | 106,056,209.55 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | 40,687 | 1,312.5 | 1,081,753.68 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | 3,336,716 | 107,636 | 100,346,477.46 |

## ind_ingreso_por_viaje

**Pregunta:** Q3 - Cuanto paga en promedio un pasajero por viaje y por milla, y como cambia en el tiempo?

**Objetivo:** Indicador I2 Ingreso promedio por viaje (total_amount) y tarifa mediana por milla, por mes.

**Fuente:** `trips_clean`

```sql
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       round(avg(total_amount), 2)                    AS total_promedio_usd,
       round(avg(fare_amount), 2)                     AS tarifa_promedio_usd,
       round(median(fare_amount / trip_distance), 2)  AS tarifa_mediana_por_milla,
       round(median(trip_distance), 2)                AS distancia_mediana_mi,
       round(median(duration_min), 1)                 AS duracion_mediana_min
FROM trips_clean
GROUP BY ALL
ORDER BY periodo, taxi_type;
```

**Resultado** (40 filas, 3.02 s):

| periodo | anio | mes | taxi_type | total_promedio_usd | tarifa_promedio_usd | tarifa_mediana_por_milla | distancia_mediana_mi | duracion_mediana_min |
|---|---|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | 22.19 | 16.54 | 6.77 | 1.9 | 11.5 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | 27.33 | 18.47 | 7.18 | 1.71 | 11.8 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | 22.5 | 16.76 | 6.77 | 1.9 | 11.6 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | 27.24 | 18.41 | 7.23 | 1.73 | 12.1 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | 22.76 | 16.99 | 6.84 | 1.9 | 11.7 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | 27.86 | 19.15 | 7.19 | 1.8 | 12.6 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | 23.31 | 17.28 | 6.8 | 1.95 | 11.8 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | 28.19 | 19.45 | 7.23 | 1.82 | 13 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | 24.47 | 18.25 | 6.91 | 2.01 | 12.5 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | 29.01 | 20.14 | 7.44 | 1.82 | 13.5 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | 24.74 | 18.56 | 6.78 | 2.05 | 12.4 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | 28.69 | 19.94 | 7.31 | 1.83 | 13.1 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | 24.35 | 18.15 | 6.64 | 2.07 | 11.9 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | 28.98 | 20.14 | 7.15 | 1.84 | 13 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | 25.78 | 19.37 | 6.6 | 2.11 | 12.1 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | 29.21 | 20.35 | 7.12 | 1.86 | 12.9 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | 26.44 | 19.98 | 6.82 | 2.1 | 12.9 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | 29.49 | 20.64 | 7.43 | 1.86 | 14 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | 24.93 | 18.64 | 6.84 | 2.03 | 12.5 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | 29.37 | 20.33 | 7.52 | 1.81 | 14 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | 23.94 | 17.83 | 6.89 | 1.96 | 12.2 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | 28.47 | 19.71 | 7.56 | 1.78 | 13.5 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | 23.78 | 17.69 | 6.88 | 1.93 | 12 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | 29.37 | 20.37 | 7.76 | 1.72 | 14 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | 24.15 | 16.01 | 6.84 | 2.02 | 13.1 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | 29.61 | 21.01 | 7.5 | 1.92 | 13.6 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | 24.26 | 16.25 | 6.94 | 2.04 | 13.6 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | 30.4 | 21.73 | 7.89 | 1.9 | 14.2 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | 24.77 | 16.06 | 6.62 | 2.14 | 13.2 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | 30.21 | 21.29 | 7.53 | 1.91 | 13.5 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | 25.14 | 16.5 | 6.62 | 2.15 | 13.1 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | 30.04 | 21.02 | 7.58 | 1.92 | 14.2 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | 25.71 | 17.57 | 6.77 | 2.16 | 13.5 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | 30.49 | 21.4 | 7.62 | 1.96 | 14.7 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | 25.97 | 17.18 | 6.71 | 2.18 | 13.6 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | 30.53 | 21.31 | 7.66 | 1.92 | 14.3 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | 26.12 | 17.43 | 6.55 | 2.23 | 13.2 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | 30.06 | 20.97 | 7.27 | 2.01 | 14.3 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | 26.33 | 18.14 | 6.51 | 2.27 | 13.3 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | 30.07 | 21.02 | 7.08 | 2.1 | 14.4 |

## ind_demanda_horaria

**Pregunta:** Q4 - En que horas del dia se concentra la demanda entre semana y en fin de semana?

**Objetivo:** Indicador I3 Distribucion horaria de viajes (% del dia) por tipo de dia y tipo de taxi.

**Fuente:** `trips_clean`

```sql
SELECT taxi_type, CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END AS tipo_dia,
       hour(pickup_datetime) AS hora,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type,
             CASE WHEN isodow(pickup_datetime) >= 6 THEN 'fin de semana' ELSE 'entre semana' END), 2) AS pct_viajes
FROM trips_clean
GROUP BY 1, 2, 3
ORDER BY taxi_type, tipo_dia, hora;
```

**Resultado** (96 filas, 1.28 s):

| taxi_type | tipo_dia | hora | viajes | pct_viajes |
|---|---|---|---|---|
| green | entre semana | 0 | 8,647 | 1.24 |
| green | entre semana | 1 | 4,965 | 0.71 |
| green | entre semana | 2 | 2,797 | 0.4 |
| green | entre semana | 3 | 1,792 | 0.26 |
| green | entre semana | 4 | 2,055 | 0.29 |
| green | entre semana | 5 | 3,855 | 0.55 |
| green | entre semana | 6 | 13,344 | 1.91 |
| green | entre semana | 7 | 31,386 | 4.5 |
| green | entre semana | 8 | 39,840 | 5.71 |
| green | entre semana | 9 | 41,070 | 5.89 |
| green | entre semana | 10 | 38,381 | 5.5 |
| green | entre semana | 11 | 36,437 | 5.22 |
| green | entre semana | 12 | 37,549 | 5.38 |
| green | entre semana | 13 | 37,669 | 5.4 |
| green | entre semana | 14 | 44,027 | 6.31 |
| green | entre semana | 15 | 48,469 | 6.95 |
| green | entre semana | 16 | 53,310 | 7.64 |
| green | entre semana | 17 | 58,646 | 8.41 |
| green | entre semana | 18 | 54,991 | 7.88 |
| green | entre semana | 19 | 41,611 | 5.97 |
| green | entre semana | 20 | 31,048 | 4.45 |
| green | entre semana | 21 | 26,930 | 3.86 |
| green | entre semana | 22 | 22,414 | 3.21 |
| green | entre semana | 23 | 16,271 | 2.33 |
| green | fin de semana | 0 | 6,695 | 3.06 |
| green | fin de semana | 1 | 5,230 | 2.39 |
| green | fin de semana | 2 | 4,414 | 2.02 |
| green | fin de semana | 3 | 3,689 | 1.69 |
| green | fin de semana | 4 | 2,680 | 1.23 |
| green | fin de semana | 5 | 1,538 | 0.7 |
| green | fin de semana | 6 | 1,922 | 0.88 |
| green | fin de semana | 7 | 3,553 | 1.63 |
| green | fin de semana | 8 | 5,039 | 2.31 |
| green | fin de semana | 9 | 7,567 | 3.46 |
| green | fin de semana | 10 | 9,518 | 4.36 |
| green | fin de semana | 11 | 11,368 | 5.2 |
| green | fin de semana | 12 | 13,072 | 5.98 |
| green | fin de semana | 13 | 13,340 | 6.1 |
| green | fin de semana | 14 | 14,595 | 6.68 |
| green | fin de semana | 15 | 15,422 | 7.06 |
| green | fin de semana | 16 | 15,695 | 7.18 |
| green | fin de semana | 17 | 15,510 | 7.1 |
| green | fin de semana | 18 | 15,938 | 7.29 |
| green | fin de semana | 19 | 13,717 | 6.28 |
| green | fin de semana | 20 | 11,544 | 5.28 |
| green | fin de semana | 21 | 10,439 | 4.78 |
| green | fin de semana | 22 | 8,664 | 3.96 |
| green | fin de semana | 23 | 7,372 | 3.37 |
| yellow | entre semana | 0 | 953,569 | 1.99 |
| yellow | entre semana | 1 | 474,690 | 0.99 |
| yellow | entre semana | 2 | 262,803 | 0.55 |
| yellow | entre semana | 3 | 178,318 | 0.37 |
| yellow | entre semana | 4 | 201,338 | 0.42 |
| yellow | entre semana | 5 | 378,064 | 0.79 |
| yellow | entre semana | 6 | 860,960 | 1.8 |
| yellow | entre semana | 7 | 1,681,736 | 3.51 |
| yellow | entre semana | 8 | 2,258,237 | 4.72 |
| yellow | entre semana | 9 | 2,248,440 | 4.7 |
| yellow | entre semana | 10 | 2,200,563 | 4.6 |
| yellow | entre semana | 11 | 2,306,742 | 4.82 |
| yellow | entre semana | 12 | 2,469,267 | 5.16 |
| yellow | entre semana | 13 | 2,558,318 | 5.34 |
| yellow | entre semana | 14 | 2,821,504 | 5.89 |
| yellow | entre semana | 15 | 2,945,674 | 6.15 |
| yellow | entre semana | 16 | 2,830,064 | 5.91 |
| yellow | entre semana | 17 | 3,183,051 | 6.65 |
| yellow | entre semana | 18 | 3,352,109 | 7 |
| yellow | entre semana | 19 | 2,962,232 | 6.19 |
| yellow | entre semana | 20 | 2,924,637 | 6.11 |
| yellow | entre semana | 21 | 3,057,587 | 6.39 |
| yellow | entre semana | 22 | 2,754,677 | 5.75 |
| yellow | entre semana | 23 | 2,020,601 | 4.22 |
| yellow | fin de semana | 0 | 1,076,672 | 5.63 |
| yellow | fin de semana | 1 | 852,234 | 4.46 |
| yellow | fin de semana | 2 | 607,349 | 3.18 |
| yellow | fin de semana | 3 | 414,782 | 2.17 |
| yellow | fin de semana | 4 | 255,478 | 1.34 |
| yellow | fin de semana | 5 | 125,383 | 0.66 |
| yellow | fin de semana | 6 | 178,618 | 0.93 |
| yellow | fin de semana | 7 | 247,434 | 1.29 |
| yellow | fin de semana | 8 | 375,460 | 1.96 |
| yellow | fin de semana | 9 | 580,931 | 3.04 |
| yellow | fin de semana | 10 | 762,238 | 3.99 |
| yellow | fin de semana | 11 | 903,244 | 4.73 |
| yellow | fin de semana | 12 | 1,021,773 | 5.35 |
| yellow | fin de semana | 13 | 1,080,054 | 5.65 |
| yellow | fin de semana | 14 | 1,098,829 | 5.75 |
| yellow | fin de semana | 15 | 1,102,062 | 5.77 |
| yellow | fin de semana | 16 | 1,147,941 | 6.01 |
| yellow | fin de semana | 17 | 1,182,779 | 6.19 |
| yellow | fin de semana | 18 | 1,204,524 | 6.3 |
| yellow | fin de semana | 19 | 1,118,162 | 5.85 |
| yellow | fin de semana | 20 | 978,803 | 5.12 |
| yellow | fin de semana | 21 | 954,886 | 5 |
| yellow | fin de semana | 22 | 960,067 | 5.02 |
| yellow | fin de semana | 23 | 884,075 | 4.63 |

## ind_velocidad_horaria

**Pregunta:** Q5 - Que tan congestionado esta el trafico a cada hora y como cambio entre anios?

**Objetivo:** Indicador I4 Velocidad mediana (mph) por hora del dia entre semana, por anio.

**Fuente:** `trips_clean`

```sql
SELECT file_year AS anio, hour(pickup_datetime) AS hora,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(median(duration_min), 1) AS duracion_mediana_min,
       count(*) AS viajes
FROM trips_clean
WHERE isodow(pickup_datetime) <= 5 AND taxi_type = 'yellow'
GROUP BY ALL
ORDER BY anio, hora;
```

**Resultado** (48 filas, 2.64 s):

| anio | hora | velocidad_mediana_mph | duracion_mediana_min | viajes |
|---|---|---|---|---|
| 2024 | 0 | 13.43 | 11.9 | 531,143 |
| 2024 | 1 | 14.12 | 10.8 | 253,008 |
| 2024 | 2 | 14.3 | 10.2 | 136,873 |
| 2024 | 3 | 15.09 | 10.6 | 90,537 |
| 2024 | 4 | 17.32 | 13.3 | 99,353 |
| 2024 | 5 | 16.16 | 11.7 | 187,162 |
| 2024 | 6 | 13.54 | 10.5 | 460,813 |
| 2024 | 7 | 10.72 | 11.3 | 943,065 |
| 2024 | 8 | 8.76 | 12.9 | 1,278,719 |
| 2024 | 9 | 8.2 | 13.6 | 1,300,053 |
| 2024 | 10 | 7.88 | 14.2 | 1,304,410 |
| 2024 | 11 | 7.5 | 14.7 | 1,374,000 |
| 2024 | 12 | 7.56 | 14.7 | 1,476,523 |
| 2024 | 13 | 7.8 | 14.6 | 1,528,917 |
| 2024 | 14 | 7.72 | 14.9 | 1,676,546 |
| 2024 | 15 | 7.68 | 14.7 | 1,745,162 |
| 2024 | 16 | 7.99 | 14.5 | 1,737,412 |
| 2024 | 17 | 8 | 14 | 1,953,244 |
| 2024 | 18 | 8.38 | 13 | 2,082,402 |
| 2024 | 19 | 9.2 | 12.3 | 1,811,390 |
| 2024 | 20 | 9.94 | 12.4 | 1,697,391 |
| 2024 | 21 | 10.38 | 12.6 | 1,764,071 |
| 2024 | 22 | 10.8 | 12.8 | 1,594,874 |
| 2024 | 23 | 11.54 | 12.7 | 1,158,300 |
| 2026 | 0 | 13.41 | 13.8 | 422,426 |
| 2026 | 1 | 14.37 | 13.1 | 221,682 |
| 2026 | 2 | 14.88 | 12.8 | 125,930 |
| 2026 | 3 | 15.54 | 13.4 | 87,781 |
| 2026 | 4 | 16.81 | 14.7 | 101,985 |
| 2026 | 5 | 15.77 | 13.5 | 190,902 |
| 2026 | 6 | 13.34 | 12.8 | 400,147 |
| 2026 | 7 | 10.63 | 13.2 | 738,671 |
| 2026 | 8 | 8.81 | 14.6 | 979,518 |
| 2026 | 9 | 8.1 | 15 | 948,387 |
| 2026 | 10 | 7.69 | 15.5 | 896,153 |
| 2026 | 11 | 7.33 | 16 | 932,742 |
| 2026 | 12 | 7.41 | 15.6 | 992,744 |
| 2026 | 13 | 7.57 | 15.5 | 1,029,401 |
| 2026 | 14 | 7.57 | 15.7 | 1,144,958 |
| 2026 | 15 | 7.42 | 15.6 | 1,200,512 |
| 2026 | 16 | 7.72 | 14.7 | 1,092,652 |
| 2026 | 17 | 7.84 | 14.1 | 1,229,807 |
| 2026 | 18 | 8.25 | 13.1 | 1,269,707 |
| 2026 | 19 | 8.94 | 12.9 | 1,150,842 |
| 2026 | 20 | 9.74 | 13.4 | 1,227,246 |
| 2026 | 21 | 10.05 | 13.6 | 1,293,516 |
| 2026 | 22 | 10.49 | 14 | 1,159,803 |
| 2026 | 23 | 11.33 | 14 | 862,301 |

## ind_mix_pago

**Pregunta:** Q6 - Como pagan los pasajeros y esta desapareciendo el efectivo?

**Objetivo:** Indicador I5 Participacion mensual de cada metodo de pago.

**Fuente:** `trips`

```sql
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       CASE coalesce(payment_type, 0) WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo'
            WHEN 0 THEN 'desconocido/flex' ELSE 'otros (sin cargo/disputa)' END AS metodo_pago,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, file_year, file_month), 2) AS pct
FROM trips
GROUP BY 1, 2, 3, 4, 5
ORDER BY periodo, taxi_type, metodo_pago;
```

**Resultado** (160 filas, 0.37 s):

| periodo | anio | mes | taxi_type | metodo_pago | viajes | pct |
|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | desconocido/flex | 3,415 | 6.04 |
| 2024-01-01 00:00:00 | 2024 | 1 | green | efectivo | 15,913 | 28.14 |
| 2024-01-01 00:00:00 | 2024 | 1 | green | otros (sin cargo/disputa) | 563 | 1 |
| 2024-01-01 00:00:00 | 2024 | 1 | green | tarjeta | 36,660 | 64.83 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | desconocido/flex | 140,162 | 4.73 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | efectivo | 439,191 | 14.81 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | otros (sin cargo/disputa) | 66,225 | 2.23 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | tarjeta | 2,319,046 | 78.22 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | desconocido/flex | 2,928 | 5.47 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | efectivo | 14,757 | 27.54 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | otros (sin cargo/disputa) | 488 | 0.91 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | tarjeta | 35,404 | 66.08 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | desconocido/flex | 185,610 | 6.17 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | efectivo | 413,254 | 13.74 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | otros (sin cargo/disputa) | 66,652 | 2.22 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | tarjeta | 2,342,010 | 77.87 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | desconocido/flex | 2,097 | 3.65 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | efectivo | 16,608 | 28.91 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | otros (sin cargo/disputa) | 503 | 0.88 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | tarjeta | 38,249 | 66.57 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | desconocido/flex | 426,190 | 11.9 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | efectivo | 477,660 | 13.33 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | otros (sin cargo/disputa) | 81,676 | 2.28 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | tarjeta | 2,597,102 | 72.49 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | desconocido/flex | 1,988 | 3.52 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | efectivo | 14,935 | 26.45 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | otros (sin cargo/disputa) | 550 | 0.97 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | tarjeta | 38,998 | 69.06 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | desconocido/flex | 408,576 | 11.63 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | efectivo | 470,436 | 13.39 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | otros (sin cargo/disputa) | 79,708 | 2.27 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | tarjeta | 2,555,569 | 72.72 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | desconocido/flex | 1,892 | 3.1 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | efectivo | 16,159 | 26.49 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | otros (sin cargo/disputa) | 599 | 0.98 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | tarjeta | 42,353 | 69.43 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | desconocido/flex | 404,666 | 10.87 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | efectivo | 502,495 | 13.49 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | otros (sin cargo/disputa) | 88,794 | 2.38 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | tarjeta | 2,727,878 | 73.25 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | desconocido/flex | 1,899 | 3.47 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | efectivo | 14,498 | 26.48 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | otros (sin cargo/disputa) | 521 | 0.95 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | tarjeta | 37,830 | 69.1 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | desconocido/flex | 410,781 | 11.61 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | efectivo | 470,031 | 13.28 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | otros (sin cargo/disputa) | 88,057 | 2.49 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | tarjeta | 2,570,324 | 72.62 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | desconocido/flex | 1,609 | 3.1 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | efectivo | 13,828 | 26.68 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | otros (sin cargo/disputa) | 509 | 0.98 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | tarjeta | 35,891 | 69.24 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | desconocido/flex | 278,989 | 9.07 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | efectivo | 454,577 | 14.77 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | otros (sin cargo/disputa) | 90,668 | 2.95 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | tarjeta | 2,252,669 | 73.21 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | desconocido/flex | 1,584 | 3.06 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | efectivo | 13,804 | 26.66 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | otros (sin cargo/disputa) | 564 | 1.09 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | tarjeta | 35,819 | 69.19 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | desconocido/flex | 258,667 | 8.68 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | efectivo | 449,387 | 15.08 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | otros (sin cargo/disputa) | 94,620 | 3.18 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | tarjeta | 2,176,509 | 73.06 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | desconocido/flex | 1,704 | 3.13 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | efectivo | 13,843 | 25.43 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | otros (sin cargo/disputa) | 504 | 0.93 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | tarjeta | 38,389 | 70.52 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | desconocido/flex | 483,731 | 13.31 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | efectivo | 445,230 | 12.26 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | otros (sin cargo/disputa) | 99,398 | 2.74 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | tarjeta | 2,604,671 | 71.69 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | desconocido/flex | 1,645 | 2.93 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | efectivo | 14,217 | 25.32 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | otros (sin cargo/disputa) | 468 | 0.83 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | tarjeta | 39,817 | 70.92 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | desconocido/flex | 393,895 | 10.27 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | efectivo | 477,350 | 12.45 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | otros (sin cargo/disputa) | 108,434 | 2.83 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | tarjeta | 2,854,092 | 74.45 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | desconocido/flex | 1,586 | 3.04 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | efectivo | 12,916 | 24.73 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | otros (sin cargo/disputa) | 427 | 0.82 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | tarjeta | 37,293 | 71.41 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | desconocido/flex | 373,674 | 10.25 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | efectivo | 449,826 | 12.34 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | otros (sin cargo/disputa) | 103,949 | 2.85 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | tarjeta | 2,718,920 | 74.57 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | desconocido/flex | 1,981 | 3.67 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | efectivo | 13,535 | 25.07 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | otros (sin cargo/disputa) | 494 | 0.91 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | tarjeta | 37,984 | 70.35 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | desconocido/flex | 326,291 | 8.89 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | efectivo | 490,651 | 13.38 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | otros (sin cargo/disputa) | 118,060 | 3.22 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | tarjeta | 2,733,369 | 74.51 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | desconocido/flex | 5,414 | 13.44 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | efectivo | 8,297 | 20.6 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | otros (sin cargo/disputa) | 331 | 0.82 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | tarjeta | 26,230 | 65.13 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | desconocido/flex | 1,088,058 | 29.21 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | efectivo | 314,043 | 8.43 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | otros (sin cargo/disputa) | 73,041 | 1.96 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | tarjeta | 2,249,747 | 60.4 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | desconocido/flex | 5,387 | 14.41 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | efectivo | 7,541 | 20.18 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | otros (sin cargo/disputa) | 326 | 0.87 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | tarjeta | 24,119 | 64.54 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | desconocido/flex | 1,023,317 | 30.1 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | efectivo | 273,616 | 8.05 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | otros (sin cargo/disputa) | 51,272 | 1.51 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | tarjeta | 2,051,661 | 60.35 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | desconocido/flex | 6,692 | 15.14 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | efectivo | 8,609 | 19.47 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | otros (sin cargo/disputa) | 303 | 0.69 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | tarjeta | 28,604 | 64.7 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | desconocido/flex | 945,748 | 23.93 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | efectivo | 353,541 | 8.94 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | otros (sin cargo/disputa) | 44,332 | 1.12 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | tarjeta | 2,608,830 | 66.01 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | desconocido/flex | 6,290 | 14.22 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | efectivo | 8,531 | 19.28 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | otros (sin cargo/disputa) | 337 | 0.76 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | tarjeta | 29,080 | 65.74 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | desconocido/flex | 799,786 | 20.88 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | efectivo | 360,995 | 9.42 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | otros (sin cargo/disputa) | 34,710 | 0.91 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | tarjeta | 2,635,749 | 68.8 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | desconocido/flex | 5,772 | 12.85 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | efectivo | 8,910 | 19.83 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | otros (sin cargo/disputa) | 301 | 0.67 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | tarjeta | 29,938 | 66.65 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | desconocido/flex | 955,371 | 23.35 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | efectivo | 372,909 | 9.12 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | otros (sin cargo/disputa) | 34,971 | 0.85 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | tarjeta | 2,727,585 | 66.68 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | desconocido/flex | 6,472 | 14.65 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | efectivo | 8,433 | 19.1 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | otros (sin cargo/disputa) | 291 | 0.66 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | tarjeta | 28,967 | 65.59 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | desconocido/flex | 1,013,500 | 26.41 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | efectivo | 357,804 | 9.32 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | otros (sin cargo/disputa) | 33,073 | 0.86 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | tarjeta | 2,432,871 | 63.4 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | desconocido/flex | 6,435 | 15.6 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | efectivo | 7,553 | 18.31 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | otros (sin cargo/disputa) | 278 | 0.67 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | tarjeta | 26,986 | 65.42 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | desconocido/flex | 969,727 | 27.47 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | efectivo | 345,646 | 9.79 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | otros (sin cargo/disputa) | 32,275 | 0.91 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | tarjeta | 2,182,461 | 61.82 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | desconocido/flex | 6,313 | 15.52 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | efectivo | 8,047 | 19.78 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | otros (sin cargo/disputa) | 271 | 0.67 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | tarjeta | 26,056 | 64.04 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | desconocido/flex | 921,181 | 27.61 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | efectivo | 329,477 | 9.87 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | otros (sin cargo/disputa) | 33,954 | 1.02 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | tarjeta | 2,052,104 | 61.5 |

## ind_propina_tarjeta

**Pregunta:** Q7 - Cuanta propina dejan los pasajeros que pagan con tarjeta y como evoluciona?

**Objetivo:** Indicador I6 Propina como % de la tarifa y % de viajes con propina (solo tarjeta, donde se registra).

**Fuente:** `trips_clean`

```sql
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       count(*) AS viajes_tarjeta,
       round(100.0 * sum(tip_amount) / sum(fare_amount), 2) AS propina_pct_tarifa,
       round(100.0 * avg(CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END), 2) AS pct_con_propina,
       round(avg(tip_amount), 2) AS propina_promedio_usd
FROM trips_clean
WHERE payment_type = 1
GROUP BY ALL
ORDER BY periodo, taxi_type;
```

**Resultado** (40 filas, 0.55 s):

| periodo | anio | mes | taxi_type | viajes_tarjeta | propina_pct_tarifa | pct_con_propina | propina_promedio_usd |
|---|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | 33,830 | 21.29 | 91.86 | 3.36 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | 2,268,155 | 22.64 | 95.35 | 4.15 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | 32,570 | 21.05 | 91.52 | 3.4 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | 2,289,786 | 22.61 | 95.2 | 4.14 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | 35,143 | 21.01 | 91.66 | 3.49 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | 2,538,012 | 22.41 | 94.84 | 4.28 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | 35,818 | 21.08 | 91.91 | 3.56 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | 2,498,454 | 22.34 | 94.76 | 4.32 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | 38,987 | 20.69 | 91.77 | 3.73 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | 2,667,839 | 22.15 | 94.68 | 4.41 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | 35,020 | 20.43 | 91.38 | 3.75 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | 2,513,522 | 22.03 | 94.32 | 4.35 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | 32,849 | 20.62 | 91.54 | 3.72 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | 2,203,848 | 21.57 | 93.42 | 4.34 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | 33,025 | 20.13 | 90.64 | 3.91 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | 2,127,832 | 21.43 | 93 | 4.35 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | 35,328 | 19.94 | 91.28 | 3.99 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | 2,550,317 | 21.75 | 94.23 | 4.5 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | 36,963 | 20.56 | 91.71 | 3.77 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | 2,792,871 | 22.06 | 94.62 | 4.49 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | 34,176 | 20.76 | 91.53 | 3.62 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | 2,667,362 | 22.04 | 94.31 | 4.33 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | 34,719 | 20.99 | 91.52 | 3.56 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | 2,676,952 | 22.2 | 94.29 | 4.47 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | 24,579 | 21.66 | 91.89 | 3.61 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | 2,173,656 | 21.23 | 90.65 | 4.1 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | 22,526 | 21.65 | 91.59 | 3.67 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | 1,983,849 | 21.19 | 90.57 | 4.14 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | 26,896 | 21.71 | 91.91 | 3.73 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | 2,528,392 | 21.14 | 90.2 | 4.13 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | 27,277 | 21.58 | 92.22 | 3.8 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | 2,555,499 | 21.08 | 90.04 | 4.18 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | 28,115 | 20.93 | 91.93 | 3.87 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | 2,642,561 | 21.11 | 90.19 | 4.26 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | 27,098 | 20.86 | 91.81 | 3.87 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | 2,350,572 | 23.11 | 94.94 | 4.52 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | 25,135 | 20.44 | 91.18 | 3.82 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | 2,108,605 | 22.36 | 91.97 | 4.34 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | 24,316 | 20.59 | 91.27 | 3.94 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | 1,982,161 | 22.08 | 90.85 | 4.28 |

## ind_aeropuertos

**Pregunta:** Q8 - Que peso tienen los viajes de aeropuerto en la demanda y en los ingresos?

**Objetivo:** Indicador I7 % de viajes y % de ingresos de viajes que tocan JFK, LaGuardia o Newark, por anio.

**Fuente:** `trips_clean + zones`

```sql
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
```

**Resultado** (8 filas, 0.82 s):

| anio | taxi_type | segmento | viajes | pct_viajes | pct_ingresos | total_promedio_usd |
|---|---|---|---|---|---|---|
| 2024 | green | aeropuerto | 25,789 | 4.25 | 8.26 | 46.77 |
| 2024 | green | resto | 580,799 | 95.75 | 91.74 | 23.08 |
| 2024 | yellow | aeropuerto | 3,955,294 | 10.11 | 27.89 | 78.97 |
| 2024 | yellow | resto | 35,158,750 | 89.89 | 72.11 | 22.97 |
| 2026 | green | aeropuerto | 10,641 | 3.44 | 6.57 | 48.39 |
| 2026 | green | resto | 298,796 | 96.56 | 93.43 | 24.5 |
| 2026 | yellow | aeropuerto | 2,273,124 | 8.15 | 21.06 | 77.96 |
| 2026 | yellow | resto | 25,611,791 | 91.85 | 78.94 | 25.94 |

## ind_borough_origen

**Pregunta:** Q9 - Donde se originan los viajes de cada tipo de taxi y esta cambiando esa distribucion?

**Objetivo:** Indicador I8 Participacion de cada borough de origen por anio y tipo de taxi.

**Fuente:** `trips_clean + zones`

```sql
SELECT t.file_year AS anio, t.taxi_type, t.taxi_type || ' ' || t.file_year AS serie,
       CASE WHEN z.borough IN ('Manhattan', 'Queens', 'Brooklyn', 'Bronx') THEN z.borough ELSE 'Otros/Desconocido' END AS borough,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.file_year, t.taxi_type), 2) AS pct
FROM trips_clean t JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY 1, 2, 3, 4
ORDER BY anio, taxi_type, viajes DESC;
```

**Resultado** (20 filas, 0.80 s):

| anio | taxi_type | serie | borough | viajes | pct |
|---|---|---|---|---|---|
| 2024 | green | green 2024 | Manhattan | 371,876 | 61.31 |
| 2024 | green | green 2024 | Queens | 148,427 | 24.47 |
| 2024 | green | green 2024 | Brooklyn | 79,318 | 13.08 |
| 2024 | green | green 2024 | Bronx | 6,422 | 1.06 |
| 2024 | green | green 2024 | Otros/Desconocido | 545 | 0.09 |
| 2024 | yellow | yellow 2024 | Manhattan | 34,757,033 | 88.86 |
| 2024 | yellow | yellow 2024 | Queens | 3,582,895 | 9.16 |
| 2024 | yellow | yellow 2024 | Brooklyn | 546,633 | 1.4 |
| 2024 | yellow | yellow 2024 | Otros/Desconocido | 115,449 | 0.3 |
| 2024 | yellow | yellow 2024 | Bronx | 112,034 | 0.29 |
| 2026 | green | green 2026 | Manhattan | 187,600 | 60.63 |
| 2026 | green | green 2026 | Queens | 68,179 | 22.03 |
| 2026 | green | green 2026 | Brooklyn | 46,263 | 14.95 |
| 2026 | green | green 2026 | Bronx | 6,995 | 2.26 |
| 2026 | green | green 2026 | Otros/Desconocido | 400 | 0.13 |
| 2026 | yellow | yellow 2026 | Manhattan | 24,180,526 | 86.72 |
| 2026 | yellow | yellow 2026 | Queens | 2,450,756 | 8.79 |
| 2026 | yellow | yellow 2026 | Brooklyn | 1,002,301 | 3.59 |
| 2026 | yellow | yellow 2026 | Bronx | 215,966 | 0.77 |
| 2026 | yellow | yellow 2026 | Otros/Desconocido | 35,366 | 0.13 |

## ind_cuota_congestion

**Pregunta:** Q10 - Cuantos viajes pagan la nueva cuota de congestion de Manhattan (CBD) y cuanto recauda?

**Objetivo:** Indicador I9 % de viajes con cbd_congestion_fee > 0 y monto mensual recaudado (desde enero 2025).

**Fuente:** `trips`

```sql
SELECT make_date(file_year, file_month, 1) AS periodo, file_year AS anio, file_month AS mes, taxi_type,
       round(100.0 * avg(CASE WHEN coalesce(cbd_congestion_fee, 0) > 0 THEN 1 ELSE 0 END), 2) AS pct_viajes_con_cuota,
       round(sum(coalesce(cbd_congestion_fee, 0)), 2) AS recaudacion_usd,
       round(avg(coalesce(congestion_surcharge, 0)), 3) AS recargo_congestion_prom
FROM trips
GROUP BY ALL
ORDER BY periodo, taxi_type;
```

**Resultado** (40 filas, 0.29 s):

| periodo | anio | mes | taxi_type | pct_viajes_con_cuota | recaudacion_usd | recargo_congestion_prom |
|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | 0 | 0 | 0.73 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | 0 | 0 | 2.149 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | 0 | 0 | 0.736 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | 0 | 0 | 2.127 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | 0 | 0 | 0.711 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | 0 | 0 | 1.984 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | 0 | 0 | 0.787 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | 0 | 0 | 1.984 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | 0 | 0 | 0.809 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | 0 | 0 | 1.998 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | 0 | 0 | 0.817 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | 0 | 0 | 1.979 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | 0 | 0 | 0.823 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | 0 | 0 | 1.997 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | 0 | 0 | 0.792 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | 0 | 0 | 1.985 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | 0 | 0 | 0.791 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | 0 | 0 | 1.924 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | 0 | 0 | 0.806 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | 0 | 0 | 2.001 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | 0 | 0 | 0.807 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | 0 | 0 | 2.008 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | 0 | 0 | 0.79 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | 0 | 0 | 2.024 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | 7.76 | 2,343 | 0.737 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | 69.96 | 1,935,615 | 1.525 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | 6.96 | 1,950.75 | 0.688 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | 70.18 | 1,776,365.25 | 1.519 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | 7.91 | 2,622.75 | 0.726 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | 70.99 | 2,093,814.75 | 1.664 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | 8.22 | 2,726.25 | 0.766 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | 71.3 | 2,041,593.75 | 1.737 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | 8.68 | 2,922 | 0.782 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | 66.04 | 2,018,902.5 | 1.689 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | 8.34 | 2,763 | 0.782 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | 73.62 | 2,111,717.25 | 1.691 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | 8.97 | 2,774.25 | 0.781 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | 76.63 | 2,021,483.25 | 1.649 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | 9.56 | 2,913.75 | 0.772 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | 76.52 | 1,907,805 | 1.632 |

## ind_calidad_datos

**Pregunta:** Q11 - Que tan confiables son los datos de cada mes?

**Objetivo:** Indicador I10 % de registros validos (trips_clean) y % de viajes sin datos de taximetro (payment_type 0/NULL).

**Fuente:** `trips + trips_clean`

```sql
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
```

**Resultado** (40 filas, 0.58 s):

| periodo | anio | mes | taxi_type | registros | validos | pct_validos | pct_sin_datos_taximetro |
|---|---|---|---|---|---|---|---|
| 2024-01-01 00:00:00 | 2024 | 1 | green | 56,551 | 52,123 | 92.17 | 6.04 |
| 2024-01-01 00:00:00 | 2024 | 1 | yellow | 2,964,624 | 2,826,660 | 95.35 | 4.73 |
| 2024-02-01 00:00:00 | 2024 | 2 | green | 53,577 | 49,303 | 92.02 | 5.47 |
| 2024-02-01 00:00:00 | 2024 | 2 | yellow | 3,007,526 | 2,856,388 | 94.97 | 6.17 |
| 2024-03-01 00:00:00 | 2024 | 3 | green | 57,457 | 52,929 | 92.12 | 3.65 |
| 2024-03-01 00:00:00 | 2024 | 3 | yellow | 3,582,628 | 3,386,216 | 94.52 | 11.9 |
| 2024-04-01 00:00:00 | 2024 | 4 | green | 56,471 | 51,823 | 91.77 | 3.52 |
| 2024-04-01 00:00:00 | 2024 | 4 | yellow | 3,514,289 | 3,361,333 | 95.65 | 11.63 |
| 2024-05-01 00:00:00 | 2024 | 5 | green | 61,003 | 56,154 | 92.05 | 3.1 |
| 2024-05-01 00:00:00 | 2024 | 5 | yellow | 3,723,833 | 3,562,428 | 95.67 | 10.87 |
| 2024-06-01 00:00:00 | 2024 | 6 | green | 54,748 | 50,488 | 92.22 | 3.47 |
| 2024-06-01 00:00:00 | 2024 | 6 | yellow | 3,539,193 | 3,377,399 | 95.43 | 11.61 |
| 2024-07-01 00:00:00 | 2024 | 7 | green | 51,837 | 47,386 | 91.41 | 3.1 |
| 2024-07-01 00:00:00 | 2024 | 7 | yellow | 3,076,903 | 2,930,958 | 95.26 | 9.07 |
| 2024-08-01 00:00:00 | 2024 | 8 | green | 51,771 | 47,443 | 91.64 | 3.06 |
| 2024-08-01 00:00:00 | 2024 | 8 | yellow | 2,979,183 | 2,825,847 | 94.85 | 8.68 |
| 2024-09-01 00:00:00 | 2024 | 9 | green | 54,440 | 49,958 | 91.77 | 3.13 |
| 2024-09-01 00:00:00 | 2024 | 9 | yellow | 3,633,030 | 3,432,131 | 94.47 | 13.31 |
| 2024-10-01 00:00:00 | 2024 | 10 | green | 56,147 | 51,910 | 92.45 | 2.93 |
| 2024-10-01 00:00:00 | 2024 | 10 | yellow | 3,833,771 | 3,625,576 | 94.57 | 10.27 |
| 2024-11-01 00:00:00 | 2024 | 11 | green | 52,222 | 47,804 | 91.54 | 3.04 |
| 2024-11-01 00:00:00 | 2024 | 11 | yellow | 3,646,369 | 3,461,982 | 94.94 | 10.25 |
| 2024-12-01 00:00:00 | 2024 | 12 | green | 53,994 | 49,267 | 91.25 | 3.67 |
| 2024-12-01 00:00:00 | 2024 | 12 | yellow | 3,668,371 | 3,467,126 | 94.51 | 8.89 |
| 2026-01-01 00:00:00 | 2026 | 1 | green | 40,272 | 37,164 | 92.28 | 13.44 |
| 2026-01-01 00:00:00 | 2026 | 1 | yellow | 3,724,889 | 3,467,593 | 93.09 | 29.21 |
| 2026-02-01 00:00:00 | 2026 | 2 | green | 37,373 | 34,226 | 91.58 | 14.41 |
| 2026-02-01 00:00:00 | 2026 | 2 | yellow | 3,399,866 | 3,163,298 | 93.04 | 30.1 |
| 2026-03-01 00:00:00 | 2026 | 3 | green | 44,208 | 40,742 | 92.16 | 15.14 |
| 2026-03-01 00:00:00 | 2026 | 3 | yellow | 3,952,451 | 3,716,409 | 94.03 | 23.93 |
| 2026-04-01 00:00:00 | 2026 | 4 | green | 44,238 | 40,704 | 92.01 | 14.22 |
| 2026-04-01 00:00:00 | 2026 | 4 | yellow | 3,831,240 | 3,635,775 | 94.9 | 20.88 |
| 2026-05-01 00:00:00 | 2026 | 5 | green | 44,921 | 41,369 | 92.09 | 12.85 |
| 2026-05-01 00:00:00 | 2026 | 5 | yellow | 4,090,836 | 3,868,182 | 94.56 | 23.35 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | 44,163 | 40,562 | 91.85 | 14.65 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | 3,837,248 | 3,600,368 | 93.83 | 26.41 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | 41,252 | 37,542 | 91.01 | 15.6 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | 3,530,109 | 3,305,175 | 93.63 | 27.47 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | 40,687 | 37,128 | 91.25 | 15.52 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | 3,336,716 | 3,128,115 | 93.75 | 27.61 |

## ind_plataformas

**Pregunta:** Q12 - Que proporcion de viajes de taxi se solicita a traves de plataformas (Uber/Lyft) desde que existe el dato?

**Objetivo:** Indicador I11 Participacion de request_source por mes (solo meses en que la columna existe, jun-2026 en adelante).

**Fuente:** `trips`

```sql
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
```

**Resultado** (17 filas, 0.14 s):

| periodo | anio | mes | taxi_type | origen | viajes | pct |
|---|---|---|---|---|---|---|
| 2026-06-01 00:00:00 | 2026 | 6 | green | calle/sin dato | 37,692 | 85.35 |
| 2026-06-01 00:00:00 | 2026 | 6 | green | otras apps/despacho | 6,471 | 14.65 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | Uber (HV0003) | 927,698 | 24.18 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | calle/sin dato | 2,824,068 | 73.6 |
| 2026-06-01 00:00:00 | 2026 | 6 | yellow | otras apps/despacho | 85,482 | 2.23 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | calle/sin dato | 34,822 | 84.41 |
| 2026-07-01 00:00:00 | 2026 | 7 | green | otras apps/despacho | 6,430 | 15.59 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | Uber (HV0003) | 739,048 | 20.94 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | calle/sin dato | 2,560,692 | 72.54 |
| 2026-07-01 00:00:00 | 2026 | 7 | yellow | otras apps/despacho | 230,369 | 6.53 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | Lyft (HV0005) | 1,179 | 2.9 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | calle/sin dato | 34,377 | 84.49 |
| 2026-08-01 00:00:00 | 2026 | 8 | green | otras apps/despacho | 5,131 | 12.61 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | Lyft (HV0005) | 181,233 | 5.43 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | Uber (HV0003) | 628,774 | 18.84 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | calle/sin dato | 2,415,867 | 72.4 |
| 2026-08-01 00:00:00 | 2026 | 8 | yellow | otras apps/despacho | 110,842 | 3.32 |

## ind_resumen_anual

**Pregunta:** Q13 - Como se comparan los anios en sus metricas principales (mismos meses)?

**Objetivo:** Tabla resumen por anio y tipo de taxi, restringida a enero-agosto para comparar periodos equivalentes.

**Fuente:** `trips_clean`

```sql
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
```

**Resultado** (4 filas, 3.83 s):

| anio | taxi_type | viajes_ene_ago | viajes_por_dia | total_promedio_usd | distancia_mediana_mi | duracion_mediana_min | velocidad_mediana_mph | pct_tarjeta | propina_pct_tarjeta |
|---|---|---|---|---|---|---|---|---|---|
| 2024 | yellow | 25,127,229 | 102,980 | 28.33 | 1.8 | 12.8 | 9.53 | 76.04 | 22.15 |
| 2024 | green | 407,649 | 1,671 | 23.74 | 1.98 | 12 | 10.4 | 68.01 | 20.77 |
| 2026 | yellow | 27,884,915 | 114,753 | 30.18 | 1.95 | 14.2 | 9.31 | 65.72 | 21.63 |
| 2026 | green | 309,437 | 1,273 | 25.32 | 2.15 | 13.3 | 10.06 | 66.55 | 21.15 |
