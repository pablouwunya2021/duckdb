# Resultados de `sql/04_eda.sql`

Generado con `python scripts/run_sql.py sql/04_eda.sql` el 2026-10-07 02:40. Origen de datos: archivos Parquet (vistas de `sql/00_vistas.sql`).

## q4_01_viajes_por_mes

**Pregunta:** P1 (temporal) - Como evoluciona el volumen mensual de viajes de cada tipo de taxi?

**Objetivo:** Contar viajes, ingresos y viajes promedio por dia para cada mes y tipo.

**Fuente:** `vista trips`

```sql
SELECT taxi_type, file_year AS anio, file_month AS mes,
       count(*)                                   AS viajes,
       round(count(*) / max(day(last_day(make_date(file_year, file_month, 1)))), 0) AS viajes_por_dia,
       round(sum(total_amount) / 1e6, 2)          AS ingresos_musd
FROM trips
GROUP BY ALL
ORDER BY taxi_type, anio, mes;
```

**Resultado** (64 filas, 0.38 s):

| taxi_type | anio | mes | viajes | viajes_por_dia | ingresos_musd |
|---|---|---|---|---|---|
| green | 2024 | 1 | 56,551 | 1,824 | 1.27 |
| green | 2024 | 2 | 53,577 | 1,847 | 1.21 |
| green | 2024 | 3 | 57,457 | 1,853 | 1.32 |
| green | 2024 | 4 | 56,471 | 1,882 | 1.32 |
| green | 2024 | 5 | 61,003 | 1,968 | 1.5 |
| green | 2024 | 6 | 54,748 | 1,825 | 1.36 |
| green | 2024 | 7 | 51,837 | 1,672 | 1.28 |
| green | 2024 | 8 | 51,771 | 1,670 | 1.34 |
| green | 2024 | 9 | 54,440 | 1,815 | 1.45 |
| green | 2024 | 10 | 56,147 | 1,811 | 1.41 |
| green | 2024 | 11 | 52,222 | 1,741 | 1.26 |
| green | 2024 | 12 | 53,994 | 1,742 | 1.3 |
| green | 2025 | 1 | 48,326 | 1,559 | 1.09 |
| green | 2025 | 2 | 46,621 | 1,665 | 1.07 |
| green | 2025 | 3 | 51,539 | 1,663 | 1.24 |
| green | 2025 | 4 | 52,132 | 1,738 | 1.28 |
| green | 2025 | 5 | 55,399 | 1,787 | 1.41 |
| green | 2025 | 6 | 49,390 | 1,646 | 1.27 |
| green | 2025 | 7 | 48,205 | 1,555 | 1.24 |
| green | 2025 | 8 | 46,306 | 1,494 | 1.29 |
| green | 2025 | 9 | 48,893 | 1,630 | 1.35 |
| green | 2025 | 10 | 49,416 | 1,594 | 1.28 |
| green | 2025 | 11 | 46,912 | 1,564 | 1.18 |
| green | 2025 | 12 | 48,236 | 1,556 | 1.2 |
| green | 2026 | 1 | 40,272 | 1,299 | 0.97 |
| green | 2026 | 2 | 37,373 | 1,335 | 0.91 |
| green | 2026 | 3 | 44,208 | 1,426 | 1.1 |
| green | 2026 | 4 | 44,238 | 1,475 | 1.12 |
| green | 2026 | 5 | 44,921 | 1,449 | 1.16 |
| green | 2026 | 6 | 44,163 | 1,472 | 1.16 |
| green | 2026 | 7 | 41,252 | 1,331 | 1.08 |
| green | 2026 | 8 | 40,687 | 1,312 | 1.08 |
| yellow | 2024 | 1 | 2,964,624 | 95,633 | 79.46 |
| yellow | 2024 | 2 | 3,007,526 | 103,708 | 80.07 |
| yellow | 2024 | 3 | 3,582,628 | 115,569 | 97.16 |
| yellow | 2024 | 4 | 3,514,289 | 117,143 | 96.62 |
| yellow | 2024 | 5 | 3,723,833 | 120,124 | 105.66 |
| yellow | 2024 | 6 | 3,539,193 | 117,973 | 98.85 |
| yellow | 2024 | 7 | 3,076,903 | 99,255 | 86.42 |
| yellow | 2024 | 8 | 2,979,183 | 96,103 | 84.23 |
| yellow | 2024 | 9 | 3,633,030 | 121,101 | 103.68 |
| yellow | 2024 | 10 | 3,833,771 | 123,670 | 108.99 |
| yellow | 2024 | 11 | 3,646,369 | 121,546 | 100.83 |
| yellow | 2024 | 12 | 3,668,371 | 118,335 | 103.89 |
| yellow | 2025 | 1 | 3,475,226 | 112,104 | 89.01 |
| yellow | 2025 | 2 | 3,577,543 | 127,769 | 89.55 |
| yellow | 2025 | 3 | 4,145,257 | 133,718 | 108.88 |
| yellow | 2025 | 4 | 3,970,553 | 132,352 | 105.6 |
| yellow | 2025 | 5 | 4,591,845 | 148,124 | 123.43 |
| yellow | 2025 | 6 | 4,322,960 | 144,099 | 118.39 |
| yellow | 2025 | 7 | 3,898,963 | 125,773 | 104.6 |
| yellow | 2025 | 8 | 3,574,091 | 115,293 | 94.32 |
| yellow | 2025 | 9 | 4,251,015 | 141,701 | 117.81 |
| yellow | 2025 | 10 | 4,428,699 | 142,861 | 119.46 |
| yellow | 2025 | 11 | 4,181,444 | 139,381 | 107.11 |
| yellow | 2025 | 12 | 4,305,006 | 138,871 | 132.92 |
| yellow | 2026 | 1 | 3,724,889 | 120,158 | 108.69 |
| yellow | 2026 | 2 | 3,399,866 | 121,424 | 102.38 |
| yellow | 2026 | 3 | 3,952,451 | 127,498 | 118.96 |
| yellow | 2026 | 4 | 3,831,240 | 127,708 | 114.94 |
| yellow | 2026 | 5 | 4,090,836 | 131,962 | 124.71 |
| yellow | 2026 | 6 | 3,837,248 | 127,908 | 117.09 |
| yellow | 2026 | 7 | 3,530,109 | 113,874 | 106.06 |
| yellow | 2026 | 8 | 3,336,716 | 107,636 | 100.35 |

## q4_02_viajes_hora_dia

**Pregunta:** P2 (temporal) - En que horas y dias de la semana se concentra la demanda?

**Objetivo:** Matriz dia de la semana x hora con el promedio de viajes por hora (normalizado por numero de dias).

**Fuente:** `vista trips_clean`

```sql
WITH base AS (
    SELECT taxi_type, isodow(pickup_datetime) AS dow, hour(pickup_datetime) AS hora,
           CAST(pickup_datetime AS DATE) AS fecha
    FROM trips_clean
)
SELECT taxi_type, dow, hora, round(count(*) / count(DISTINCT fecha), 1) AS viajes_promedio
FROM base
GROUP BY ALL
ORDER BY taxi_type, dow, hora;
```

**Resultado** (336 filas, 1.98 s):

