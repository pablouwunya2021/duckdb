#!/usr/bin/env python3
"""Benchmark: consultar Parquet directamente vs. tabla materializada en DuckDB.

Para cada escala de datos (cantidad de archivos/filas):
  1. Estrategia "parquet": conexion en memoria con las vistas de sql/00_vistas.sql
     apuntando solo a los archivos de esa escala.
  2. Estrategia "tabla": se materializa la misma vista `trips` en
     data/processed/bench/<escala>.duckdb (se mide el tiempo de carga y el tamanio)
     y se define trips_clean con las mismas reglas.
  3. Se ejecutan las consultas de sql/06_benchmark.sql en ambas estrategias:
     1 ejecucion "primera" (conexion nueva) + N repeticiones; se reporta la mediana.
  4. Se verifica que ambas estrategias devuelvan el mismo resultado.

Salidas:
  docs/resultados/06_benchmark_resultados.csv  (todas las mediciones)
  docs/resultados/06_benchmark.md          (tablas resumen)
  docs/img/bench_*.png                     (graficas)

Uso:
    python scripts/benchmark.py                    # todas las escalas, 5 repeticiones
    python scripts/benchmark.py --repeticiones 3 --escalas 1_mes todos
"""

import argparse
import statistics
import sys
import time
from datetime import datetime
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

import lab_db

SQL_BENCH = lab_db.DIR_SQL / "06_benchmark.sql"
DIR_BENCH = lab_db.RAIZ / "data" / "processed" / "bench"
CSV = lab_db.RAIZ / "docs" / "resultados" / "06_benchmark_resultados.csv"
REPORTE = lab_db.RAIZ / "docs" / "resultados" / "06_benchmark.md"
DIR_IMG = lab_db.RAIZ / "docs" / "img"


def archivos_disponibles() -> pd.DataFrame:
    filas = []
    for ruta in sorted((lab_db.RAIZ / "data" / "raw").glob("*/*/*.parquet")):
        tipo, anio = ruta.parent.parent.name, int(ruta.parent.name)
        mes = int(ruta.stem[-2:])
        filas.append({"tipo": tipo, "anio": anio, "mes": mes, "ruta": ruta.relative_to(lab_db.RAIZ).as_posix(),
                      "bytes": ruta.stat().st_size})
    return pd.DataFrame(filas)


