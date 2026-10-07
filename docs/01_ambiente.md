# Ejercicio 1 - Preparación del ambiente

## 1.1 / 1.2 Fork y clonación

- Fork: <https://github.com/pablouwunya2021/duckdb> (creado a partir de <https://github.com/menene/duckdb>).
- El repositorio del docente se dejó configurado como remoto `upstream` para poder
  recibir correcciones:

```bash
git clone https://github.com/pablouwunya2021/duckdb.git lab8-duckdb
cd lab8-duckdb
git remote add upstream https://github.com/menene/duckdb.git
docker compose up --build -d
```

## Análisis de la estructura del proyecto

| Directorio / archivo | Propósito |
|---|---|
| `data/raw/` | Datos **crudos e inmutables** tal como los publica la TLC (`data/raw/<tipo>/<anio>/*.parquet`). Nunca se modifican; cualquier transformación se hace por SQL. Excluido de Git. |
| `data/processed/` | Productos derivados: base DuckDB materializada (`taxi.duckdb`), resultados de benchmarks, agregados para el tablero. Se puede regenerar completamente a partir de `raw/` + scripts. Excluido de Git. |
| `notebooks/` | Notebooks de Jupyter para exploración interactiva y narración del análisis (consultas + resultados + gráficas). |
| `scripts/` | Código ejecutable y reproducible: descarga de datos, verificación, creación de la base, benchmarks y generación de gráficas. Es la "tubería" del proyecto. |
| `sql/` | Consultas SQL versionadas y documentadas (una por archivo/sección), reutilizadas por notebooks, scripts y Metabase. |
| `docs/` | Documentación de cada ejercicio, resultados de consultas, benchmarks e imágenes del tablero. |
| `Dockerfile` | Imagen del ambiente de análisis (Python 3.11 + DuckDB + JupyterLab + pandas/pyarrow/matplotlib), con versiones fijadas. |
| `metabase.Dockerfile` | Imagen de Metabase (herramienta de visualización/tableros) con el driver de DuckDB, sobre Debian porque el driver necesita glibc. |
| `docker-compose.yml` | Orquesta los dos servicios (`lab` y `metabase`), puertos y volúmenes compartidos (`./data` montado en `/workspace/data` en ambos). |
| `requirements.txt` | Dependencias de Python con versión exacta (DuckDB alineado con la versión del driver de Metabase). |
| `README.md` | Punto de entrada: cómo levantar el ambiente, descargar datos y reproducir todo. |

## 1.3 Verificación de los servicios

Comandos utilizados y resultado obtenido:

```bash
docker compose ps
```

```text
NAME            IMAGE                  SERVICE    STATUS          PORTS
lab8-lab        lab8-duckdb-lab        lab        Up              127.0.0.1:8888->8888/tcp
lab8-metabase   lab8-duckdb-metabase   metabase   Up              127.0.0.1:3000->3000/tcp
```

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8888/api   # -> 200 (JupyterLab)
curl -s http://127.0.0.1:3000/api/health                             # -> {"status":"ok"} (Metabase)
docker exec lab8-metabase ls /home/metabase/plugins                  # -> duckdb.metabase-driver.jar
docker exec lab8-lab python -c "import duckdb; print(duckdb.__version__)"  # -> 1.5.5
```

## 1.4 Herramientas disponibles en el ambiente

| Servicio | Herramienta | Versión | Uso en el laboratorio |
|---|---|---|---|
| `lab` (puerto 8888) | Python | 3.11.14 | Lenguaje base |
| | DuckDB (API Python) | 1.5.5 | Motor analítico: consultas sobre Parquet y base materializada |
| | JupyterLab | 4.6.4 | Notebooks de exploración |
| | pandas | 3.0.6 | Manejo de resultados pequeños (salidas de DuckDB) |
| | pyarrow | 25.0.1 | Lectura/metadatos de Parquet e intercambio con DuckDB |
| | matplotlib | 3.11.2 | Gráficas de los indicadores |
| | requests | 2.34.2 | Descarga de datos desde la TLC |
| | curl | sistema | Verificaciones HTTP |
| `metabase` (puerto 3000) | Metabase | v0.63.19 | Tablero de indicadores |
| | Driver DuckDB para Metabase | 1.5.5.0 | Conexión de Metabase a `taxi.duckdb` (solo lectura) |

No se incluye el CLI `duckdb`; todo el SQL se ejecuta desde Python (`duckdb.sql(...)`) o desde Metabase.

## 1.6 ¿Por qué un ambiente reproducible?

- **Mismos resultados en cualquier máquina:** las versiones de Python, DuckDB, pandas, etc. están fijadas
  en `requirements.txt` y en las imágenes. Un cambio de versión de DuckDB puede cambiar tipos inferidos,
  funciones disponibles o incluso el formato del archivo `.duckdb`; fijarlas elimina el "en mi máquina sí funciona".
- **Compatibilidad entre componentes:** el driver de Metabase debe coincidir con la versión de DuckDB usada
  para crear la base; si no, Metabase no puede abrir el archivo. Docker garantiza esa alineación.
- **Integración inmediata de nuevos miembros / evaluadores:** con `docker compose up --build` cualquier
  persona obtiene el mismo ambiente sin instalar nada más que Docker.
- **Trazabilidad:** el ambiente queda descrito como código (Dockerfile, compose) y versionado en Git junto
  con los scripts y el SQL, por lo que cada resultado se puede asociar a un estado exacto del código.
- **Aislamiento:** no se contamina el sistema del usuario con librerías, y los datos se montan como volumen,
  separados del código (los datos no van a Git).