| taxi_type | dow | hora | viajes_promedio |
|---|---|---|---|
| green | 1 | 0 | 17.6 |
| green | 1 | 1 | 9.9 |
| green | 1 | 2 | 6.5 |
| green | 1 | 3 | 4.7 |
| green | 1 | 4 | 5.3 |
| green | 1 | 5 | 9.9 |
| green | 1 | 6 | 31.5 |
| green | 1 | 7 | 69 |
| green | 1 | 8 | 89.8 |
| green | 1 | 9 | 91 |
| green | 1 | 10 | 85.4 |
| green | 1 | 11 | 80.2 |
| green | 1 | 12 | 85.4 |
| green | 1 | 13 | 84.2 |
| green | 1 | 14 | 97.8 |
| green | 1 | 15 | 104.1 |
| green | 1 | 16 | 114.3 |
| green | 1 | 17 | 123.8 |
| green | 1 | 18 | 114.7 |
| green | 1 | 19 | 86.2 |
| green | 1 | 20 | 64.2 |
| green | 1 | 21 | 51.7 |
| green | 1 | 22 | 40.7 |
| green | 1 | 23 | 26.5 |
| green | 2 | 0 | 15.2 |
| green | 2 | 1 | 8.5 |
| green | 2 | 2 | 5 |
| green | 2 | 3 | 3.2 |
| green | 2 | 4 | 4.1 |
| green | 2 | 5 | 8.4 |
| green | 2 | 6 | 32 |
| green | 2 | 7 | 74.8 |
| green | 2 | 8 | 97.4 |
| green | 2 | 9 | 99.7 |
| green | 2 | 10 | 91.7 |
| green | 2 | 11 | 85.6 |
| green | 2 | 12 | 88.7 |
| green | 2 | 13 | 88.1 |
| green | 2 | 14 | 97.8 |
| green | 2 | 15 | 107.9 |
| green | 2 | 16 | 119.2 |
| green | 2 | 17 | 130.7 |
| green | 2 | 18 | 123.5 |
| green | 2 | 19 | 94.2 |
| green | 2 | 20 | 69.3 |
| green | 2 | 21 | 59.9 |
| green | 2 | 22 | 48.2 |
| green | 2 | 23 | 30.8 |
| green | 3 | 0 | 17.9 |
| green | 3 | 1 | 10.3 |
| green | 3 | 2 | 5.5 |
| green | 3 | 3 | 4.1 |
| green | 3 | 4 | 4.3 |
| green | 3 | 5 | 9 |
| green | 3 | 6 | 32.1 |
| green | 3 | 7 | 74.3 |
| green | 3 | 8 | 98.4 |
| green | 3 | 9 | 99.3 |
| green | 3 | 10 | 92 |
| green | 3 | 11 | 87.8 |
| green | 3 | 12 | 90.5 |
| green | 3 | 13 | 90.5 |
| green | 3 | 14 | 101.8 |
| green | 3 | 15 | 112.3 |
| green | 3 | 16 | 125.6 |
| green | 3 | 17 | 139.2 |
| green | 3 | 18 | 129.4 |
| green | 3 | 19 | 98.3 |
| green | 3 | 20 | 72.9 |
| green | 3 | 21 | 63.5 |
| green | 3 | 22 | 51 |
| green | 3 | 23 | 36.1 |
| green | 4 | 0 | 21.4 |
| green | 4 | 1 | 10.8 |
| green | 4 | 2 | 6.1 |
| green | 4 | 3 | 3.7 |
| green | 4 | 4 | 4.6 |
| green | 4 | 5 | 8.9 |
| green | 4 | 6 | 31.8 |
| green | 4 | 7 | 75.7 |
| green | 4 | 8 | 95.5 |
| green | 4 | 9 | 98.1 |
| green | 4 | 10 | 91.4 |
| green | 4 | 11 | 87.6 |
| green | 4 | 12 | 91 |
| green | 4 | 13 | 92.6 |
| green | 4 | 14 | 104.3 |
| green | 4 | 15 | 116.4 |
| green | 4 | 16 | 128.7 |
| green | 4 | 17 | 146.2 |
| green | 4 | 18 | 134.8 |
| green | 4 | 19 | 101.3 |
| green | 4 | 20 | 75.3 |
| green | 4 | 21 | 64.1 |
| green | 4 | 22 | 55.4 |
| green | 4 | 23 | 40.7 |
| green | 5 | 0 | 23.2 |
| green | 5 | 1 | 14.4 |
| green | 5 | 2 | 7.8 |
| green | 5 | 3 | 4.7 |
| green | 5 | 4 | 4.9 |
| green | 5 | 5 | 9.7 |
| green | 5 | 6 | 28.5 |
| green | 5 | 7 | 66.3 |
| green | 5 | 8 | 80.3 |
| green | 5 | 9 | 80.3 |
| green | 5 | 10 | 80.7 |
| green | 5 | 11 | 77.7 |
| green | 5 | 12 | 77.5 |
| green | 5 | 13 | 80.3 |
| green | 5 | 14 | 98.9 |
| green | 5 | 15 | 112.2 |
| green | 5 | 16 | 123 |
| green | 5 | 17 | 131.6 |
| green | 5 | 18 | 125.3 |
| green | 5 | 19 | 97.1 |
| green | 5 | 20 | 72.6 |
| green | 5 | 21 | 66.1 |
| green | 5 | 22 | 60 |
| green | 5 | 23 | 51.6 |
| green | 6 | 0 | 36 |
| green | 6 | 1 | 27.9 |
| green | 6 | 2 | 22.8 |
| green | 6 | 3 | 19.2 |
| green | 6 | 4 | 14.2 |
| green | 6 | 5 | 8.5 |
| green | 6 | 6 | 11.4 |
| green | 6 | 7 | 22.2 |
| green | 6 | 8 | 30.9 |
| green | 6 | 9 | 46.5 |
| green | 6 | 10 | 58.7 |
| green | 6 | 11 | 69.3 |
| green | 6 | 12 | 78 |
| green | 6 | 13 | 79 |
| green | 6 | 14 | 84 |
| green | 6 | 15 | 89.5 |
| green | 6 | 16 | 91.7 |
| green | 6 | 17 | 90.4 |
| green | 6 | 18 | 92.4 |
| green | 6 | 19 | 81.4 |
| green | 6 | 20 | 68 |
| green | 6 | 21 | 63.6 |
| green | 6 | 22 | 57.7 |
| green | 6 | 23 | 53.9 |
| green | 7 | 0 | 39 |
| green | 7 | 1 | 31.1 |
| green | 7 | 2 | 26 |
| green | 7 | 3 | 21.8 |
| green | 7 | 4 | 16.6 |
| green | 7 | 5 | 10.1 |
| green | 7 | 6 | 12.3 |
| green | 7 | 7 | 20.7 |
| green | 7 | 8 | 27.8 |
| green | 7 | 9 | 42.1 |
| green | 7 | 10 | 50.2 |
| green | 7 | 11 | 59.9 |
| green | 7 | 12 | 72.6 |
| green | 7 | 13 | 73.9 |
| green | 7 | 14 | 83.7 |
| green | 7 | 15 | 86 |
| green | 7 | 16 | 89.1 |
| green | 7 | 17 | 85.8 |
| green | 7 | 18 | 88.8 |
| green | 7 | 19 | 74 |
| green | 7 | 20 | 64.1 |
| green | 7 | 21 | 54.5 |
| green | 7 | 22 | 41.9 |
| green | 7 | 23 | 29.9 |
| yellow | 1 | 0 | 1,807.6 |
| yellow | 1 | 1 | 918.4 |
| yellow | 1 | 2 | 521.5 |
| yellow | 1 | 3 | 389.8 |
| yellow | 1 | 4 | 508.6 |
| yellow | 1 | 5 | 912.4 |
| yellow | 1 | 6 | 1,979.6 |
| yellow | 1 | 7 | 3,675.1 |
| yellow | 1 | 8 | 4,850.7 |
| yellow | 1 | 9 | 4,787.8 |
| yellow | 1 | 10 | 4,704.6 |
| yellow | 1 | 11 | 4,911.4 |
| yellow | 1 | 12 | 5,291.4 |
| yellow | 1 | 13 | 5,497 |
| yellow | 1 | 14 | 6,031.9 |
| yellow | 1 | 15 | 6,297.4 |
| yellow | 1 | 16 | 5,974 |
| yellow | 1 | 17 | 6,593.3 |
| yellow | 1 | 18 | 6,637.7 |
| yellow | 1 | 19 | 5,656.6 |
| yellow | 1 | 20 | 5,637.8 |
| yellow | 1 | 21 | 5,575.4 |
| yellow | 1 | 22 | 4,427.3 |
| yellow | 1 | 23 | 2,827.7 |
| yellow | 2 | 0 | 1,590.2 |
| yellow | 2 | 1 | 716.5 |
| yellow | 2 | 2 | 362.4 |
| yellow | 2 | 3 | 238.9 |
| yellow | 2 | 4 | 334.7 |
| yellow | 2 | 5 | 798.7 |
| yellow | 2 | 6 | 1,993 |
| yellow | 2 | 7 | 4,104.2 |
| yellow | 2 | 8 | 5,611.2 |
| yellow | 2 | 9 | 5,597 |
| yellow | 2 | 10 | 5,347.7 |
| yellow | 2 | 11 | 5,502.9 |
| yellow | 2 | 12 | 5,846.5 |
| yellow | 2 | 13 | 6,005.4 |
| yellow | 2 | 14 | 6,588.8 |
| yellow | 2 | 15 | 6,865.1 |
| yellow | 2 | 16 | 6,607.1 |
| yellow | 2 | 17 | 7,535.8 |
| yellow | 2 | 18 | 7,928.7 |
| yellow | 2 | 19 | 6,843.1 |
| yellow | 2 | 20 | 7,153.4 |
| yellow | 2 | 21 | 7,681.5 |
| yellow | 2 | 22 | 6,284.4 |
| yellow | 2 | 23 | 3,779.5 |
| yellow | 3 | 0 | 1,930.3 |
| yellow | 3 | 1 | 901.5 |
| yellow | 3 | 2 | 484.2 |
| yellow | 3 | 3 | 325 |
| yellow | 3 | 4 | 397 |
| yellow | 3 | 5 | 828.1 |
| yellow | 3 | 6 | 2,060.4 |
| yellow | 3 | 7 | 4,263.6 |
| yellow | 3 | 8 | 5,818.9 |
| yellow | 3 | 9 | 5,739.4 |
| yellow | 3 | 10 | 5,473.4 |
| yellow | 3 | 11 | 5,707.3 |
| yellow | 3 | 12 | 6,076.4 |
| yellow | 3 | 13 | 6,281.8 |
| yellow | 3 | 14 | 6,784.6 |
| yellow | 3 | 15 | 7,079.4 |
| yellow | 3 | 16 | 6,878 |
| yellow | 3 | 17 | 7,853.3 |
| yellow | 3 | 18 | 8,281.7 |
| yellow | 3 | 19 | 7,423 |
| yellow | 3 | 20 | 7,599.4 |
| yellow | 3 | 21 | 8,107.4 |
| yellow | 3 | 22 | 7,069.3 |
| yellow | 3 | 23 | 4,513 |
| yellow | 4 | 0 | 2,456 |
| yellow | 4 | 1 | 1,225 |
| yellow | 4 | 2 | 667.4 |
| yellow | 4 | 3 | 458.4 |
| yellow | 4 | 4 | 498.8 |
| yellow | 4 | 5 | 947.4 |
| yellow | 4 | 6 | 2,181.8 |
| yellow | 4 | 7 | 4,281.3 |
| yellow | 4 | 8 | 5,773.3 |
| yellow | 4 | 9 | 5,708.2 |
| yellow | 4 | 10 | 5,523.4 |
| yellow | 4 | 11 | 5,744.3 |
| yellow | 4 | 12 | 6,124.2 |
| yellow | 4 | 13 | 6,378.2 |
| yellow | 4 | 14 | 6,998 |
| yellow | 4 | 15 | 7,380 |
| yellow | 4 | 16 | 7,068.9 |
| yellow | 4 | 17 | 8,040.9 |
| yellow | 4 | 18 | 8,536.9 |
| yellow | 4 | 19 | 7,652.3 |
| yellow | 4 | 20 | 7,792.3 |
| yellow | 4 | 21 | 8,262.5 |
| yellow | 4 | 22 | 7,786.5 |
| yellow | 4 | 23 | 5,816.9 |
| yellow | 5 | 0 | 3,608.2 |
| yellow | 5 | 1 | 1,940.5 |
| yellow | 5 | 2 | 1,122.3 |
| yellow | 5 | 3 | 723 |
| yellow | 5 | 4 | 687.6 |
| yellow | 5 | 5 | 996.6 |
| yellow | 5 | 6 | 1,977.6 |
| yellow | 5 | 7 | 3,595.9 |
| yellow | 5 | 8 | 4,613.4 |
| yellow | 5 | 9 | 4,752.8 |
| yellow | 5 | 10 | 4,998.4 |
| yellow | 5 | 11 | 5,357 |
| yellow | 5 | 12 | 5,849.1 |
| yellow | 5 | 13 | 6,124.2 |
| yellow | 5 | 14 | 6,904.6 |
| yellow | 5 | 15 | 7,227.5 |
| yellow | 5 | 16 | 6,704.1 |
| yellow | 5 | 17 | 7,326.8 |
| yellow | 5 | 18 | 7,830.5 |
| yellow | 5 | 19 | 7,313.2 |
| yellow | 5 | 20 | 6,686 |
| yellow | 5 | 21 | 6,724.5 |
| yellow | 5 | 22 | 7,250.3 |
| yellow | 5 | 23 | 7,129.1 |
| yellow | 6 | 0 | 6,295.5 |
| yellow | 6 | 1 | 4,916.7 |
| yellow | 6 | 2 | 3,543.3 |
| yellow | 6 | 3 | 2,322.2 |
| yellow | 6 | 4 | 1,395.6 |
| yellow | 6 | 5 | 713.5 |
| yellow | 6 | 6 | 1,062.2 |
| yellow | 6 | 7 | 1,516.5 |
| yellow | 6 | 8 | 2,378.4 |
| yellow | 6 | 9 | 3,598.3 |
| yellow | 6 | 10 | 4,612.4 |
| yellow | 6 | 11 | 5,441.4 |
| yellow | 6 | 12 | 6,113.8 |
| yellow | 6 | 13 | 6,506.6 |
| yellow | 6 | 14 | 6,542.3 |
| yellow | 6 | 15 | 6,852.6 |
| yellow | 6 | 16 | 7,304.1 |
| yellow | 6 | 17 | 7,672.1 |
| yellow | 6 | 18 | 8,101.8 |
| yellow | 6 | 19 | 7,922.8 |
| yellow | 6 | 20 | 6,753.9 |
| yellow | 6 | 21 | 6,732.9 |
| yellow | 6 | 22 | 7,555.4 |
| yellow | 6 | 23 | 7,723.6 |
| yellow | 7 | 0 | 6,753.8 |
| yellow | 7 | 1 | 5,387.5 |
| yellow | 7 | 2 | 3,873.7 |
| yellow | 7 | 3 | 2,680 |
| yellow | 7 | 4 | 1,736.1 |
| yellow | 7 | 5 | 865.7 |
| yellow | 7 | 6 | 1,113.8 |
| yellow | 7 | 7 | 1,477.9 |
| yellow | 7 | 8 | 2,131.7 |
| yellow | 7 | 9 | 3,322.4 |
| yellow | 7 | 10 | 4,463.7 |
| yellow | 7 | 11 | 5,243.1 |
| yellow | 7 | 12 | 5,923.6 |
| yellow | 7 | 13 | 6,246 |
| yellow | 7 | 14 | 6,445.1 |
| yellow | 7 | 15 | 6,202.6 |
| yellow | 7 | 16 | 6,305.1 |
| yellow | 7 | 17 | 6,392.4 |
| yellow | 7 | 18 | 6,266.6 |
| yellow | 7 | 19 | 5,431.7 |
| yellow | 7 | 20 | 4,949.6 |
| yellow | 7 | 21 | 4,727 |
| yellow | 7 | 22 | 4,026.2 |
| yellow | 7 | 23 | 2,952.3 |

