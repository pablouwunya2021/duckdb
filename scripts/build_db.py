#!/usr/bin/env python3
"""Materializa los datos en una base DuckDB: data/processed/taxi.duckdb.

Crea, a partir de las vistas sobre Parquet de sql/00_vistas.sql:
  - tabla  trips        : todos los viajes (yellow + green, todos los anios descargados)
  - tabla  zones        : tabla de zonas de la TLC
  - vista  trips_clean  : mismas reglas de calidad del Ejercicio 3, pero sobre la tabla
  - tablas de indicadores (ind_*) definidas en sql/07_indicadores.sql, si existe,
    para que Metabase consulte agregados pequenos en lugar de 100 M de filas.

La base se reconstruye completa en cada ejecucion (es un derivado de data/raw).
Uso:
    python scripts/build_db.py
    python scripts/build_db.py --sin-indicadores
    python scripts/build_db.py --memoria 2GB      # limite de memoria de DuckDB

Memoria: Metabase y Jupyter comparten la memoria de la VM de Docker. Sin limite,
DuckDB intenta usar el 80% de la RAM y el contenedor puede terminar por falta de
memoria (exit 137) con 120 M de filas. Por eso se fija memory_limit (por defecto
3GB), se limitan los hilos a 4 (cada hilo mantiene buffers de lectura de Parquet
que no cuentan dentro de memory_limit), se desactiva preserve_insertion_order (permite procesar en streaming) y se
usa data/processed/tmp como directorio de derrame a disco.
"""

import argparse
import sys
import time
from pathlib import Path

import duckdb

import lab_db

INDICADORES = lab_db.DIR_SQL / "07_indicadores.sql"


def configurar_memoria(con, memoria: str, hilos: int = 4) -> None:
    tmp = lab_db.RAIZ / "data" / "processed" / "tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    con.execute(f"SET memory_limit = '{memoria}'")
    con.execute(f"SET threads = {int(hilos)}")
    con.execute("SET preserve_insertion_order = false")
    con.execute(f"SET temp_directory = '{tmp.as_posix()}'")


def construir(destino: Path, con_indicadores: bool = True, memoria: str = "3GB", hilos: int = 4) -> dict:
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_suffix(".tmp.duckdb")
    temporal.unlink(missing_ok=True)

    con = lab_db.conectar()  # en memoria, con vistas sobre Parquet
    configurar_memoria(con, memoria, hilos)
    definicion_limpia = con.execute(
        "SELECT sql FROM duckdb_views() WHERE view_name = 'trips_clean'"
    ).fetchone()[0]

    con.execute(f"ATTACH '{temporal.as_posix()}' AS destino")
    tiempos = {}

    inicio = time.perf_counter()
    con.execute("CREATE TABLE destino.trips AS SELECT * FROM trips")
    tiempos["tabla_trips_s"] = time.perf_counter() - inicio

    con.execute("CREATE TABLE destino.zones AS SELECT * FROM zones")
    con.execute("DETACH destino")
    con.close()

    # Los indicadores se calculan desde las vistas sobre Parquet y se escriben en la
    # base. Calcularlos sobre la tabla recien creada agotaba la memoria con 120 M de
    # filas (los agregados median/quantile mantienen todos los valores en memoria y
    # la tabla sin comprimir ocupa mas que el Parquet), mientras que el lector de
    # Parquet procesa por row groups.
    # Se usa una conexion nueva para liberar la memoria de la carga anterior.
    if con_indicadores and INDICADORES.exists():
        con = lab_db.conectar()
        configurar_memoria(con, memoria, hilos)
        con.execute(f"ATTACH '{temporal.as_posix()}' AS destino")
        inicio = time.perf_counter()
        sueltas, consultas = lab_db.leer_sql(INDICADORES)
        for sentencia in sueltas:
            con.execute(sentencia)
        for c in consultas:
            try:
                con.execute(f"CREATE OR REPLACE TABLE destino.{c.nombre} AS {c.sql}")
            except duckdb.Error as error:
                raise RuntimeError(f"error al crear el indicador {c.nombre}: {error}") from error
        tiempos["indicadores_s"] = time.perf_counter() - inicio
        con.execute("DETACH destino")
        con.close()

    db = duckdb.connect(temporal.as_posix())
    configurar_memoria(db, memoria, hilos)
    # La definicion de trips_clean referencia `trips`; dentro de la base es la tabla.
    db.execute(definicion_limpia)

    filas = db.execute("SELECT count(*) FROM trips").fetchone()[0]
    db.execute("CHECKPOINT")
    db.close()
    temporal.replace(destino)

    return {"filas": filas, "bytes": destino.stat().st_size, **tiempos}


def main() -> int:
    parser = argparse.ArgumentParser(description="Crea data/processed/taxi.duckdb")
    parser.add_argument("--destino", type=Path, default=lab_db.DB_MATERIALIZADA)
    parser.add_argument("--sin-indicadores", action="store_true")
    parser.add_argument("--memoria", default="3GB", help="memory_limit de DuckDB (por defecto 3GB)")
    parser.add_argument("--hilos", type=int, default=4, help="hilos de DuckDB durante la carga (por defecto 4)")
    args = parser.parse_args()

    inicio = time.perf_counter()
    r = construir(args.destino, not args.sin_indicadores, args.memoria, args.hilos)
    print(f"base creada en {args.destino}")
    print(f"  filas en trips      : {r['filas']:,}")
    print(f"  tamanio             : {r['bytes'] / 2**30:.2f} GiB")
    print(f"  CREATE TABLE trips  : {r['tabla_trips_s']:.1f} s")
    if "indicadores_s" in r:
        print(f"  tablas de indicadores: {r['indicadores_s']:.1f} s")
    print(f"  total               : {time.perf_counter() - inicio:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
