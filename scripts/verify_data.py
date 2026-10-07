#!/usr/bin/env python3
"""Verifica que el conjunto de datos descargado este completo y sea legible.

Para cada archivo en data/raw/<tipo>/<anio>/*.parquet:
  1. Comprueba que DuckDB pueda leer los metadatos Parquet (archivo no corrupto).
  2. Obtiene el numero de filas desde los metadatos (sin escanear los datos).
  3. Revisa que no falten meses entre enero y el ultimo mes publicado
     (huecos en la secuencia indican descargas faltantes).
  4. Compara el inventario local con el manifiesto generado por download_data.py.

Uso:
    python scripts/verify_data.py
    python scripts/verify_data.py --salida docs/inventario_datos.md

Devuelve codigo 1 si encuentra archivos ilegibles o meses faltantes.
"""

import argparse
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

import duckdb

DIR_RAW = Path("data/raw")
MANIFIESTO = DIR_RAW / "manifest.csv"
PATRON = re.compile(r"(?P<tipo>yellow|green)_tripdata_(?P<anio>\d{4})-(?P<mes>\d{2})\.parquet$")


def inventario_local() -> list[dict]:
    con = duckdb.connect()
    filas = []
    for ruta in sorted(DIR_RAW.glob("*/*/*.parquet")):
        m = PATRON.search(ruta.name)
        if not m:
            continue
        fila = {"tipo": m["tipo"], "anio": int(m["anio"]), "mes": int(m["mes"]),
                "archivo": ruta.as_posix(), "bytes": ruta.stat().st_size,
                "filas": None, "row_groups": None, "ok": False, "error": ""}
        try:
            fila["filas"], fila["row_groups"] = con.execute(
                "SELECT num_rows, num_row_groups FROM parquet_file_metadata(?)", [str(ruta)]
            ).fetchone()
            fila["ok"] = True
        except duckdb.Error as error:
            fila["error"] = str(error).splitlines()[0]
        filas.append(fila)
    return filas


def meses_faltantes(filas: list[dict]) -> list[str]:
    """Meses ausentes entre enero y el ultimo mes disponible de cada tipo/anio."""
    por_grupo = defaultdict(set)
    for f in filas:
        por_grupo[(f["tipo"], f["anio"])].add(f["mes"])
    faltantes = []
    for (tipo, anio), meses in sorted(por_grupo.items()):
        for mes in range(1, max(meses) + 1):
            if mes not in meses:
                faltantes.append(f"{tipo} {anio}-{mes:02d}")
    return faltantes


def no_publicados_en_manifiesto() -> set[str]:
    if not MANIFIESTO.exists():
        return set()
    with MANIFIESTO.open() as archivo:
        return {f"{r['tipo']} {r['anio']}-{int(r['mes']):02d}"
                for r in csv.DictReader(archivo) if r["estado"] == "no_publicado"}


def escribir_markdown(filas: list[dict], salida: Path) -> None:
    resumen = defaultdict(lambda: {"archivos": 0, "filas": 0, "bytes": 0, "meses": []})
    for f in filas:
        r = resumen[(f["tipo"], f["anio"])]
        r["archivos"] += 1
        r["filas"] += f["filas"] or 0
        r["bytes"] += f["bytes"]
        r["meses"].append(f["mes"])

    lineas = ["# Inventario de datos descargados", "",
              "Generado por `python scripts/verify_data.py --salida docs/inventario_datos.md`.", "",
              "## Resumen por tipo y anio", "",
              "| tipo | anio | archivos | meses | filas | tamanio (MiB) |",
              "|---|---|---:|---|---:|---:|"]
    for (tipo, anio), r in sorted(resumen.items()):
        meses = f"{min(r['meses']):02d}-{max(r['meses']):02d}"
        lineas.append(f"| {tipo} | {anio} | {r['archivos']} | {meses} | {r['filas']:,} | {r['bytes'] / 2**20:,.1f} |")
    total_filas = sum(r["filas"] for r in resumen.values())
    total_bytes = sum(r["bytes"] for r in resumen.values())
    lineas.append(f"| **total** | | **{len(filas)}** | | **{total_filas:,}** | **{total_bytes / 2**20:,.1f}** |")
    lineas += ["", "## Detalle por archivo", "",
               "| archivo | filas | row groups | MiB | legible |", "|---|---:|---:|---:|---|"]
    for f in filas:
        lineas.append(f"| `{f['archivo']}` | {f['filas'] or 0:,} | {f['row_groups'] or 0} | "
                      f"{f['bytes'] / 2**20:.1f} | {'si' if f['ok'] else 'NO: ' + f['error']} |")
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text("\n".join(lineas) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Verifica el conjunto de datos descargado.")
    parser.add_argument("--salida", type=Path, help="escribe el inventario en Markdown")
    argumentos = parser.parse_args()

    filas = inventario_local()
    ilegibles = [f for f in filas if not f["ok"]]
    faltantes = meses_faltantes(filas)
    pendientes = no_publicados_en_manifiesto()

    print(f"{'tipo':<7}{'anio':>5}{'mes':>5}{'filas':>14}{'MiB':>9}  estado")
    for f in filas:
        estado = "ok" if f["ok"] else f"ILEGIBLE ({f['error']})"
        print(f"{f['tipo']:<7}{f['anio']:>5}{f['mes']:>5}{(f['filas'] or 0):>14,}"
              f"{f['bytes'] / 2**20:>9.1f}  {estado}")

    print("\n" + "=" * 60)
    print(f"  archivos encontrados : {len(filas)}")
    print(f"  filas totales        : {sum(f['filas'] or 0 for f in filas):,}")
    print(f"  archivos ilegibles   : {len(ilegibles)}")
    print(f"  meses faltantes      : {len(faltantes)} {', '.join(faltantes)}")
    if pendientes:
        print(f"  no publicados (TLC)  : {len(pendientes)} {', '.join(sorted(pendientes))}")
    print("=" * 60)

    if argumentos.salida:
        escribir_markdown(filas, argumentos.salida)
        print(f"inventario escrito en {argumentos.salida}")

    return 1 if ilegibles or faltantes else 0


if __name__ == "__main__":
    sys.exit(main())