## q4_03_perfil_horario

**Pregunta:** P2 (temporal) - Cual es la hora pico y la hora valle de cada tipo de taxi, entre semana y fin de semana?

**Objetivo:** Resumir la matriz horaria en hora pico/valle y su participacion.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (4 filas, 1.83 s):

| taxi_type | tipo_dia | hora_pico | pct_hora_pico | hora_valle | pct_hora_valle |
|---|---|---|---|---|---|
| green | entre semana | 17 | 8.41 | 3 | 0.24 |
| green | fin de semana | 18 | 7.26 | 5 | 0.74 |
| yellow | entre semana | 18 | 6.92 | 3 | 0.38 |
| yellow | fin de semana | 18 | 6.29 | 5 | 0.69 |

## q4_04_caracteristicas_viaje

**Pregunta:** P3 (caracteristicas) - Como son los viajes tipicos (distancia, duracion, pasajeros, velocidad)?

**Objetivo:** Percentiles de distancia, duracion, velocidad y tarifa por tipo de taxi.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (2 filas, 18.69 s):

| taxi_type | viajes | distancia_p50_mi | distancia_prom_mi | distancia_p95_mi | duracion_p50_min | duracion_prom_min | duracion_p95_min | velocidad_prom_mph | pasajeros_prom | tarifa_p50 | total_prom |
|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 110,568,996 | 1.88 | 3.5 | 13.5 | 13.6 | 17.3 | 44.1 | 11 | 1.31 | 14.61 | 29.1 |
| green | 1,458,348 | 2.06 | 3.14 | 9.51 | 12.6 | 15.7 | 37.9 | 11.6 | 1.32 | 13.5 | 24.74 |

## q4_05_velocidad_por_hora

**Pregunta:** P4 (caracteristicas/temporal) - Como cambia la velocidad del trafico a lo largo del dia?

**Objetivo:** Velocidad mediana (mph) y duracion mediana por hora del dia, entre semana.

**Fuente:** `vista trips_clean`

```sql
SELECT hour(pickup_datetime) AS hora,
       round(median(trip_distance / (duration_min / 60)), 2) AS velocidad_mediana_mph,
       round(median(duration_min), 1) AS duracion_mediana_min,
       round(median(trip_distance), 2) AS distancia_mediana_mi
FROM trips_clean
WHERE isodow(pickup_datetime) <= 5
GROUP BY hora
ORDER BY hora;
```

**Resultado** (24 filas, 3.57 s):

| hora | velocidad_mediana_mph | duracion_mediana_min | distancia_mediana_mi |
|---|---|---|---|
| 0 | 13.57 | 12.8 | 2.77 |
| 1 | 14.39 | 12 | 2.74 |
| 2 | 14.7 | 11.5 | 2.7 |
| 3 | 15.39 | 12 | 2.96 |
| 4 | 17.11 | 14.1 | 4 |
| 5 | 16.04 | 12.8 | 3.39 |
| 6 | 13.49 | 11.7 | 2.51 |
| 7 | 10.71 | 12.2 | 2.04 |
| 8 | 8.85 | 13.6 | 1.82 |
| 9 | 8.25 | 14.1 | 1.72 |
| 10 | 7.88 | 14.7 | 1.7 |
| 11 | 7.5 | 15.2 | 1.64 |
| 12 | 7.58 | 15 | 1.63 |
| 13 | 7.77 | 15 | 1.67 |
| 14 | 7.73 | 15.2 | 1.7 |
| 15 | 7.63 | 15.1 | 1.68 |
| 16 | 7.94 | 14.5 | 1.68 |
| 17 | 8 | 14 | 1.64 |
| 18 | 8.38 | 13 | 1.61 |
| 19 | 9.13 | 12.6 | 1.7 |
| 20 | 9.91 | 12.8 | 1.94 |
| 21 | 10.3 | 13 | 2.06 |
| 22 | 10.73 | 13.2 | 2.2 |
| 23 | 11.53 | 13.2 | 2.37 |

