#!/usr/bin/env python3
"""Ejecuta archivos SQL documentados y genera un reporte Markdown con los resultados.

Para cada consulta con nombre (`-- name:`) el reporte incluye: objetivo,
fuente, SQL, tiempo de ejecucion y resultado. Asi la documentacion de las
consultas (Ejercicios 3.8, 4.3, 5.8, 7.7, 8.7) se regenera siempre a partir del
SQL versionado y de los datos actuales.

Uso:
    python scripts/run_sql.py sql/03_exploracion.sql
    python scripts/run_sql.py sql/04_eda.sql --salida docs/resultados/04_eda.md
    python scripts/run_sql.py sql/07_indicadores.sql --db data/processed/taxi.duckdb
"""

import argparse
import sys
from datetime import datetime
from pathlib import Path

import lab_db


def main() -> int:
    parser = argparse.ArgumentParser(description="Ejecuta y documenta consultas SQL.")
    parser.add_argument("archivo", type=Path, help="archivo .sql con consultas `-- name:`")
    parser.add_argument("--salida", type=Path, help="reporte Markdown (por defecto docs/resultados/<archivo>.md)")
    parser.add_argument("--db", type=Path, help="base DuckDB a usar (por defecto: en memoria, sobre Parquet)")
    parser.add_argument("--solo", nargs="*", help="ejecutar solo estas consultas")
    parser.add_argument("--max-filas", type=int, default=30)
    args = parser.parse_args()

    salida = args.salida or lab_db.RAIZ / "docs" / "resultados" / f"{args.archivo.stem}.md"
    con = lab_db.conectar(args.db, read_only=False)
    sueltas, consultas = lab_db.leer_sql(args.archivo)
    for sentencia in sueltas:
        con.execute(sentencia)

    origen = f"base `{args.db}`" if args.db else "archivos Parquet (vistas de `sql/00_vistas.sql`)"
    lineas = [f"# Resultados de `{args.archivo.as_posix()}`", "",
              f"Generado con `python scripts/run_sql.py {args.archivo.as_posix()}` "
              f"el {datetime.now():%Y-%m-%d %H:%M}. Origen de datos: {origen}.", ""]

    for c in consultas:
        if args.solo and c.nombre not in args.solo:
            continue
        print(f"-> {c.nombre}", end=" ", flush=True)
        df, segundos = lab_db.ejecutar(con, c.sql)
        print(f"({segundos:.2f} s, {len(df)} filas)")
        lineas += [f"## {c.nombre}", ""]
        if "pregunta" in c.meta:
            lineas += [f"**Pregunta:** {c.meta['pregunta']}", ""]
        lineas += [f"**Objetivo:** {c.meta.get('objetivo', '-')}", "",
                   f"**Fuente:** `{c.meta.get('fuente', '-')}`", "",
                   "```sql", c.sql + ";", "```", "",
                   f"**Resultado** ({len(df)} filas, {segundos:.2f} s):", "",
                   lab_db.df_a_markdown(df, args.max_filas), ""]
        if "decision" in c.meta:
            lineas += [f"**Decision / interpretacion:** {c.meta['decision']}", ""]

    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text("\n".join(lineas))
    print(f"reporte escrito en {salida}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
