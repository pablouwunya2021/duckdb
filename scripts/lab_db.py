"""Utilidades compartidas para conectarse a DuckDB y ejecutar los archivos SQL.

Todas las herramientas del proyecto (run_sql.py, notebooks, benchmark, tablero)
usan este modulo para que las vistas sobre Parquet se definan en un solo lugar:
sql/00_vistas.sql.

Formato de los archivos SQL documentados:

    -- name: q3_01_cantidad_archivos
    -- objetivo: Determinar cuantos archivos Parquet hay disponibles.
    -- fuente: data/raw/*/*/*.parquet
    SELECT ...;

Cada bloque que empieza con `-- name:` es una consulta con nombre. Las lineas
`-- clave: valor` inmediatamente despues son metadatos. Las sentencias que no
tienen nombre (p. ej. CREATE VIEW) se ejecutan sin documentarse.
"""

from __future__ import annotations

import re
import time
from dataclasses import dataclass, field
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parent.parent
DIR_SQL = RAIZ / "sql"
VISTAS = DIR_SQL / "00_vistas.sql"
DB_MATERIALIZADA = RAIZ / "data" / "processed" / "taxi.duckdb"

_META = re.compile(r"^--\s*(\w+)\s*:\s*(.*)$")


@dataclass
class Consulta:
    nombre: str
    sql: str
    meta: dict = field(default_factory=dict)


def parsear_sql(texto: str) -> tuple[list[str], list[Consulta]]:
    """Separa un archivo SQL en sentencias sin nombre y consultas con nombre."""
    sueltas: list[str] = []
    consultas: list[Consulta] = []
    actual: Consulta | None = None
    buffer: list[str] = []
    en_cabecera = False

    def cerrar():
        cuerpo = "\n".join(buffer).strip()
        if actual is not None:
            actual.sql = cuerpo.rstrip(";").strip()
            consultas.append(actual)
        elif cuerpo:
            sueltas.extend(s.strip() for s in _dividir(cuerpo) if s.strip())

    for linea in texto.splitlines():
        m = _META.match(linea.strip())
        if m and m.group(1) == "name":
            cerrar()
            actual, buffer, en_cabecera = Consulta(m.group(2).strip(), ""), [], True
            continue
        if actual is not None and en_cabecera and m:
            actual.meta[m.group(1)] = (actual.meta.get(m.group(1), "") + " " + m.group(2)).strip()
            continue
        en_cabecera = False
        buffer.append(linea)
    cerrar()
    return sueltas, consultas


def _dividir(sql: str) -> list[str]:
    """Divide sentencias por ';' al final de linea (suficiente para nuestros archivos)."""
    return re.split(r";\s*(?:\n|$)", sql)


def leer_sql(ruta: str | Path) -> tuple[list[str], list[Consulta]]:
    return parsear_sql(Path(ruta).read_text())


def conectar(db: str | Path | None = None, read_only: bool = False,
             vistas: bool = True, threads: int | None = None) -> duckdb.DuckDBPyConnection:
    """Abre una conexion (en memoria por defecto) con el directorio de trabajo en la raiz.

    Las rutas de las vistas son relativas (data/raw/...), por eso se fija
    file_search_path a la raiz del proyecto.
    """
    con = duckdb.connect(str(db) if db else ":memory:", read_only=read_only)
    con.execute(f"SET file_search_path = '{RAIZ.as_posix()}'")
    if threads:
        con.execute(f"SET threads = {int(threads)}")
    if vistas and not read_only:
        sueltas, _ = leer_sql(VISTAS)
        for sentencia in sueltas:
            con.execute(sentencia)
    return con


def ejecutar(con: duckdb.DuckDBPyConnection, sql: str):
    """Ejecuta una consulta y devuelve (DataFrame, segundos)."""
    inicio = time.perf_counter()
    df = con.execute(sql).df()
    return df, time.perf_counter() - inicio


def consulta(nombre: str, archivo: str | Path) -> Consulta:
    """Busca una consulta por nombre dentro de un archivo SQL."""
    _, consultas = leer_sql(archivo)
    for c in consultas:
        if c.nombre == nombre:
            return c
    raise KeyError(f"{nombre} no esta en {archivo}")


def df_a_markdown(df, max_filas: int = 30) -> str:
    """Convierte un DataFrame en tabla Markdown sin dependencias externas."""
    if df.empty:
        return "_(sin filas)_"
    recorte = df.head(max_filas)

    sin_miles = {c for c in recorte.columns if any(k in str(c).lower() for k in ("anio", "year", "mes", "hora", "dow"))}

    def fmt(v, col=None):
        if v is None or (isinstance(v, float) and v != v):
            return "NULL"
        if isinstance(v, float):
            return f"{v:,.4f}".rstrip("0").rstrip(".") if abs(v) < 1e15 else f"{v:.3e}"
        if isinstance(v, int):
            return str(v) if col in sin_miles else f"{v:,}"
        return str(v).replace("|", "\\|").replace("\n", " ")

    filas = ["| " + " | ".join(map(str, recorte.columns)) + " |",
             "|" + "|".join("---" for _ in recorte.columns) + "|"]
    for registro in recorte.itertuples(index=False):
        filas.append("| " + " | ".join(fmt(v.item() if hasattr(v, "item") else v, col)
                                      for v, col in zip(registro, recorte.columns)) + " |")
    if len(df) > max_filas:
        filas.append(f"\n_... {len(df) - max_filas} filas mas no mostradas ({len(df)} en total)_")
    return "\n".join(filas)