## q4_06_pasajeros

**Pregunta:** P3 (caracteristicas) - Cuantos pasajeros viajan normalmente?

**Objetivo:** Distribucion de passenger_count por tipo de taxi (incluye desconocidos).

**Fuente:** `vista trips`

```sql
SELECT taxi_type, coalesce(passenger_count::VARCHAR, 'desconocido') AS pasajeros, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips
GROUP BY 1, 2
ORDER BY taxi_type DESC, viajes DESC;
```

**Resultado** (22 filas, 0.50 s):

| taxi_type | pasajeros | viajes | pct |
|---|---|---|---|
| yellow | 1 | 76,115,322 | 63.64 |
| yellow | desconocido | 23,419,814 | 19.58 |
| yellow | 2 | 13,244,472 | 11.07 |
| yellow | 3 | 3,101,320 | 2.59 |
| yellow | 4 | 2,061,478 | 1.72 |
| yellow | 0 | 752,775 | 0.63 |
| yellow | 5 | 550,453 | 0.46 |
| yellow | 6 | 349,585 | 0.29 |
| yellow | 8 | 297 | 0 |
| yellow | 7 | 85 | 0 |
| yellow | 9 | 76 | 0 |
| green | 1 | 1,216,943 | 76.6 |
| green | 2 | 144,782 | 9.11 |
| green | desconocido | 122,983 | 7.74 |
| green | 5 | 33,821 | 2.13 |
| green | 6 | 23,970 | 1.51 |
| green | 0 | 19,575 | 1.23 |
| green | 3 | 16,641 | 1.05 |
| green | 4 | 9,523 | 0.6 |
| green | 8 | 174 | 0.01 |
| green | 7 | 158 | 0.01 |
| green | 9 | 137 | 0.01 |

## q4_07_borough_origen

**Pregunta:** P5 (yellow vs green) - En que boroughs se originan los viajes de cada tipo de taxi?

**Objetivo:** Participacion de cada borough de origen por tipo, uniendo con la tabla de zonas.

**Fuente:** `vistas trips_clean + zones (data/raw/reference/taxi_zone_lookup.csv)`

```sql
SELECT t.taxi_type, z.borough, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct
FROM trips_clean t
JOIN zones z ON z.location_id = t.pu_location_id
GROUP BY 1, 2
ORDER BY t.taxi_type DESC, viajes DESC;
```

**Resultado** (15 filas, 1.96 s):

| taxi_type | borough | viajes | pct |
|---|---|---|---|
| yellow | Manhattan | 96,543,562 | 87.32 |
| yellow | Queens | 10,128,441 | 9.16 |
| yellow | Brooklyn | 3,000,411 | 2.71 |
| yellow | Bronx | 663,784 | 0.6 |
| yellow | Unknown | 208,728 | 0.19 |
| yellow | N/A | 15,738 | 0.01 |
| yellow | Staten Island | 7,474 | 0.01 |
| yellow | EWR | 858 | 0 |
| green | Manhattan | 896,100 | 61.45 |
| green | Queens | 338,022 | 23.18 |
| green | Brooklyn | 201,018 | 13.78 |
| green | Bronx | 21,751 | 1.49 |
| green | Unknown | 783 | 0.05 |
| green | N/A | 578 | 0.04 |
| green | Staten Island | 96 | 0.01 |

## q4_08_top_zonas

**Pregunta:** P5 (yellow vs green) - Cuales son las zonas de origen mas frecuentes de cada tipo?

**Objetivo:** Top 8 zonas de pickup por tipo de taxi.

**Fuente:** `vistas trips_clean + zones`

```sql
SELECT * FROM (
    SELECT t.taxi_type, z.borough, z.zone, count(*) AS viajes,
           round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY t.taxi_type), 2) AS pct,
           row_number() OVER (PARTITION BY t.taxi_type ORDER BY count(*) DESC) AS ranking
    FROM trips_clean t JOIN zones z ON z.location_id = t.pu_location_id
    GROUP BY 1, 2, 3
)
WHERE ranking <= 8
ORDER BY taxi_type DESC, ranking;
```

**Resultado** (16 filas, 2.24 s):

| taxi_type | borough | zone | viajes | pct | ranking |
|---|---|---|---|---|---|
| yellow | Manhattan | Upper East Side South | 5,062,542 | 4.58 | 1 |
| yellow | Manhattan | Midtown Center | 4,919,496 | 4.45 | 2 |
| yellow | Queens | JFK Airport | 4,796,263 | 4.34 | 3 |
| yellow | Manhattan | Upper East Side North | 4,493,959 | 4.06 | 4 |
| yellow | Manhattan | Midtown East | 3,615,044 | 3.27 | 5 |
| yellow | Manhattan | Penn Station/Madison Sq West | 3,592,449 | 3.25 | 6 |
| yellow | Manhattan | Times Sq/Theatre District | 3,502,587 | 3.17 | 7 |
| yellow | Manhattan | Lincoln Square East | 3,337,115 | 3.02 | 8 |
| green | Manhattan | East Harlem North | 370,156 | 25.38 | 1 |
| green | Manhattan | East Harlem South | 209,311 | 14.35 | 2 |
| green | Queens | Forest Hills | 71,881 | 4.93 | 3 |
| green | Manhattan | Central Park | 71,800 | 4.92 | 4 |
| green | Manhattan | Morningside Heights | 70,402 | 4.83 | 5 |
| green | Manhattan | Central Harlem | 60,473 | 4.15 | 6 |
| green | Queens | Elmhurst | 59,776 | 4.1 | 7 |
| green | Brooklyn | Fort Greene | 45,850 | 3.14 | 8 |

## q4_09_yellow_vs_green

**Pregunta:** P6 (yellow vs green) - En que se diferencian economicamente los viajes amarillos y verdes?

**Objetivo:** Comparar tarifa, costo por milla, propina, peajes y recargos por tipo.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (2 filas, 6.11 s):

| taxi_type | tarifa_prom | tarifa_por_milla_mediana | propina_prom | peajes_prom | congestion_prom | cbd_fee_prom | airport_fee_prom | total_prom | pct_tarifa_negociada | pct_despacho |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 20.23 | 7.32 | 3.13 | 0.56 | 1.9 | 0.35 | 0.13 | 29.1 | 0.42 | 0 |
| green | 17.72 | 6.75 | 2.68 | 0.25 | 0.83 | 0.04 | 0 | 24.74 | 3.02 | 2.73 |

## q4_10_tipo_pago

**Pregunta:** P7 (pago) - Como se distribuyen los metodos de pago y como cambian mes a mes?

**Objetivo:** Participacion mensual de cada metodo de pago por tipo de taxi.

**Fuente:** `vista trips`

```sql
SELECT taxi_type, file_year AS anio, file_month AS mes,
       CASE payment_type WHEN 1 THEN 'tarjeta' WHEN 2 THEN 'efectivo' WHEN 3 THEN 'sin cargo'
                         WHEN 4 THEN 'disputa' ELSE 'desconocido/flex' END AS metodo_pago,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, file_year, file_month), 2) AS pct
FROM trips
GROUP BY 1, 2, 3, 4
ORDER BY taxi_type DESC, anio, mes, viajes DESC;
```

**Resultado** (320 filas, 0.34 s):

