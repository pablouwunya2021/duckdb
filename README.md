# Lab 8 - DuckDB

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este es el repositorio **proporcionado por el docente**. Contiene la estructura
del proyecto, el ambiente de ejecucion basado en Docker y un script que descarga
los datos de **2026**. Todo lo demas debe ser construido por cada equipo.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/<su-usuario>/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|
+-- sql/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
2026 publicados por la TLC (`--help` muestra las opciones disponibles). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, completado segun la siguiente seccion.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones deben ser completadas por cada equipo. El README final
debe permitir que una persona que no participo en el desarrollo pueda levantar el
ambiente, descargar los datos, ejecutar el analisis, reproducir los benchmarks y
generar los resultados principales.

**Fork del equipo:** <https://github.com/pablouwunya2021/duckdb>
**Integrantes:** Pablo Cabrera (`pablouwunya2021`), Fernando Mendoza (`lfmendoza`)

## Como levantar el ambiente

Requisitos: Docker Desktop (o Docker Engine + Compose v2), Git y ~10 GB libres.

```bash
# 1. Clonar el fork
git clone https://github.com/pablouwunya2021/duckdb.git lab8-duckdb
cd lab8-duckdb
git remote add upstream https://github.com/menene/duckdb.git   # opcional

# 2. Construir y levantar los servicios en segundo plano
docker compose up --build -d

# 3. Verificar que ambos servicios esten arriba
docker compose ps
curl -s http://127.0.0.1:3000/api/health      # {"status":"ok"} -> Metabase
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8888/api   # 200 -> JupyterLab
```

| Servicio | URL | Contenido |
|---|---|---|
| JupyterLab (`lab8-lab`) | <http://127.0.0.1:8888> | Python 3.11, DuckDB 1.5.5, pandas, pyarrow, matplotlib |
| Metabase (`lab8-metabase`) | <http://127.0.0.1:3000> | Metabase v0.63.19 + driver DuckDB 1.5.5.0 |

Todos los comandos de las siguientes secciones se ejecutan **dentro del contenedor
`lab`** (cuyo directorio de trabajo es `/workspace`), por ejemplo:

```bash
docker exec -it lab8-lab bash        # abrir una terminal dentro del ambiente
docker exec lab8-lab python scripts/download_data.py   # o ejecutar algo directo
```

Para detener el ambiente: `docker compose down` (agregar `-v` borra tambien la
configuracion de Metabase). Detalle del analisis de la estructura, herramientas y
la justificacion de un ambiente reproducible: [`docs/01_ambiente.md`](docs/01_ambiente.md).

## Como descargar los datos

```bash
# Descarga todos los meses publicados de los anios configurados en ANIOS (yellow + green)
docker exec lab8-lab python scripts/download_data.py

# Opciones
docker exec lab8-lab python scripts/download_data.py --anio 2026          # un anio
docker exec lab8-lab python scripts/download_data.py --taxi green         # un tipo
docker exec lab8-lab python scripts/download_data.py --verificar          # revalidar tamanios vs servidor

# Verificar integridad y completitud (lee metadatos Parquet con DuckDB)
docker exec lab8-lab python scripts/verify_data.py --salida docs/inventario_datos.md
```

- Los archivos quedan en `data/raw/<tipo>/<anio>/<tipo>_tripdata_<anio>-<mes>.parquet`.
- Un archivo existente no se vuelve a descargar; las descargas se validan contra el
  `Content-Length` del servidor y se registran en `data/raw/manifest.csv`.
- Los meses que la TLC aun no publica se reportan como `no publicado` y se obtendran
  automaticamente en una ejecucion posterior.
- Para agregar un anio basta con incluirlo en `ANIOS` dentro de `scripts/download_data.py`
  (o pasar `--anio`); las vistas y consultas lo incorporan automaticamente.
- Cambios al script y verificacion de completitud: [`docs/02_descarga.md`](docs/02_descarga.md).
- Incorporacion de 2024: [`docs/05_incorporacion_2024.md`](docs/05_incorporacion_2024.md).

## Como ejecutar el analisis

Todas las consultas estan en `sql/` y se ejecutan con DuckDB **directamente sobre los Parquet**
mediante las vistas de [`sql/00_vistas.sql`](sql/00_vistas.sql) (`trips`, `trips_clean`, `zones`).
Cada consulta tiene un nombre (`-- name:`) y metadatos (`-- objetivo`, `-- fuente`, `-- decision`);
`scripts/run_sql.py` las ejecuta y genera un reporte Markdown con el SQL, el resultado y el tiempo.

```bash
docker exec lab8-lab python scripts/run_sql.py sql/03_exploracion.sql   # Ej. 3: exploracion directa de Parquet
docker exec lab8-lab python scripts/run_sql.py sql/04_eda.sql           # Ej. 4: analisis exploratorio
docker exec lab8-lab python scripts/run_sql.py sql/05_validacion_2024.sql
docker exec lab8-lab python scripts/run_sql.py sql/08_validacion_2025.sql
# reportes en docs/resultados/<archivo>.md
```

