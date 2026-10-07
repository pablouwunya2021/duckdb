# Ejercicio 6 - Parquet versus tablas DuckDB

- **Consultas del benchmark:** [`sql/06_benchmark.sql`](../sql/06_benchmark.sql) (6.3, 6.8)
- **Script:** [`scripts/benchmark.py`](../scripts/benchmark.py) · **Base materializada:** [`scripts/build_db.py`](../scripts/build_db.py)
- **Resultados completos:** [`docs/resultados/06_benchmark.md`](resultados/06_benchmark.md) y
  [`06_benchmark_resultados.csv`](resultados/06_benchmark_resultados.csv)
- **Notebook:** [`notebooks/04_benchmark.ipynb`](../notebooks/04_benchmark.ipynb)

```bash
docker exec lab8-lab python scripts/build_db.py                    # 6.2 base del proyecto
docker exec lab8-lab python scripts/benchmark.py --repeticiones 5  # 6.4 - 6.7
```

> Esta página corresponde a la ejecución con **2024 + 2026** (71.9 M de filas). En el Ejercicio 8
> el benchmark se volvió a ejecutar con los tres años (ver [`08_analisis_completo.md`](08_analisis_completo.md)).

## Metodología

| Aspecto | Decisión |
|---|---|
| 6.1 Parquet directo | Conexión en memoria con las vistas `trips`/`trips_clean`/`zones` de `sql/00_vistas.sql`; cada consulta lee los archivos |
| 6.2 Tabla materializada | `CREATE TABLE trips AS SELECT * FROM trips` (la vista anterior) + `zones` en un archivo `.duckdb`; `trips_clean` se recrea como vista con **las mismas reglas** sobre la tabla. Para el proyecto: `data/processed/taxi.duckdb` (`build_db.py`) |
| 6.3 Consultas representativas | 8 consultas tomadas de los ejercicios 3 y 4 que cubren distintos patrones: conteo (metadatos), agregación temporal, agregación por fecha derivada, percentiles, JOIN, filtro selectivo, CASE condicional y lectura de muchas columnas |
| Equivalencia (validez) | **El mismo texto SQL** se ejecuta en ambas estrategias; ambas fuentes tienen exactamente las mismas filas y el script compara los resultados: 32/32 combinaciones devolvieron el mismo resultado |
| 6.5 Medición | Conexión nueva por consulta y estrategia: 1 ejecución "primera" + 5 repeticiones; se reporta la **mediana** (robusta a ruido) y la primera ejecución por separado |
| 6.6 Escalas | `1_mes` (ene-2026, 3.8 M filas), `1_trimestre` (ene-mar 2026, 11.2 M), `anio_2024` (41.8 M), `todos` (71.9 M) |
| Ambiente | Contenedor `lab8-lab`, DuckDB 1.5.5, 10 hilos, ~7.6 GB RAM, disco SSD (montaje virtiofs) |

## 6.7 Resultados

### Costo de materializar

| escala | filas | Parquet | tabla DuckDB | tiempo de `CREATE TABLE` |
|---|---:|---:|---:|---:|
| 1_mes | 3,765,161 | 62 MiB | 127 MiB | 0.9 s |
| 1_trimestre | 11,199,059 | 185 MiB | 386 MiB | 1.8 s |
| anio_2024 | 41,829,938 | 676 MiB | 1,406 MiB | 6.2 s |
| todos | 71,870,407 | 1,172 MiB | 2,419 MiB | 10.1 s |

### Mediana por consulta (segundos) - escala `todos` (71.9 M filas)

| consulta | patrón | Parquet | tabla | speedup | Parquet 1ª ejec. | tabla 1ª ejec. |
|---|---|---:|---:|---:|---:|---:|
| b1_conteo_total | metadatos | 0.035 | 0.0002 | ×199 | 0.037 | 0.003 |
| b2_viajes_ingresos_por_mes | agregación simple | 0.112 | 0.139 | ×0.8 | 0.132 | 0.353 |
| b3_heatmap_hora_dia | funciones de fecha + filtros | 1.164 | 0.625 | ×1.9 | 1.182 | 2.544 |
| b4_percentiles_viaje | percentiles (CPU) | 4.978 | 4.464 | ×1.1 | 5.440 | 6.994 |
| b5_join_zonas | JOIN | 1.578 | 0.775 | ×2.0 | 1.605 | 2.909 |
| b6_filtro_selectivo | filtro muy selectivo | 0.324 | 0.030 | **×10.9** | 0.358 | 1.023 |
| b7_propina_por_pago | CASE + filtros | 1.640 | 0.872 | ×1.9 | 1.662 | 2.448 |
| b8_muchas_columnas | muchas columnas | 0.966 | 0.588 | ×1.6 | 0.942 | 1.972 |