| taxi_type | anio | mes | metodo_pago | viajes | pct |
|---|---|---|---|---|---|
| yellow | 2024 | 1 | tarjeta | 2,319,046 | 78.22 |
| yellow | 2024 | 1 | efectivo | 439,191 | 14.81 |
| yellow | 2024 | 1 | desconocido/flex | 140,162 | 4.73 |
| yellow | 2024 | 1 | disputa | 46,628 | 1.57 |
| yellow | 2024 | 1 | sin cargo | 19,597 | 0.66 |
| yellow | 2024 | 2 | tarjeta | 2,342,010 | 77.87 |
| yellow | 2024 | 2 | efectivo | 413,254 | 13.74 |
| yellow | 2024 | 2 | desconocido/flex | 185,610 | 6.17 |
| yellow | 2024 | 2 | disputa | 47,741 | 1.59 |
| yellow | 2024 | 2 | sin cargo | 18,911 | 0.63 |
| yellow | 2024 | 3 | tarjeta | 2,597,102 | 72.49 |
| yellow | 2024 | 3 | efectivo | 477,660 | 13.33 |
| yellow | 2024 | 3 | desconocido/flex | 426,190 | 11.9 |
| yellow | 2024 | 3 | disputa | 58,218 | 1.63 |
| yellow | 2024 | 3 | sin cargo | 23,458 | 0.65 |
| yellow | 2024 | 4 | tarjeta | 2,555,569 | 72.72 |
| yellow | 2024 | 4 | efectivo | 470,436 | 13.39 |
| yellow | 2024 | 4 | desconocido/flex | 408,578 | 11.63 |
| yellow | 2024 | 4 | disputa | 57,096 | 1.62 |
| yellow | 2024 | 4 | sin cargo | 22,610 | 0.64 |
| yellow | 2024 | 5 | tarjeta | 2,727,878 | 73.25 |
| yellow | 2024 | 5 | efectivo | 502,495 | 13.49 |
| yellow | 2024 | 5 | desconocido/flex | 404,666 | 10.87 |
| yellow | 2024 | 5 | disputa | 64,300 | 1.73 |
| yellow | 2024 | 5 | sin cargo | 24,494 | 0.66 |
| yellow | 2024 | 6 | tarjeta | 2,570,324 | 72.62 |
| yellow | 2024 | 6 | efectivo | 470,031 | 13.28 |
| yellow | 2024 | 6 | desconocido/flex | 410,781 | 11.61 |
| yellow | 2024 | 6 | disputa | 63,775 | 1.8 |
| yellow | 2024 | 6 | sin cargo | 24,282 | 0.69 |
| yellow | 2024 | 7 | tarjeta | 2,252,669 | 73.21 |
| yellow | 2024 | 7 | efectivo | 454,577 | 14.77 |
| yellow | 2024 | 7 | desconocido/flex | 278,991 | 9.07 |
| yellow | 2024 | 7 | disputa | 65,938 | 2.14 |
| yellow | 2024 | 7 | sin cargo | 24,728 | 0.8 |
| yellow | 2024 | 8 | tarjeta | 2,176,509 | 73.06 |
| yellow | 2024 | 8 | efectivo | 449,387 | 15.08 |
| yellow | 2024 | 8 | desconocido/flex | 258,667 | 8.68 |
| yellow | 2024 | 8 | disputa | 69,623 | 2.34 |
| yellow | 2024 | 8 | sin cargo | 24,997 | 0.84 |
| yellow | 2024 | 9 | tarjeta | 2,604,671 | 71.69 |
| yellow | 2024 | 9 | desconocido/flex | 483,731 | 13.31 |
| yellow | 2024 | 9 | efectivo | 445,230 | 12.26 |
| yellow | 2024 | 9 | disputa | 74,061 | 2.04 |
| yellow | 2024 | 9 | sin cargo | 25,337 | 0.7 |
| yellow | 2024 | 10 | tarjeta | 2,854,092 | 74.45 |
| yellow | 2024 | 10 | efectivo | 477,350 | 12.45 |
| yellow | 2024 | 10 | desconocido/flex | 393,895 | 10.27 |
| yellow | 2024 | 10 | disputa | 80,888 | 2.11 |
| yellow | 2024 | 10 | sin cargo | 27,546 | 0.72 |
| yellow | 2024 | 11 | tarjeta | 2,718,920 | 74.57 |
| yellow | 2024 | 11 | efectivo | 449,826 | 12.34 |
| yellow | 2024 | 11 | desconocido/flex | 373,674 | 10.25 |
| yellow | 2024 | 11 | disputa | 77,104 | 2.11 |
| yellow | 2024 | 11 | sin cargo | 26,845 | 0.74 |
| yellow | 2024 | 12 | tarjeta | 2,733,369 | 74.51 |
| yellow | 2024 | 12 | efectivo | 490,651 | 13.38 |
| yellow | 2024 | 12 | desconocido/flex | 326,291 | 8.89 |
| yellow | 2024 | 12 | disputa | 89,122 | 2.43 |
| yellow | 2024 | 12 | sin cargo | 28,938 | 0.79 |
| yellow | 2025 | 1 | tarjeta | 2,444,393 | 70.34 |
| yellow | 2025 | 1 | desconocido/flex | 540,150 | 15.54 |
| yellow | 2025 | 1 | efectivo | 390,429 | 11.23 |
| yellow | 2025 | 1 | disputa | 76,481 | 2.2 |
| yellow | 2025 | 1 | sin cargo | 23,773 | 0.68 |
| yellow | 2025 | 2 | tarjeta | 2,336,175 | 65.3 |
| yellow | 2025 | 2 | desconocido/flex | 806,937 | 22.56 |
| yellow | 2025 | 2 | efectivo | 339,481 | 9.49 |
| yellow | 2025 | 2 | disputa | 73,101 | 2.04 |
| yellow | 2025 | 2 | sin cargo | 21,849 | 0.61 |
| yellow | 2025 | 3 | tarjeta | 2,704,166 | 65.24 |
| yellow | 2025 | 3 | desconocido/flex | 916,663 | 22.11 |
| yellow | 2025 | 3 | efectivo | 405,847 | 9.79 |
| yellow | 2025 | 3 | disputa | 91,657 | 2.21 |
| yellow | 2025 | 3 | sin cargo | 26,924 | 0.65 |
| yellow | 2025 | 4 | tarjeta | 2,686,812 | 67.67 |
| yellow | 2025 | 4 | desconocido/flex | 745,730 | 18.78 |
| yellow | 2025 | 4 | efectivo | 412,754 | 10.4 |
| yellow | 2025 | 4 | disputa | 97,491 | 2.46 |
| yellow | 2025 | 4 | sin cargo | 27,766 | 0.7 |
| yellow | 2025 | 5 | tarjeta | 2,842,165 | 61.9 |
| yellow | 2025 | 5 | desconocido/flex | 1,196,176 | 26.05 |
| yellow | 2025 | 5 | efectivo | 418,529 | 9.11 |
| yellow | 2025 | 5 | disputa | 105,323 | 2.29 |
| yellow | 2025 | 5 | sin cargo | 29,652 | 0.65 |
| yellow | 2025 | 6 | tarjeta | 2,595,374 | 60.04 |
| yellow | 2025 | 6 | desconocido/flex | 1,212,948 | 28.06 |
| yellow | 2025 | 6 | efectivo | 386,552 | 8.94 |
| yellow | 2025 | 6 | disputa | 100,163 | 2.32 |
| yellow | 2025 | 6 | sin cargo | 27,923 | 0.65 |
| yellow | 2025 | 7 | tarjeta | 2,343,668 | 60.11 |
| yellow | 2025 | 7 | desconocido/flex | 1,038,755 | 26.64 |
| yellow | 2025 | 7 | efectivo | 383,976 | 9.85 |
| yellow | 2025 | 7 | disputa | 105,080 | 2.7 |
| yellow | 2025 | 7 | sin cargo | 27,484 | 0.7 |
| yellow | 2025 | 8 | tarjeta | 2,182,738 | 61.07 |
| yellow | 2025 | 8 | desconocido/flex | 886,234 | 24.8 |
| yellow | 2025 | 8 | efectivo | 370,677 | 10.37 |
| yellow | 2025 | 8 | disputa | 106,641 | 2.98 |
| yellow | 2025 | 8 | sin cargo | 27,801 | 0.78 |
| yellow | 2025 | 9 | tarjeta | 2,676,305 | 62.96 |
| yellow | 2025 | 9 | desconocido/flex | 1,067,195 | 25.1 |
| yellow | 2025 | 9 | efectivo | 372,069 | 8.75 |
| yellow | 2025 | 9 | disputa | 107,514 | 2.53 |
| yellow | 2025 | 9 | sin cargo | 27,932 | 0.66 |
| yellow | 2025 | 10 | tarjeta | 2,918,737 | 65.91 |
| yellow | 2025 | 10 | desconocido/flex | 990,887 | 22.37 |
| yellow | 2025 | 10 | efectivo | 399,080 | 9.01 |
| yellow | 2025 | 10 | disputa | 93,891 | 2.12 |
| yellow | 2025 | 10 | sin cargo | 26,104 | 0.59 |
| yellow | 2025 | 11 | tarjeta | 2,704,695 | 64.68 |
| yellow | 2025 | 11 | desconocido/flex | 1,014,740 | 24.27 |
| yellow | 2025 | 11 | efectivo | 373,932 | 8.94 |
| yellow | 2025 | 11 | disputa | 67,726 | 1.62 |
| yellow | 2025 | 11 | sin cargo | 20,351 | 0.49 |
| yellow | 2025 | 12 | tarjeta | 2,618,772 | 60.83 |
| yellow | 2025 | 12 | desconocido/flex | 1,195,482 | 27.77 |
| yellow | 2025 | 12 | efectivo | 401,019 | 9.32 |
| yellow | 2025 | 12 | disputa | 69,145 | 1.61 |
| yellow | 2025 | 12 | sin cargo | 20,588 | 0.48 |
| yellow | 2026 | 1 | tarjeta | 2,249,747 | 60.4 |
| yellow | 2026 | 1 | desconocido/flex | 1,088,058 | 29.21 |
| yellow | 2026 | 1 | efectivo | 314,043 | 8.43 |
| yellow | 2026 | 1 | disputa | 56,400 | 1.51 |
| yellow | 2026 | 1 | sin cargo | 16,641 | 0.45 |
| yellow | 2026 | 2 | tarjeta | 2,051,661 | 60.35 |
| yellow | 2026 | 2 | desconocido/flex | 1,023,317 | 30.1 |
| yellow | 2026 | 2 | efectivo | 273,616 | 8.05 |
| yellow | 2026 | 2 | disputa | 38,888 | 1.14 |
| yellow | 2026 | 2 | sin cargo | 12,384 | 0.36 |
| yellow | 2026 | 3 | tarjeta | 2,608,830 | 66.01 |
| yellow | 2026 | 3 | desconocido/flex | 945,748 | 23.93 |
| yellow | 2026 | 3 | efectivo | 353,541 | 8.94 |
| yellow | 2026 | 3 | disputa | 31,490 | 0.8 |
| yellow | 2026 | 3 | sin cargo | 12,842 | 0.32 |
| yellow | 2026 | 4 | tarjeta | 2,635,749 | 68.8 |
| yellow | 2026 | 4 | desconocido/flex | 799,786 | 20.88 |
| yellow | 2026 | 4 | efectivo | 360,995 | 9.42 |
| yellow | 2026 | 4 | disputa | 22,918 | 0.6 |
| yellow | 2026 | 4 | sin cargo | 11,792 | 0.31 |
| yellow | 2026 | 5 | tarjeta | 2,727,585 | 66.68 |
| yellow | 2026 | 5 | desconocido/flex | 955,371 | 23.35 |
| yellow | 2026 | 5 | efectivo | 372,909 | 9.12 |
| yellow | 2026 | 5 | disputa | 22,987 | 0.56 |
| yellow | 2026 | 5 | sin cargo | 11,984 | 0.29 |
| yellow | 2026 | 6 | tarjeta | 2,432,871 | 63.4 |
| yellow | 2026 | 6 | desconocido/flex | 1,013,502 | 26.41 |
| yellow | 2026 | 6 | efectivo | 357,804 | 9.32 |
| yellow | 2026 | 6 | disputa | 21,866 | 0.57 |
| yellow | 2026 | 6 | sin cargo | 11,205 | 0.29 |
| yellow | 2026 | 7 | tarjeta | 2,182,461 | 61.82 |
| yellow | 2026 | 7 | desconocido/flex | 969,727 | 27.47 |
| yellow | 2026 | 7 | efectivo | 345,646 | 9.79 |
| yellow | 2026 | 7 | disputa | 21,382 | 0.61 |
| yellow | 2026 | 7 | sin cargo | 10,893 | 0.31 |
| yellow | 2026 | 8 | tarjeta | 2,052,104 | 61.5 |
| yellow | 2026 | 8 | desconocido/flex | 921,181 | 27.61 |
| yellow | 2026 | 8 | efectivo | 329,477 | 9.87 |
| yellow | 2026 | 8 | disputa | 23,557 | 0.71 |
| yellow | 2026 | 8 | sin cargo | 10,397 | 0.31 |
| green | 2024 | 1 | tarjeta | 36,660 | 64.83 |
| green | 2024 | 1 | efectivo | 15,913 | 28.14 |
| green | 2024 | 1 | desconocido/flex | 3,416 | 6.04 |
| green | 2024 | 1 | sin cargo | 434 | 0.77 |
| green | 2024 | 1 | disputa | 128 | 0.23 |
| green | 2024 | 2 | tarjeta | 35,404 | 66.08 |
| green | 2024 | 2 | efectivo | 14,757 | 27.54 |
| green | 2024 | 2 | desconocido/flex | 2,929 | 5.47 |
| green | 2024 | 2 | sin cargo | 347 | 0.65 |
| green | 2024 | 2 | disputa | 140 | 0.26 |
| green | 2024 | 3 | tarjeta | 38,249 | 66.57 |
| green | 2024 | 3 | efectivo | 16,608 | 28.91 |
| green | 2024 | 3 | desconocido/flex | 2,101 | 3.66 |
| green | 2024 | 3 | sin cargo | 347 | 0.6 |
| green | 2024 | 3 | disputa | 152 | 0.26 |
| green | 2024 | 4 | tarjeta | 38,998 | 69.06 |
| green | 2024 | 4 | efectivo | 14,935 | 26.45 |
| green | 2024 | 4 | desconocido/flex | 1,988 | 3.52 |
| green | 2024 | 4 | sin cargo | 422 | 0.75 |
| green | 2024 | 4 | disputa | 128 | 0.23 |
| green | 2024 | 5 | tarjeta | 42,353 | 69.43 |
| green | 2024 | 5 | efectivo | 16,159 | 26.49 |
| green | 2024 | 5 | desconocido/flex | 1,894 | 3.1 |
| green | 2024 | 5 | sin cargo | 451 | 0.74 |
| green | 2024 | 5 | disputa | 146 | 0.24 |
| green | 2024 | 6 | tarjeta | 37,830 | 69.1 |
| green | 2024 | 6 | efectivo | 14,498 | 26.48 |
| green | 2024 | 6 | desconocido/flex | 1,903 | 3.48 |
| green | 2024 | 6 | sin cargo | 396 | 0.72 |
| green | 2024 | 6 | disputa | 121 | 0.22 |
| green | 2024 | 7 | tarjeta | 35,891 | 69.24 |
| green | 2024 | 7 | efectivo | 13,828 | 26.68 |
| green | 2024 | 7 | desconocido/flex | 1,615 | 3.12 |
| green | 2024 | 7 | sin cargo | 392 | 0.76 |
| green | 2024 | 7 | disputa | 111 | 0.21 |
| green | 2024 | 8 | tarjeta | 35,819 | 69.19 |
| green | 2024 | 8 | efectivo | 13,804 | 26.66 |
| green | 2024 | 8 | desconocido/flex | 1,587 | 3.07 |
| green | 2024 | 8 | sin cargo | 435 | 0.84 |
| green | 2024 | 8 | disputa | 126 | 0.24 |
| green | 2024 | 9 | tarjeta | 38,389 | 70.52 |
| green | 2024 | 9 | efectivo | 13,843 | 25.43 |
| green | 2024 | 9 | desconocido/flex | 1,708 | 3.14 |
| green | 2024 | 9 | sin cargo | 390 | 0.72 |
| green | 2024 | 9 | disputa | 110 | 0.2 |
| green | 2024 | 10 | tarjeta | 39,817 | 70.92 |
| green | 2024 | 10 | efectivo | 14,217 | 25.32 |
| green | 2024 | 10 | desconocido/flex | 1,647 | 2.93 |
| green | 2024 | 10 | sin cargo | 323 | 0.58 |
| green | 2024 | 10 | disputa | 143 | 0.25 |
| green | 2024 | 11 | tarjeta | 37,293 | 71.41 |
| green | 2024 | 11 | efectivo | 12,916 | 24.73 |
| green | 2024 | 11 | desconocido/flex | 1,588 | 3.04 |
| green | 2024 | 11 | sin cargo | 308 | 0.59 |
| green | 2024 | 11 | disputa | 117 | 0.22 |
| green | 2024 | 12 | tarjeta | 37,984 | 70.35 |
| green | 2024 | 12 | efectivo | 13,535 | 25.07 |
| green | 2024 | 12 | desconocido/flex | 1,981 | 3.67 |
| green | 2024 | 12 | sin cargo | 355 | 0.66 |
| green | 2024 | 12 | disputa | 139 | 0.26 |
| green | 2025 | 1 | tarjeta | 34,635 | 71.67 |
| green | 2025 | 1 | efectivo | 11,424 | 23.64 |
| green | 2025 | 1 | desconocido/flex | 1,837 | 3.8 |
| green | 2025 | 1 | sin cargo | 332 | 0.69 |
| green | 2025 | 1 | disputa | 98 | 0.2 |
| green | 2025 | 2 | tarjeta | 33,074 | 70.94 |
| green | 2025 | 2 | efectivo | 10,573 | 22.68 |
| green | 2025 | 2 | desconocido/flex | 2,517 | 5.4 |
| green | 2025 | 2 | sin cargo | 351 | 0.75 |
| green | 2025 | 2 | disputa | 106 | 0.23 |
| green | 2025 | 3 | tarjeta | 35,445 | 68.77 |
| green | 2025 | 3 | efectivo | 12,064 | 23.41 |
| green | 2025 | 3 | desconocido/flex | 3,551 | 6.89 |
| green | 2025 | 3 | sin cargo | 357 | 0.69 |
| green | 2025 | 3 | disputa | 122 | 0.24 |
| green | 2025 | 4 | tarjeta | 36,873 | 70.73 |
| green | 2025 | 4 | efectivo | 11,665 | 22.38 |
| green | 2025 | 4 | desconocido/flex | 3,188 | 6.12 |
| green | 2025 | 4 | sin cargo | 288 | 0.55 |
| green | 2025 | 4 | disputa | 118 | 0.23 |
| green | 2025 | 5 | tarjeta | 39,553 | 71.4 |
| green | 2025 | 5 | efectivo | 12,088 | 21.82 |
| green | 2025 | 5 | desconocido/flex | 3,249 | 5.86 |
| green | 2025 | 5 | sin cargo | 366 | 0.66 |
| green | 2025 | 5 | disputa | 143 | 0.26 |
| green | 2025 | 6 | tarjeta | 34,026 | 68.89 |
| green | 2025 | 6 | efectivo | 11,126 | 22.53 |
| green | 2025 | 6 | desconocido/flex | 3,790 | 7.67 |
| green | 2025 | 6 | sin cargo | 312 | 0.63 |
| green | 2025 | 6 | disputa | 136 | 0.28 |
| green | 2025 | 7 | tarjeta | 31,921 | 66.22 |
| green | 2025 | 7 | efectivo | 10,699 | 22.19 |
| green | 2025 | 7 | desconocido/flex | 5,187 | 10.76 |
| green | 2025 | 7 | sin cargo | 313 | 0.65 |
| green | 2025 | 7 | disputa | 85 | 0.18 |
| green | 2025 | 8 | tarjeta | 30,701 | 66.3 |
| green | 2025 | 8 | efectivo | 10,457 | 22.58 |
| green | 2025 | 8 | desconocido/flex | 4,746 | 10.25 |
| green | 2025 | 8 | sin cargo | 319 | 0.69 |
| green | 2025 | 8 | disputa | 83 | 0.18 |
| green | 2025 | 9 | tarjeta | 33,045 | 67.59 |
| green | 2025 | 9 | efectivo | 10,113 | 20.68 |
| green | 2025 | 9 | desconocido/flex | 5,408 | 11.06 |
| green | 2025 | 9 | sin cargo | 245 | 0.5 |
| green | 2025 | 9 | disputa | 82 | 0.17 |
| green | 2025 | 10 | tarjeta | 33,953 | 68.71 |
| green | 2025 | 10 | efectivo | 10,074 | 20.39 |
| green | 2025 | 10 | desconocido/flex | 5,016 | 10.15 |
| green | 2025 | 10 | sin cargo | 285 | 0.58 |
| green | 2025 | 10 | disputa | 88 | 0.18 |
| green | 2025 | 11 | tarjeta | 31,628 | 67.42 |
| green | 2025 | 11 | efectivo | 9,341 | 19.91 |
| green | 2025 | 11 | desconocido/flex | 5,571 | 11.88 |
| green | 2025 | 11 | sin cargo | 286 | 0.61 |
| green | 2025 | 11 | disputa | 86 | 0.18 |
| green | 2025 | 12 | tarjeta | 31,758 | 65.84 |
| green | 2025 | 12 | efectivo | 10,208 | 21.16 |
| green | 2025 | 12 | desconocido/flex | 5,843 | 12.11 |
| green | 2025 | 12 | sin cargo | 330 | 0.68 |
| green | 2025 | 12 | disputa | 97 | 0.2 |
| green | 2026 | 1 | tarjeta | 26,230 | 65.13 |
| green | 2026 | 1 | efectivo | 8,297 | 20.6 |
| green | 2026 | 1 | desconocido/flex | 5,414 | 13.44 |
| green | 2026 | 1 | sin cargo | 237 | 0.59 |
| green | 2026 | 1 | disputa | 94 | 0.23 |
| green | 2026 | 2 | tarjeta | 24,119 | 64.54 |
| green | 2026 | 2 | efectivo | 7,541 | 20.18 |
| green | 2026 | 2 | desconocido/flex | 5,387 | 14.41 |
| green | 2026 | 2 | sin cargo | 237 | 0.63 |
| green | 2026 | 2 | disputa | 89 | 0.24 |
| green | 2026 | 3 | tarjeta | 28,604 | 64.7 |
| green | 2026 | 3 | efectivo | 8,609 | 19.47 |
| green | 2026 | 3 | desconocido/flex | 6,692 | 15.14 |
| green | 2026 | 3 | sin cargo | 228 | 0.52 |
| green | 2026 | 3 | disputa | 75 | 0.17 |
| green | 2026 | 4 | tarjeta | 29,080 | 65.74 |
| green | 2026 | 4 | efectivo | 8,531 | 19.28 |
| green | 2026 | 4 | desconocido/flex | 6,290 | 14.22 |
| green | 2026 | 4 | sin cargo | 241 | 0.54 |
| green | 2026 | 4 | disputa | 96 | 0.22 |
| green | 2026 | 5 | tarjeta | 29,938 | 66.65 |
| green | 2026 | 5 | efectivo | 8,910 | 19.83 |
| green | 2026 | 5 | desconocido/flex | 5,772 | 12.85 |
| green | 2026 | 5 | sin cargo | 200 | 0.45 |
| green | 2026 | 5 | disputa | 101 | 0.22 |
| green | 2026 | 6 | tarjeta | 28,967 | 65.59 |
| green | 2026 | 6 | efectivo | 8,433 | 19.1 |
| green | 2026 | 6 | desconocido/flex | 6,472 | 14.65 |
| green | 2026 | 6 | sin cargo | 199 | 0.45 |
| green | 2026 | 6 | disputa | 92 | 0.21 |
| green | 2026 | 7 | tarjeta | 26,986 | 65.42 |
| green | 2026 | 7 | efectivo | 7,553 | 18.31 |
| green | 2026 | 7 | desconocido/flex | 6,435 | 15.6 |
| green | 2026 | 7 | sin cargo | 177 | 0.43 |
| green | 2026 | 7 | disputa | 101 | 0.24 |
| green | 2026 | 8 | tarjeta | 26,056 | 64.04 |
| green | 2026 | 8 | efectivo | 8,047 | 19.78 |
| green | 2026 | 8 | desconocido/flex | 6,313 | 15.52 |
| green | 2026 | 8 | sin cargo | 169 | 0.42 |
| green | 2026 | 8 | disputa | 102 | 0.25 |

