# Ejercicio 9 - Discusión

## 9.1 ¿Qué características de DuckDB resultaron más útiles?

- **Consultar Parquet directamente con globs** (`read_parquet('data/raw/yellow/*/*.parquet')`): permitió
  trabajar con 121 M de filas sin paso de carga y que los años nuevos aparecieran solos.
- **`union_by_name` y `UNION ALL BY NAME`**: absorbieron la evolución del esquema (`cbd_congestion_fee` en
  2025, `request_source` en jun-2026, diferencias yellow/green) sin reescribir consultas.
- **`filename = true`**: año/mes de origen de cada fila; base de las validaciones y de las reglas de limpieza.
- **Funciones de metadatos** (`parquet_file_metadata`, `parquet_schema`, `parquet_metadata`, `glob`):
  conteos y verificación de completitud en milisegundos sin leer datos.
- **SQL analítico expresivo**: `SUMMARIZE`, `GROUP BY ALL`, `FILTER (WHERE ...)`, `PIVOT/UNPIVOT`,
  `quantile_cont` con listas, `arg_max`, `USING SAMPLE ... REPEATABLE`, funciones de ventana.
- **Vistas lógicas** (`trips`, `trips_clean`): una sola definición de la normalización y la limpieza.
- **`ATTACH` + `CREATE TABLE AS`**: materializar 121 M de filas en ~30 s en un único archivo portable.
- **Embebido en Python y en Metabase**: el mismo motor en scripts, notebooks y tablero, sin servidor.
- **Configuración de recursos** (`memory_limit`, `threads`, `temp_directory`, `preserve_insertion_order`):
  imprescindible cuando el volumen creció a 121 M de filas.

## 9.2 Ventajas y limitaciones de consultar directamente Parquet

| Ventajas | Limitaciones |
|---|---|
| Sin tiempo de carga ni duplicación (1.98 GB de Parquet vs 4.18 GB de tabla) | En ejecuciones repetidas es 1.4-2× más lento que la tabla y ~9× en filtros selectivos |
| Los archivos nuevos se consultan inmediatamente (globs) | Cada consulta vuelve a abrir 64 archivos, leer footers y descomprimir ZSTD |
| Formato abierto, compartible con otras herramientas | Rutas relativas: Metabase (otro contenedor/directorio) no puede usar las vistas |
| Lectura columnar + estadísticas por row group; `COUNT(*)` desde metadatos | El esquema puede variar entre archivos y obliga a `union_by_name` y manejo de nulos |
| En la primera ejecución suele ser más rápido que la tabla | Sin índices, sin actualizaciones (UPDATE/DELETE) |
| Los archivos originales permanecen inmutables (trazabilidad) | El rendimiento depende del disco y del tamaño de row group elegido por el publicador |

## 9.3 Ventajas y limitaciones de las tablas materializadas

**Ventajas:** 1.4-2.1× más rápidas en consultas repetidas, hasta ~9-11× en filtros selectivos (zonemaps y
buffer manager), conteos instantáneos (catálogo), archivo autocontenido que Metabase puede abrir en modo
lectura, y permiten precalcular indicadores pequeños para el tablero.

**Limitaciones:** costo de carga (31.6 s para 121 M filas) que se amortiza recién tras ~3-4 ejecuciones del
conjunto de consultas; ocupan **2.1× más disco** que el Parquet; la primera ejecución en una conexión nueva
es más lenta que Parquet; hay que **reconstruirlas** cada vez que llegan datos (y reiniciar Metabase, que
mantiene abierto el archivo anterior); un solo proceso escritor por archivo; y operaciones sobre la tabla
sin comprimir (medianas de 121 M filas) llegaron a agotar la memoria del contenedor.

## 9.4 Ventajas frente a cargar todo con Pandas

- **Memoria:** 121 M de filas × 26 columnas ocuparían decenas de GB en un DataFrame; el contenedor tiene
  ~7.6 GB. DuckDB procesa por bloques, en streaming, con derrame a disco.
- **Solo se lee lo necesario:** proyección de columnas y filtros empujados al lector de Parquet; pandas
  carga todas las columnas y filas antes de filtrar.
- **Paralelismo automático** en todos los núcleos; pandas es mayormente de un solo hilo.
- **SQL declarativo y versionable**, reutilizable en Metabase y en scripts; las transformaciones quedan
  documentadas en `sql/`.