def definir_escalas(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    """Escalas crecientes, calculadas segun los archivos disponibles."""
    ultimo = df.anio.max()
    primero = df.anio.min()
    escalas = {
        "1_mes": df[(df.anio == ultimo) & (df.mes == 1)],
        "1_trimestre": df[(df.anio == ultimo) & (df.mes <= 3)],
        f"anio_{primero}": df[df.anio == primero],
        "todos": df,
    }
    return {k: v for k, v in escalas.items() if not v.empty}


def a_dict(archivos: pd.DataFrame) -> dict[str, list[str]]:
    return {t: archivos[archivos.tipo == t].ruta.tolist() for t in ("yellow", "green")}


def materializar(nombre: str, archivos: pd.DataFrame) -> tuple[Path, float]:
    """Crea la base con la tabla trips de la escala. Devuelve (ruta, segundos de carga)."""
    DIR_BENCH.mkdir(parents=True, exist_ok=True)
    destino = DIR_BENCH / f"{nombre}.duckdb"
    destino.unlink(missing_ok=True)
    con = lab_db.conectar(archivos=a_dict(archivos))
    definicion_limpia = con.execute(
        "SELECT sql FROM duckdb_views() WHERE view_name = 'trips_clean'").fetchone()[0]
    con.execute(f"ATTACH '{destino.as_posix()}' AS b")
    inicio = time.perf_counter()
    con.execute("CREATE TABLE b.trips AS SELECT * FROM trips")
    con.execute("CREATE TABLE b.zones AS SELECT * FROM zones")
    con.execute("DETACH b")
    segundos = time.perf_counter() - inicio
    con.close()
    db = lab_db.conectar(destino)
    db.execute(definicion_limpia)
    db.execute("CHECKPOINT")
    db.close()
    return destino, segundos


def medir(con, sql: str, repeticiones: int):
    inicio = time.perf_counter()
    df = con.execute(sql).df()
    primera = time.perf_counter() - inicio
    tiempos = []
    for _ in range(repeticiones):
        inicio = time.perf_counter()
        con.execute(sql).fetchall()
        tiempos.append(time.perf_counter() - inicio)
    return df, primera, tiempos


def iguales(a: pd.DataFrame, b: pd.DataFrame) -> bool:
    if a.shape != b.shape:
        return False
    a, b = a.reset_index(drop=True), b.reset_index(drop=True)
    for col in a.columns:
        if pd.api.types.is_float_dtype(a[col]):
            cerca = (a[col] - b[col]).abs() <= 1e-6 * (a[col].abs() + 1)
            if not (cerca | (a[col].isna() & b[col].isna())).all():
                return False
        elif not a[col].equals(b[col]):
            return False
    return True


def graficar(res: pd.DataFrame, cargas: pd.DataFrame) -> None:
    DIR_IMG.mkdir(parents=True, exist_ok=True)
    piv = res.pivot_table(index=["escala", "filas"], columns="estrategia", values="mediana_s", aggfunc="sum").reset_index()
    piv = piv.sort_values("filas")

    fig, axes = plt.subplots(1, 2, figsize=(13, 4))
    ax = axes[0]
    ax.plot(piv.filas / 1e6, piv.parquet, marker="o", label="Parquet directo")
    ax.plot(piv.filas / 1e6, piv.tabla, marker="s", label="Tabla DuckDB")
    ax.set_xlabel("millones de filas"); ax.set_ylabel("segundos (suma de medianas, 8 consultas)")
    ax.set_title("Tiempo total del conjunto de consultas vs volumen"); ax.legend(); ax.grid(alpha=0.3)

    ax = axes[1]
    todos = res[res.escala == res.loc[res.filas.idxmax(), "escala"]]
    p = todos.pivot(index="consulta", columns="estrategia", values="mediana_s")
    p[["parquet", "tabla"]].plot.barh(ax=ax)
    ax.set_xlabel("segundos (mediana)"); ax.set_title(f"Por consulta - escala '{todos.escala.iloc[0]}'")
    fig.tight_layout(); fig.savefig(DIR_IMG / "bench_tiempos.png", dpi=110); plt.close(fig)

    fig, ax = plt.subplots(figsize=(7, 3.5))
    sp = res.pivot_table(index="consulta", columns="escala", values="speedup")
    sp = sp[[e for e in cargas.sort_values("filas").escala if e in sp.columns]]
    sp.plot.bar(ax=ax); ax.axhline(1, color="black", lw=0.8)
    ax.set_ylabel("veces mas rapida la tabla"); ax.set_title("Speedup tabla vs Parquet (mediana)")
    fig.tight_layout(); fig.savefig(DIR_IMG / "bench_speedup.png", dpi=110); plt.close(fig)


def reporte(res: pd.DataFrame, cargas: pd.DataFrame, repeticiones: int) -> None:
    lineas = ["# Resultados del benchmark Parquet vs tabla DuckDB", "",
              f"Generado con `python scripts/benchmark.py --repeticiones {repeticiones}` el "
              f"{datetime.now():%Y-%m-%d %H:%M}. DuckDB con {res.threads.iloc[0]} hilos. "
              "`primera_s` = primera ejecucion en una conexion nueva; `mediana_s` = mediana de las "
              f"{repeticiones} repeticiones siguientes. `speedup` = mediana Parquet / mediana tabla.", "",
              "## Costo de materializar (por escala)", "",
              lab_db.df_a_markdown(cargas, 50), "",
              "## Tiempo por consulta, escala y estrategia", ""]
    tabla = res.pivot_table(index=["escala", "filas", "consulta"], columns="estrategia",
                            values=["primera_s", "mediana_s"]).round(4)
    tabla.columns = [f"{e}_{m}" for m, e in tabla.columns]
    tabla = tabla.reset_index().sort_values(["filas", "consulta"])
    tabla["speedup"] = (tabla.parquet_mediana_s / tabla.tabla_mediana_s).round(2)
    tabla = tabla[["escala", "filas", "consulta", "parquet_primera_s", "parquet_mediana_s",
                   "tabla_primera_s", "tabla_mediana_s", "speedup"]]
    lineas += [lab_db.df_a_markdown(tabla, 500), "",
               "## Resumen por escala (suma de medianas de las 8 consultas)", ""]
    resumen = res.pivot_table(index=["escala", "filas"], columns="estrategia", values="mediana_s", aggfunc="sum")
    resumen = resumen.reset_index().sort_values("filas")
    resumen["speedup"] = (resumen.parquet / resumen.tabla).round(2)
    resumen = resumen.merge(cargas[["escala", "carga_s"]], on="escala")
    ahorro = resumen.parquet - resumen.tabla
    resumen["ejecuciones_para_amortizar_carga"] = (resumen.carga_s / ahorro.where(ahorro > 0)).round(1)
    resumen = resumen.rename(columns={"parquet": "parquet_s", "tabla": "tabla_s"}).round(3)
    lineas += [lab_db.df_a_markdown(resumen, 50), "",
               f"Todas las consultas devolvieron el mismo resultado en ambas estrategias: "
               f"{'si' if res.resultado_igual.all() else 'NO'}.", "",
               "![tiempos](../img/bench_tiempos.png)", "", "![speedup](../img/bench_speedup.png)", ""]
    REPORTE.parent.mkdir(parents=True, exist_ok=True)
    REPORTE.write_text("\n".join(lineas))


def main() -> int:
    parser = argparse.ArgumentParser(description="Benchmark Parquet vs tabla DuckDB")
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--escalas", nargs="*", help="subconjunto de escalas a ejecutar")
    parser.add_argument("--limpiar", action="store_true", help="borra las bases de benchmark al final")
    args = parser.parse_args()

    _, consultas = lab_db.leer_sql(SQL_BENCH)
    escalas = definir_escalas(archivos_disponibles())
    if args.escalas:
        escalas = {k: v for k, v in escalas.items() if k in args.escalas}

    resultados, cargas = [], []
    for nombre, archivos in escalas.items():
        print(f"\n=== escala {nombre}: {len(archivos)} archivos ===")
        ruta_db, carga = materializar(nombre, archivos)
        con_pq = lab_db.conectar(archivos=a_dict(archivos))
        filas = con_pq.execute("SELECT count(*) FROM trips").fetchone()[0]
        con_pq.close()
        cargas.append({"escala": nombre, "archivos": len(archivos), "filas": filas,
                       "parquet_mib": round(archivos.bytes.sum() / 2**20, 1),
                       "tabla_mib": round(ruta_db.stat().st_size / 2**20, 1),
                       "carga_s": round(carga, 2)})
        print(f"  {filas:,} filas; CREATE TABLE {carga:.1f} s; "
              f"Parquet {archivos.bytes.sum() / 2**20:.0f} MiB vs base {ruta_db.stat().st_size / 2**20:.0f} MiB")

        for c in consultas:
            salidas = {}
            for estrategia in ("parquet", "tabla"):
                # conexion nueva por consulta y estrategia: la "primera" ejecucion
                # incluye la lectura de metadatos/plan sin cache de DuckDB
                con = (lab_db.conectar(archivos=a_dict(archivos)) if estrategia == "parquet"
                       else lab_db.conectar(ruta_db, read_only=True))
                hilos = con.execute("SELECT current_setting('threads')").fetchone()[0]
                df, primera, tiempos = medir(con, c.sql, args.repeticiones)
                con.close()
                salidas[estrategia] = df
                resultados.append({"escala": nombre, "filas": filas, "consulta": c.nombre,
                                   "estrategia": estrategia, "primera_s": primera,
                                   "mediana_s": statistics.median(tiempos), "min_s": min(tiempos),
                                   "max_s": max(tiempos), "repeticiones": args.repeticiones,
                                   "threads": hilos})
            igual = iguales(salidas["parquet"], salidas["tabla"])
            for r in resultados[-2:]:
                r["resultado_igual"] = igual
            pq, tb = resultados[-2]["mediana_s"], resultados[-1]["mediana_s"]
            print(f"  {c.nombre:<28} parquet {pq:7.3f} s | tabla {tb:7.3f} s | x{pq / tb:5.1f} "
                  f"| {'ok' if igual else 'RESULTADOS DISTINTOS'}")

        if args.limpiar:
            ruta_db.unlink(missing_ok=True)

    res = pd.DataFrame(resultados)
    sp = res.pivot_table(index=["escala", "consulta"], columns="estrategia", values="mediana_s")
    res = res.merge((sp.parquet / sp.tabla).rename("speedup").reset_index(), on=["escala", "consulta"])
    cargas = pd.DataFrame(cargas)
    CSV.parent.mkdir(parents=True, exist_ok=True)
    res.to_csv(CSV, index=False)
    reporte(res, cargas, args.repeticiones)
    graficar(res, cargas)
    print(f"\nresultados: {CSV}\nreporte   : {REPORTE}")
    return 0 if res.resultado_igual.all() else 1


if __name__ == "__main__":
    sys.exit(main())