## q4_11_propina_por_pago

**Pregunta:** P8 (pago) - Que porcentaje de propina se deja segun el metodo de pago?

**Objetivo:** Porcentaje de propina sobre la tarifa y proporcion de viajes con propina, por metodo de pago.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (10 filas, 2.32 s):

| taxi_type | metodo_pago | viajes | pct_con_propina | propina_pct_tarifa | propina_prom |
|---|---|---|---|---|---|
| yellow | tarjeta | 78,161,574 | 93.02 | 21.94 | 4.31 |
| yellow | desconocido/flex | 19,220,811 | 10.04 | 2.09 | 0.47 |
| yellow | efectivo | 11,878,821 | 0.01 | 0 | 0 |
| yellow | disputa | 973,988 | 0.08 | 0.04 | 0.01 |
| yellow | sin cargo | 333,802 | 0.09 | 0.04 | 0.01 |
| green | tarjeta | 1,001,428 | 91.63 | 20.77 | 3.72 |
| green | efectivo | 344,228 | 0 | 0 | 0 |
| green | desconocido/flex | 109,427 | 36.79 | 11.32 | 1.75 |
| green | sin cargo | 2,361 | 0.13 | 0.06 | 0.01 |
| green | disputa | 904 | 0.11 | 0.01 | 0 |