- **Pandas sigue siendo útil al final**: los resultados agregados (decenas de filas) se pasan a pandas para
  graficar (`.df()`), que es como se usó en los notebooks.

## 9.5 Características del sistema que permiten incorporar datos con cambios mínimos

1. Año como configuración (`ANIOS` / `--anio`), no como código: agregar 2024 y 2025 fue cambiar una línea.
2. Convención de rutas `data/raw/<tipo>/<anio>/` + globs en una única capa de vistas (`sql/00_vistas.sql`).
3. `union_by_name` y columnas opcionales declaradas explícitamente (robustez ante esquemas distintos).
4. `file_year`/`file_month` derivados del nombre de archivo; las consultas agrupan por ellos y no usan
   años fijos.
5. Descarga idempotente con validación de tamaño, manifiesto y `verify_data.py`.
6. Reportes, base, indicadores y tablero regenerables con un comando (`scripts/run_all.sh`).

## 9.6 ¿Qué debería automatizarse en producción?

- **Ingesta programada** (p. ej. mensual con cron/Airflow) que detecte los meses recién publicados por la
  TLC, descargue, verifique (tamaño, legibilidad, conteos, esquema) y alerte si algo falla.
- **Validación de esquema y calidad** automática: comparar columnas/tipos con los meses anteriores (aparición
  de `request_source`) y umbrales sobre `% válidos` y `% sin taxímetro` (como el salto de 2025).
- **Reconstrucción incremental** de la base: insertar solo los meses nuevos en lugar de recrear 121 M filas,
  y refrescar las tablas de indicadores.
- **Refresco de Metabase** (reinicio/reconexión y sincronización) y regeneración del tablero.
- **Benchmarks de regresión** y monitoreo de tiempos/memoria, CI que ejecute las consultas sobre una muestra.

## 9.7 Decisiones de diseño importantes para la reproducibilidad

- Ambiente Docker con versiones fijadas (DuckDB 1.5.5 alineado con el driver de Metabase).
- Datos fuera de Git (`.gitignore`), descargados desde la fuente oficial por script; inventario y manifiesto.
- Datos crudos inmutables; toda transformación en SQL versionado (vistas, reglas de limpieza documentadas).
- Consultas con metadatos (`-- objetivo`, `-- fuente`, `-- decision`) y reportes generados automáticamente
  con el resultado real, el tiempo y la fecha.
- Muestras reproducibles (`REPEATABLE (42)`), benchmark con verificación de resultados idénticos.
- Metabase configurado por API (`setup_metabase.py`) en lugar de clics manuales; credenciales locales
  generadas fuera del repositorio.
- Instantáneas de resultados por fase (`*_2026`, `*_2024_2026`, `*_3anios`) para conservar la evidencia de
  cada etapa del laboratorio.

## 9.8 ¿Qué se aprendió que no habría sido evidente con datos pequeños?

- **La memoria es un recurso de diseño:** con 72 M filas todo funcionó con la configuración por defecto; con
  121 M el contenedor terminó por OOM. Hubo que limitar hilos (los buffers de lectura por hilo no cuentan en
  `memory_limit`), evitar medianas sobre la tabla sin comprimir y usar derrame a disco.
- **Los "errores raros" dejan de ser raros:** 0.01% de 121 M son miles de registros (fechas de 2001, distancias
  de 328,000 millas, totales de 7,000 USD); cualquier promedio sin limpieza queda sesgado.
- **La calidad cambia con el tiempo y por proveedor:** el 36.7% de totales que no cuadran se explica por
  diferencias sistemáticas entre proveedores de taxímetro; el 2025 tiene un salto de tarifas en cero. Con una
  muestra pequeña o un solo mes no se ve.
- **El esquema evoluciona:** columnas nuevas (2025, 2026) obligan a diseñar para la heterogeneidad.
- **El costo de una estrategia depende del uso:** materializar no siempre es mejor (primera ejecución más
  lenta, el doble de disco); el formato de almacenamiento importa tanto como el motor.
- **Comparar períodos equivalentes:** con años incompletos (2026 hasta agosto) los totales anuales engañan;
  hay que normalizar por día o comparar los mismos meses.
- **Las tendencias necesitan varios años:** con 2024 y 2026 parecía un crecimiento del 11%; con 2025 se ve un
  pico y una leve caída posterior.