Notebooks (JupyterLab en <http://127.0.0.1:8888>, carpeta `notebooks/`):

| Notebook | Contenido |
|---|---|
| `01_exploracion_parquet.ipynb` | Ejercicio 3 (salidas guardadas con datos 2026) |
| `02_eda.ipynb` | Ejercicio 4 con graficas (salidas guardadas con datos 2026) |
| `03_incorporacion_anios.ipynb` | Ejercicios 5 y 8: validacion de 2024 y 2025 |
| `04_benchmark.ipynb` | Ejercicio 6: demo en vivo y analisis de resultados |
| `05_indicadores_evolucion.ipynb` | Ejercicios 7 y 8: indicadores y evolucion 2024-2026 |

Para re-ejecutar un notebook desde la terminal:
`docker exec -w /workspace/notebooks lab8-lab jupyter nbconvert --to notebook --execute --inplace 02_eda.ipynb`

## Como reproducir los benchmarks

```bash
docker exec lab8-lab python scripts/build_db.py                          # base del proyecto: data/processed/taxi.duckdb
docker exec lab8-lab python scripts/benchmark.py --repeticiones 5 --limpiar
```

- Consultas: [`sql/06_benchmark.sql`](sql/06_benchmark.sql) (8 consultas representativas de los Ej. 3-4).
- Se ejecuta **el mismo SQL** sobre vistas Parquet y sobre una tabla materializada, en 4 escalas
  (1 mes, 1 trimestre, 1 anio, todos), con 1 ejecucion inicial + N repeticiones, y se verifica que
  ambas estrategias devuelvan resultados identicos.
- Salidas: `docs/resultados/06_benchmark.md`, `docs/resultados/06_benchmark_resultados.csv`,
  `docs/img/bench_*.png`. Opciones: `--hilos 4 --memoria 3GB` (por defecto, evitan quedarse sin memoria
  con 121 M de filas), `--escalas 1_mes todos`.
- Analisis: [`docs/06_benchmark.md`](docs/06_benchmark.md).

## Como generar los resultados principales

Todo el flujo (descarga -> verificacion -> reportes -> base + indicadores -> benchmark -> tablero):

```bash
docker exec lab8-lab sh scripts/run_all.sh            # agregar --sin-benchmark para omitirlo
docker compose restart metabase                       # Metabase suelta la base anterior
docker exec lab8-lab python scripts/setup_metabase.py # crea/actualiza el tablero
```

Tablero (Ejercicio 7): `setup_metabase.py` crea un administrador **local** de Metabase (credenciales
generadas en `data/processed/metabase_admin.json`, fuera de Git, o tomadas de `MB_EMAIL`/`MB_PASSWORD`),
la conexion DuckDB de solo lectura a `taxi.duckdb`, una pregunta por indicador y el tablero
"Taxis NYC - Indicadores"; al final imprime la URL privada y un enlace publico de solo lectura.
Evidencia: [`docs/dashboard/tablero_final_2024_2025_2026.png`](docs/dashboard/tablero_final_2024_2025_2026.png).

### Documentacion por ejercicio

| Ejercicio | Documento | SQL / codigo |
|---|---|---|
| 1. Ambiente | [`docs/01_ambiente.md`](docs/01_ambiente.md) | `Dockerfile`, `docker-compose.yml` |
| 2. Descarga | [`docs/02_descarga.md`](docs/02_descarga.md), [`docs/inventario_datos.md`](docs/inventario_datos.md) | `scripts/download_data.py`, `scripts/verify_data.py` |
| 3. Consultas sobre Parquet | [`docs/03_consultas_parquet.md`](docs/03_consultas_parquet.md) | `sql/00_vistas.sql`, `sql/03_exploracion.sql` |
| 4. EDA | [`docs/04_eda.md`](docs/04_eda.md) | `sql/04_eda.sql` |
| 5. Incorporacion de 2024 | [`docs/05_incorporacion_2024.md`](docs/05_incorporacion_2024.md) | `sql/05_validacion_2024.sql` |
| 6. Parquet vs tabla | [`docs/06_benchmark.md`](docs/06_benchmark.md) | `sql/06_benchmark.sql`, `scripts/build_db.py`, `scripts/benchmark.py` |
| 7. Indicadores y tablero | [`docs/07_indicadores.md`](docs/07_indicadores.md) | `sql/07_indicadores.sql`, `scripts/setup_metabase.py` |
| 8. 2025 y analisis completo | [`docs/08_analisis_completo.md`](docs/08_analisis_completo.md) | `sql/08_validacion_2025.sql` |
| 9. Discusion | [`docs/09_discusion.md`](docs/09_discusion.md) | |

### Resultados principales

- **Datos:** 64 archivos Parquet (yellow + green, ene-2024 a ago-2026), 121,184,384 viajes, 1.98 GB.
- **Calidad:** 89-95% de registros validos por anio; problemas tipicos documentados (fechas fuera de rango,
  duraciones/distancias imposibles, montos negativos, 26% de viajes amarillos sin datos de taximetro en 2026,
  diferencias sistematicas de registro entre proveedores).
- **Benchmark (121 M filas):** la tabla DuckDB es ~1.4x mas rapida en consultas repetidas y ~9x en filtros
  selectivos, pero cuesta 31.6 s de carga, ocupa 2.1x mas disco y es mas lenta en la primera ejecucion.
- **Tendencias 2024-2026:** pico de demanda del taxi amarillo en 2025 (+13%) y leve caida en 2026; declive
  sostenido del taxi verde (-24% en dos anios); la cuota de congestion (2025) se paga en ~72% de los viajes
  amarillos sin mejora de velocidad en la zona CBD; crecen los viajes por plataformas (Uber/Lyft) y los
  aeropuertos pierden peso en los ingresos (27.9% -> 21.1%).