## q4_12_composicion_total

**Pregunta:** P9 (pago) - Que componentes forman el monto total pagado?

**Objetivo:** Participacion de tarifa, propina, peajes, recargos y cuotas en el total cobrado.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (2 filas, 2.42 s):

| taxi_type | pct_tarifa | pct_propina | pct_peajes | pct_congestion | pct_cbd_fee | pct_aeropuerto | pct_otros |
|---|---|---|---|---|---|---|---|
| yellow | 69.51 | 10.76 | 1.92 | 6.51 | 1.21 | 0.45 | 9.57 |
| green | 71.65 | 10.85 | 1.02 | 3.37 | 0.16 | 0 | 9.93 |

## q4_13_distribucion_distancia

**Pregunta:** P10 (distribuciones) - Como se distribuye la distancia de los viajes?

**Objetivo:** Histograma de distancia por rangos (millas), por tipo de taxi.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (14 filas, 2.10 s):

| taxi_type | rango_millas | orden | viajes | pct |
|---|---|---|---|---|
| yellow | 0-1 | 0.1 | 22,927,586 | 20.74 |
| yellow | 1-2 | 1 | 35,230,987 | 31.86 |
| yellow | 2-3 | 2 | 17,861,816 | 16.15 |
| yellow | 3-5 | 3 | 13,970,463 | 12.64 |
| yellow | 5-10 | 5 | 11,667,700 | 10.55 |
| yellow | 10-20 | 10 | 7,879,357 | 7.13 |
| yellow | 20+ | 20 | 1,031,087 | 0.93 |
| green | 0-1 | 0.1 | 203,938 | 13.98 |
| green | 1-2 | 1 | 501,183 | 34.37 |
| green | 2-3 | 2 | 294,486 | 20.19 |
| green | 3-5 | 3 | 226,538 | 15.53 |
| green | 5-10 | 5 | 166,544 | 11.42 |
| green | 10-20 | 10 | 59,205 | 4.06 |
| green | 20+ | 20 | 6,454 | 0.44 |