### Comportamiento según el volumen (suma de medianas de las 8 consultas)

| escala | filas | Parquet | tabla | speedup | ejecuciones del conjunto para amortizar la carga |
|---|---:|---:|---:|---:|---:|
| 1_mes | 3.8 M | 0.77 s | 0.32 s | ×2.45 | 1.9 |
| 1_trimestre | 11.2 M | 1.77 s | 1.09 s | ×1.63 | 2.6 |
| anio_2024 | 41.8 M | 6.04 s | 4.44 s | ×1.36 | 3.8 |
| todos | 71.9 M | 10.80 s | 7.49 s | ×1.44 | 3.0 |

![Tiempos](img/bench_tiempos.png)
![Speedup](img/bench_speedup.png)

## 6.9 Análisis de las diferencias

1. **Ambas estrategias escalan de forma ~lineal** con el número de filas (gráfica izquierda): de 3.8 M
   a 71.9 M (×19) el tiempo total crece ×14 (Parquet) y ×24 (tabla). DuckDB procesa los Parquet en
   paralelo y por columnas, así que incluso sin materializar se analizan 72 M de filas en ~11 s para
   las 8 consultas.
2. **En ejecuciones repetidas la tabla es 1.4-2.5× más rápida.** El formato nativo de DuckDB guarda los
   datos en row groups con estadísticas (*zonemaps*) y, una vez leídos, los bloques quedan en el
   *buffer manager* ya descomprimidos; el lector de Parquet tiene que volver a abrir los 40 archivos,
   leer sus footers y descomprimir ZSTD en cada ejecución.
3. **La mayor ventaja aparece en consultas selectivas (b6, ×10.9).** El filtro por zona JFK + domingo +
   noche permite a la tabla saltarse la mayoría de los bloques usando zonemaps en memoria; en Parquet
   hay que leer las columnas de los 40 archivos.
4. **Los conteos se resuelven con metadatos en ambos casos** (b1): 35 ms en Parquet (leer 40 footers) y
   prácticamente 0 en la tabla (el conteo está en el catálogo).
5. **Cuando la consulta está dominada por CPU, la diferencia desaparece** (b4, percentiles ×1.1): el
   costo está en ordenar/agregar, no en leer.
6. **En agregaciones muy simples Parquet puede ganar** (b2, ×0.8): `file_year`/`file_month` se derivan del
   nombre del archivo (constante por archivo) y `taxi_type` es constante en cada rama de la vista, así que
   Parquet solo lee `total_amount`; la tabla debe leer cuatro columnas almacenadas.
7. **Primera ejecución ("en frío"): Parquet es más rápido** en casi todas las consultas (p. ej. b3: 1.18 s
   vs 2.54 s). La tabla ocupa **2.1× más espacio** en disco (2.4 GB vs 1.2 GB: DuckDB usa compresión más
   ligera que ZSTD) y la primera lectura debe traer esos bloques al buffer manager. La ventaja de la tabla
   aparece solo cuando la misma sesión ejecuta varias consultas.
8. **Costo de materializar:** ~10 s para 72 M filas y el doble de disco. El conjunto de 8 consultas se
   amortiza después de ~2-4 ejecuciones; para una consulta exploratoria única no compensa.

## 6.10 ¿Cuándo usar cada estrategia?

**Consultar Parquet directamente cuando:**
- se está explorando un conjunto nuevo o se ejecutan consultas una sola vez (no compensa los ~10 s de carga
  ni duplicar 1.2 GB en disco);
- los datos llegan de forma incremental (nuevos meses/años): basta con descargar el archivo, sin recargar;
- el almacenamiento es limitado o los datos se comparten con otras herramientas (Spark, pandas, Polars)
  — Parquet es un formato abierto y es la "fuente de verdad";
- las consultas son conteos, agregaciones sobre pocas columnas o los datos viven en almacenamiento remoto (S3).

**Materializar una tabla DuckDB cuando:**
- las mismas consultas se ejecutan muchas veces en una sesión o las consulta un tablero (Metabase): cada
  interacción del usuario repite agregaciones;
- hay filtros selectivos frecuentes (×11 en b6) o JOINs repetidos;
- se necesitan tipos/columnas derivadas ya calculadas, índices o actualizaciones (UPDATE/DELETE);
- la herramienta consumidora no puede resolver rutas relativas a Parquet (Metabase corre en otro contenedor y
  su directorio de trabajo es distinto; la base materializada es autocontenida).

**Estrategia adoptada en el proyecto:** Parquet como fuente de verdad y para la exploración/validación
(Ejercicios 3-5), y una base materializada `taxi.duckdb` (+ tablas pequeñas de indicadores) como capa de
servicio para el tablero (Ejercicio 7), regenerable con `build_db.py` cada vez que se incorporan datos.