## q4_14_distribucion_tarifa

**Pregunta:** P10 (distribuciones) - Como se distribuye el monto total pagado?

**Objetivo:** Histograma del total por intervalos de 10 USD (hasta 150) usando trips_clean.

**Fuente:** `vista trips_clean`

```sql
SELECT taxi_type, least(floor(total_amount / 10) * 10, 150)::INTEGER AS desde_usd,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS pct
FROM trips_clean
GROUP BY 1, 2
ORDER BY taxi_type DESC, desde_usd;
```

**Resultado** (32 filas, 1.82 s):

| taxi_type | desde_usd | viajes | pct |
|---|---|---|---|
| yellow | 0 | 1,761,098 | 1.59 |
| yellow | 10 | 43,633,735 | 39.46 |
| yellow | 20 | 33,759,239 | 30.53 |
| yellow | 30 | 13,424,654 | 12.14 |
| yellow | 40 | 5,581,175 | 5.05 |
| yellow | 50 | 2,731,461 | 2.47 |
| yellow | 60 | 2,285,345 | 2.07 |
| yellow | 70 | 1,879,507 | 1.7 |
| yellow | 80 | 1,803,935 | 1.63 |
| yellow | 90 | 2,021,038 | 1.83 |
| yellow | 100 | 976,333 | 0.88 |
| yellow | 110 | 218,368 | 0.2 |
| yellow | 120 | 141,613 | 0.13 |
| yellow | 130 | 93,834 | 0.08 |
| yellow | 140 | 63,481 | 0.06 |
| yellow | 150 | 194,180 | 0.18 |
| green | 0 | 83,949 | 5.76 |
| green | 10 | 650,796 | 44.63 |
| green | 20 | 390,074 | 26.75 |
| green | 30 | 156,347 | 10.72 |
| green | 40 | 76,146 | 5.22 |
| green | 50 | 40,342 | 2.77 |
| green | 60 | 21,189 | 1.45 |
| green | 70 | 12,910 | 0.89 |
| green | 80 | 8,314 | 0.57 |
| green | 90 | 6,827 | 0.47 |
| green | 100 | 4,082 | 0.28 |
| green | 110 | 1,973 | 0.14 |
| green | 120 | 1,525 | 0.1 |
| green | 130 | 907 | 0.06 |
| green | 140 | 768 | 0.05 |
| green | 150 | 2,199 | 0.15 |

## q4_15_atipicos_iqr

**Pregunta:** P11 (atipicos) - Cuantos viajes limpios siguen siendo atipicos segun el criterio IQR?

**Objetivo:** Calcular limites de Tukey (Q1 - 1.5 IQR, Q3 + 1.5 IQR) para distancia, duracion, total y costo por milla.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (2 filas, 23.89 s):

| taxi_type | lim_sup_distancia | pct_atip_distancia | lim_sup_duracion | pct_atip_duracion | lim_sup_total | pct_atip_total | lim_sup_usd_milla | pct_atip_usd_milla |
|---|---|---|---|---|---|---|---|---|
| yellow | 7.6 | 12.16 | 41.7 | 5.78 | 54.9 | 9.91 | 15.21 | 4.79 |
| green | 7 | 9.34 | 35.1 | 6.08 | 50.4 | 6.75 | 11.95 | 4.77 |

## q4_16_inconsistencias_monto

**Pregunta:** P11 (inconsistencias) - El total cobrado coincide con la suma de sus componentes?

**Objetivo:** Detectar viajes donde total_amount difiere de la suma de componentes en mas de 0.05 USD.

**Fuente:** `vista trips`

```sql
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
```

**Resultado** (2 filas, 2.38 s):

| taxi_type | viajes | total_no_cuadra | pct_no_cuadra | efectivo_con_propina_registrada | velocidad_mayor_80mph |
|---|---|---|---|---|---|
| yellow | 119,595,677 | 39,742,163 | 33.23 | 3,542 | 34,932 |
| green | 1,588,707 | 249,449 | 15.701 | 6 | 6,845 |

## q4_17_aeropuertos

**Pregunta:** P12 (caracteristicas) - Que peso tienen los viajes a/desde aeropuertos y cuanto cuestan?

**Objetivo:** Viajes, distancia y monto promedio de los viajes que tocan JFK, LaGuardia o Newark versus el resto.

**Fuente:** `vistas trips_clean + zones`

```sql
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
```

**Resultado** (4 filas, 6.36 s):

| taxi_type | categoria | viajes | pct_viajes | distancia_prom | total_prom | pct_ingresos |
|---|---|---|---|---|---|---|
| yellow | aeropuerto | 10,087,232 | 9.12 | 13.4 | 78.68 | 24.67 |
| yellow | otros | 100,481,764 | 90.88 | 2.51 | 24.12 | 75.33 |
| green | aeropuerto | 56,885 | 3.9 | 7.44 | 47.81 | 7.54 |
| green | otros | 1,401,463 | 96.1 | 2.96 | 23.8 | 92.46 |

## q4_18_fin_de_semana_vs_semana

**Pregunta:** P2 (temporal) - Cambian las caracteristicas del viaje entre semana y fin de semana?

**Objetivo:** Comparar volumen diario, distancia, duracion y propina por tipo de dia.

**Fuente:** `vista trips_clean`

```sql
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
```

**Resultado** (4 filas, 2.57 s):

| taxi_type | tipo_dia | viajes_por_dia | distancia_prom | duracion_prom | velocidad_prom | propina_pct_tarifa |
|---|---|---|---|---|---|---|
| yellow | entre semana | 113,247 | 3.46 | 17.7 | 10.6 | 16.1 |
| yellow | fin de semana | 114,206 | 3.6 | 16.2 | 12 | 13.91 |
| green | entre semana | 1,597 | 3.07 | 15.9 | 11.3 | 15.34 |
| green | fin de semana | 1,249 | 3.34 | 15.1 | 12.7 | 14.58 |

## q4_19_inconsistencia_por_proveedor

**Pregunta:** P11 (inconsistencias) - La diferencia entre el total y sus componentes depende del proveedor del taximetro?

**Objetivo:** Diferencia mediana (total - suma de componentes) por proveedor y metodo de pago, solo en viajes que no cuadran.

**Fuente:** `vista trips`

```sql
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
```

**Resultado** (21 filas, 2.37 s):

| taxi_type | proveedor | pago | viajes | pct_no_cuadra | diferencia_mediana_usd |
|---|---|---|---|---|---|
| yellow | 2 Curb Mobility | tarjeta | 61,359,607 | 0.1 | 2.5 |
| yellow | 2 Curb Mobility | flex/desconocido | 19,994,826 | 86 | 2.5 |
| yellow | 1 Creative Mobile | tarjeta | 18,306,865 | 87.7 | -2.5 |
| yellow | 2 Curb Mobility | efectivo | 10,109,395 | 0.4 | 2.5 |
| yellow | 1 Creative Mobile | flex/desconocido | 3,339,547 | 88.7 | 2.5 |
| yellow | 1 Creative Mobile | efectivo | 2,682,130 | 93.3 | -2.5 |
| yellow | 2 Curb Mobility | otro | 2,373,295 | 1.1 | -0.75 |
| yellow | 7 Helix | tarjeta | 780,695 | 45.7 | 1 |
| yellow | 1 Creative Mobile | otro | 441,320 | 84.3 | -2.5 |
| yellow | 7 Helix | efectivo | 110,939 | 39.1 | 1 |
| yellow | 6 Myle | flex/desconocido | 85,441 | 98.5 | 24.77 |
| yellow | 7 Helix | otro | 11,617 | 43.8 | 1 |
| green | 2 Curb Mobility | tarjeta | 953,711 | 0.1 | 2.5 |
| green | 2 Curb Mobility | efectivo | 330,689 | 0.1 | 2.5 |
| green | 1 Creative Mobile | tarjeta | 127,568 | 97.7 | -1 |
| green | 6 Myle | flex/desconocido | 61,932 | 100 | 21.18 |
| green | 2 Curb Mobility | flex/desconocido | 58,441 | 29.7 | 2.75 |
| green | 1 Creative Mobile | efectivo | 40,077 | 97.5 | -1 |
| green | 2 Curb Mobility | otro | 9,299 | 0.2 | -0.75 |
| green | 1 Creative Mobile | otro | 4,380 | 80.3 | -1 |
| green | 1 Creative Mobile | flex/desconocido | 2,610 | 63.5 | 2.75 |
