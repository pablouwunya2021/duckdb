#!/usr/bin/env python3
"""Configura Metabase y construye el tablero de indicadores de forma reproducible.

Pasos (idempotentes; se puede volver a ejecutar despues de reconstruir la base):
  1. Si Metabase no esta inicializado, crea un usuario administrador LOCAL.
     Las credenciales se leen de MB_EMAIL / MB_PASSWORD o, si no existen, se
     generan y se guardan en data/processed/metabase_admin.json (fuera de Git).
  2. Registra (o actualiza) la conexion DuckDB a /workspace/data/processed/taxi.duckdb
     en modo read_only y sincroniza el esquema.
  3. Crea/actualiza una pregunta (card) por indicador usando SQL nativo sobre las
     tablas ind_* (sql/07_indicadores.sql, materializadas por build_db.py).
  4. Crea/actualiza el tablero "Taxis NYC - Indicadores" con todas las preguntas.
  5. Habilita un enlace publico de solo lectura del tablero y lo imprime.

Uso (dentro del contenedor lab, Metabase es accesible como http://metabase:3000):
    python scripts/build_db.py
    python scripts/setup_metabase.py
"""

import json
import os
import secrets
import sys
import time
from pathlib import Path

import requests

import lab_db

MB_URL = os.environ.get("MB_URL", "http://metabase:3000").rstrip("/")
CREDENCIALES = lab_db.RAIZ / "data" / "processed" / "metabase_admin.json"
RUTA_DB_METABASE = "/workspace/data/processed/taxi.duckdb"   # ruta dentro del contenedor metabase
NOMBRE_DB = "NYC Taxi (DuckDB)"
NOMBRE_COLECCION = "Lab 8 - DuckDB"
NOMBRE_TABLERO = "Taxis NYC - Indicadores"

ULTIMO_ANIO = "(SELECT max(anio) FROM ind_resumen_anual)"

# ---------------------------------------------------------------------------
# Definicion de las preguntas del tablero. Cada una se apoya en una tabla ind_*
# (la consulta de origen esta documentada en sql/07_indicadores.sql).
# ---------------------------------------------------------------------------
CARDS = [
    # --- KPIs del ultimo anio disponible (enero-agosto) ---
    {"clave": "kpi_viajes", "nombre": "KPI - Viajes/dia yellow (ultimo anio)", "display": "scalar",
     "sql": f"SELECT viajes_por_dia FROM ind_resumen_anual WHERE taxi_type = 'yellow' AND anio = {ULTIMO_ANIO}",
     "viz": {"scalar.decimals": 0}},
    {"clave": "kpi_total", "nombre": "KPI - USD por viaje yellow", "display": "scalar",
     "sql": f"SELECT total_promedio_usd FROM ind_resumen_anual WHERE taxi_type = 'yellow' AND anio = {ULTIMO_ANIO}",
     "viz": {"scalar.prefix": "$", "scalar.decimals": 2}},
    {"clave": "kpi_velocidad", "nombre": "KPI - Velocidad mediana yellow", "display": "scalar",
     "sql": f"SELECT velocidad_mediana_mph FROM ind_resumen_anual WHERE taxi_type = 'yellow' AND anio = {ULTIMO_ANIO}",
     "viz": {"scalar.suffix": " mph", "scalar.decimals": 1}},
    {"clave": "kpi_propina", "nombre": "KPI - Propina tarjeta yellow", "display": "scalar",
     "sql": f"SELECT propina_pct_tarjeta FROM ind_resumen_anual WHERE taxi_type = 'yellow' AND anio = {ULTIMO_ANIO}",
     "viz": {"scalar.suffix": " %", "scalar.decimals": 1}},
    # --- Indicadores ---
    {"clave": "i1", "nombre": "I1 - Viajes por dia por mes (Q1)", "display": "line",
     "sql": "SELECT periodo, taxi_type, viajes_por_dia FROM ind_demanda_mensual ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "taxi_type"], "graph.metrics": ["viajes_por_dia"],
             "graph.x_axis.title_text": "mes", "graph.y_axis.title_text": "viajes por dia (yellow)",
             "series_settings": {"green": {"axis": "right", "title": "green (eje der.)"}}}},
    {"clave": "i1b", "nombre": "I1b - Ingresos mensuales USD (Q2)", "display": "bar",
     "sql": "SELECT periodo, taxi_type, ingresos_usd FROM ind_demanda_mensual ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "taxi_type"], "graph.metrics": ["ingresos_usd"],
             "graph.y_axis.title_text": "USD (yellow)",
             "series_settings": {"green": {"axis": "right", "title": "green (eje der.)"}}}},
    {"clave": "i2", "nombre": "I2 - Ingreso promedio por viaje USD (Q3)", "display": "line",
     "sql": "SELECT periodo, taxi_type, total_promedio_usd FROM ind_ingreso_por_viaje ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "taxi_type"], "graph.metrics": ["total_promedio_usd"],
             "graph.y_axis.title_text": "USD por viaje"}},
    {"clave": "i3", "nombre": "I3 - Distribucion horaria de la demanda, % del dia (Q4)", "display": "line",
     "sql": "SELECT hora, taxi_type || ' - ' || tipo_dia AS serie, pct_viajes FROM ind_demanda_horaria ORDER BY hora",
     "viz": {"graph.dimensions": ["hora", "serie"], "graph.metrics": ["pct_viajes"],
             "graph.x_axis.title_text": "hora del dia", "graph.y_axis.title_text": "% de viajes"}},
    {"clave": "i4", "nombre": "I4 - Velocidad mediana por hora, entre semana (Q5)", "display": "line",
     "sql": "SELECT hora, CAST(anio AS VARCHAR) AS anio, velocidad_mediana_mph FROM ind_velocidad_horaria ORDER BY hora",
     "viz": {"graph.dimensions": ["hora", "anio"], "graph.metrics": ["velocidad_mediana_mph"],
             "graph.x_axis.title_text": "hora del dia", "graph.y_axis.title_text": "mph"}},
    {"clave": "i5", "nombre": "I5 - Metodo de pago, % de viajes yellow (Q6)", "display": "bar",
     "sql": "SELECT periodo, metodo_pago, pct FROM ind_mix_pago WHERE taxi_type = 'yellow' ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "metodo_pago"], "graph.metrics": ["pct"],
             "stackable.stack_type": "stacked", "graph.y_axis.title_text": "% de viajes"}},
    {"clave": "i6", "nombre": "I6 - Propina con tarjeta, % de la tarifa (Q7)", "display": "line",
     "sql": "SELECT periodo, taxi_type, propina_pct_tarifa FROM ind_propina_tarjeta ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "taxi_type"], "graph.metrics": ["propina_pct_tarifa"],
             "graph.y_axis.title_text": "% de la tarifa"}},
    {"clave": "i7", "nombre": "I7 - Aeropuertos: % de viajes vs % de ingresos, yellow (Q8)", "display": "bar",
     "sql": ("SELECT CAST(anio AS VARCHAR) AS anio, pct_viajes AS \"% viajes\", pct_ingresos AS \"% ingresos\" "
             "FROM ind_aeropuertos WHERE taxi_type = 'yellow' AND segmento = 'aeropuerto' ORDER BY anio"),
     "viz": {"graph.dimensions": ["anio"], "graph.metrics": ["% viajes", "% ingresos"],
             "graph.show_values": True}},
    {"clave": "i8", "nombre": "I8 - Borough de origen, % de viajes (Q9)", "display": "row",
     "sql": "SELECT serie, borough, pct FROM ind_borough_origen ORDER BY serie",
     "viz": {"graph.dimensions": ["serie", "borough"], "graph.metrics": ["pct"],
             "stackable.stack_type": "stacked"}},
    {"clave": "i9", "nombre": "I9 - Cuota de congestion CBD: recaudacion mensual USD (Q10)", "display": "combo",
     "sql": ("SELECT periodo, sum(recaudacion_usd) AS recaudacion_usd, "
             "round(sum(pct_viajes_con_cuota * CASE WHEN taxi_type = 'yellow' THEN 1 ELSE 0 END), 2) AS pct_viajes_yellow_con_cuota "
             "FROM ind_cuota_congestion GROUP BY periodo ORDER BY periodo"),
     "viz": {"graph.dimensions": ["periodo"], "graph.metrics": ["recaudacion_usd", "pct_viajes_yellow_con_cuota"],
             "series_settings": {"recaudacion_usd": {"display": "bar"},
                                 "pct_viajes_yellow_con_cuota": {"display": "line", "axis": "right"}}}},
    {"clave": "i10", "nombre": "I10 - Calidad de datos: % validos y % sin datos de taximetro (Q11)", "display": "line",
     "sql": ("SELECT periodo, taxi_type || ' validos' AS serie, pct_validos AS pct FROM ind_calidad_datos "
             "UNION ALL SELECT periodo, taxi_type || ' sin taximetro', pct_sin_datos_taximetro FROM ind_calidad_datos "
             "ORDER BY periodo"),
     "viz": {"graph.dimensions": ["periodo", "serie"], "graph.metrics": ["pct"], "graph.y_axis.title_text": "%"}},
    {"clave": "i11", "nombre": "I11 - Origen de la solicitud, yellow (Q12)", "display": "bar",
     "sql": "SELECT periodo, origen, pct FROM ind_plataformas WHERE taxi_type = 'yellow' ORDER BY periodo",
     "viz": {"graph.dimensions": ["periodo", "origen"], "graph.metrics": ["pct"],
             "stackable.stack_type": "stacked", "graph.y_axis.title_text": "% de viajes"}},
    {"clave": "t1", "nombre": "Resumen anual comparable (enero-agosto) (Q13)", "display": "table",
     "sql": "SELECT CAST(anio AS VARCHAR) AS anio, * EXCLUDE (anio) FROM ind_resumen_anual ORDER BY taxi_type DESC, anio",
     "viz": {}},
]

TEXTO_ENCABEZADO = (
    "# Taxis de Nueva York - Indicadores (DuckDB + Parquet)\n"
    "Fuente: NYC TLC Trip Record Data (yellow y green). Datos procesados con DuckDB a partir de los archivos "
    "Parquet descargados por `scripts/download_data.py`; las tablas `ind_*` se generan con "
    "`scripts/build_db.py` desde `sql/07_indicadores.sql`. Los KPI comparan enero-agosto del ultimo anio."
)
TEXTO_NOTA = (
    "**Como leer el tablero.** I1-I2 miden volumen y precio; I3-I4 patrones horarios y congestion; I5-I6 pagos y "
    "propinas (solo tarjeta registra propina); I7-I8 geografia del servicio; I9 la cuota de congestion de "
    "Manhattan (desde ene-2025); I10 la confiabilidad del dato; I11 la participacion de plataformas (desde jun-2026). "
    "Interpretacion completa en `docs/07_indicadores.md` y `docs/08_analisis_completo.md`."
)

# Distribucion en la grilla de 24 columnas: (clave, fila, columna, ancho, alto)
LAYOUT = [
    ("texto_encabezado", 0, 0, 24, 3),
    ("kpi_viajes", 3, 0, 6, 3), ("kpi_total", 3, 6, 6, 3), ("kpi_velocidad", 3, 12, 6, 3), ("kpi_propina", 3, 18, 6, 3),
    ("i1", 6, 0, 12, 7), ("i1b", 6, 12, 12, 7),
    ("i2", 13, 0, 12, 7), ("i3", 13, 12, 12, 7),
    ("i4", 20, 0, 12, 7), ("i5", 20, 12, 12, 7),
    ("i6", 27, 0, 12, 7), ("i7", 27, 12, 12, 7),
    ("i8", 34, 0, 12, 7), ("i9", 34, 12, 12, 7),
    ("i10", 41, 0, 12, 7), ("i11", 41, 12, 12, 7),
    ("t1", 48, 0, 24, 6),
    ("texto_nota", 54, 0, 24, 3),
]


class Metabase:
    def __init__(self, url: str):
        self.url = url
        self.s = requests.Session()

    def req(self, metodo: str, ruta: str, **kw):
        r = self.s.request(metodo, f"{self.url}/api{ruta}", timeout=120, **kw)
        if not r.ok:
            raise RuntimeError(f"{metodo} {ruta} -> {r.status_code}: {r.text[:300]}")
        return r.json() if r.content else None


def credenciales() -> dict:
    if os.environ.get("MB_EMAIL") and os.environ.get("MB_PASSWORD"):
        return {"email": os.environ["MB_EMAIL"], "password": os.environ["MB_PASSWORD"]}
    if CREDENCIALES.exists():
        return json.loads(CREDENCIALES.read_text())
    datos = {"email": "admin@lab8.local", "password": secrets.token_urlsafe(18)}
    CREDENCIALES.parent.mkdir(parents=True, exist_ok=True)
    CREDENCIALES.write_text(json.dumps(datos, indent=2))
    CREDENCIALES.chmod(0o600)
    print(f"credenciales de administrador local generadas en {CREDENCIALES}")
    return datos


def esperar(mb: Metabase) -> dict:
    for _ in range(60):
        try:
            if mb.req("GET", "/health").get("status") == "ok":
                return mb.req("GET", "/session/properties")
        except (requests.RequestException, RuntimeError):
            pass
        time.sleep(3)
    raise RuntimeError(f"Metabase no responde en {MB_URL}")


def autenticar(mb: Metabase, props: dict) -> None:
    cred = credenciales()
    if not props.get("has-user-setup"):
        r = mb.req("POST", "/setup", json={
            "token": props["setup-token"],
            "user": {"email": cred["email"], "password": cred["password"],
                     "first_name": "Admin", "last_name": "Lab8", "site_name": "Lab 8 DuckDB"},
            "prefs": {"site_name": "Lab 8 DuckDB", "site_locale": "es", "allow_tracking": False},
        })
        print("Metabase inicializado")
    else:
        r = mb.req("POST", "/session", json={"username": cred["email"], "password": cred["password"]})
    mb.s.headers["X-Metabase-Session"] = r["id"]


def base_de_datos(mb: Metabase) -> int:
    detalles = {"database_file": RUTA_DB_METABASE, "read_only": True}
    existentes = mb.req("GET", "/database")
    existentes = existentes.get("data", existentes) if isinstance(existentes, dict) else existentes
    for db in existentes:
        if db["name"] == NOMBRE_DB:
            # Volver a guardar los detalles reinicia el pool de conexiones: necesario
            # cuando build_db.py reemplaza el archivo taxi.duckdb.
            mb.req("PUT", f"/database/{db['id']}", json={"details": detalles, "engine": "duckdb"})
            mb.req("POST", f"/database/{db['id']}/sync_schema")
            return db["id"]
    db = mb.req("POST", "/database", json={"engine": "duckdb", "name": NOMBRE_DB, "details": detalles,
                                           "is_full_sync": True})
    mb.req("POST", f"/database/{db['id']}/sync_schema")
    print(f"conexion '{NOMBRE_DB}' creada (id {db['id']})")
    return db["id"]


def coleccion(mb: Metabase) -> int:
    for c in mb.req("GET", "/collection"):
        if c.get("name") == NOMBRE_COLECCION and not c.get("archived"):
            return c["id"]
    return mb.req("POST", "/collection", json={"name": NOMBRE_COLECCION, "color": "#509EE3"})["id"]


def preguntas(mb: Metabase, db_id: int, col_id: int) -> dict[str, int]:
    actuales = {c["name"]: c["id"] for c in mb.req("GET", f"/collection/{col_id}/items?models=card")["data"]}
    ids = {}
    for c in CARDS:
        cuerpo = {
            "name": c["nombre"], "display": c["display"], "collection_id": col_id,
            "visualization_settings": c["viz"],
            "dataset_query": {"type": "native", "database": db_id, "native": {"query": c["sql"]}},
        }
        if c["nombre"] in actuales:
            ids[c["clave"]] = actuales[c["nombre"]]
            mb.req("PUT", f"/card/{ids[c['clave']]}", json=cuerpo)
        else:
            ids[c["clave"]] = mb.req("POST", "/card", json=cuerpo)["id"]
        # ejecutar una vez para validar el SQL y que Metabase guarde los metadatos
        r = mb.req("POST", f"/card/{ids[c['clave']]}/query")
        if r.get("status") != "completed":
            raise RuntimeError(f"la pregunta {c['nombre']} fallo: {r.get('error')}")
        print(f"  pregunta lista: {c['nombre']} ({r['row_count']} filas)")
    # archivar preguntas de ejecuciones anteriores que ya no forman parte del tablero
    vigentes = {c["nombre"] for c in CARDS}
    for nombre, card_id in actuales.items():
        if nombre not in vigentes:
            mb.req("PUT", f"/card/{card_id}", json={"archived": True})
            print(f"  pregunta obsoleta archivada: {nombre}")
    return ids


def tablero(mb: Metabase, col_id: int, ids: dict[str, int]) -> int:
    existente = [d for d in mb.req("GET", f"/collection/{col_id}/items?models=dashboard")["data"]
                 if d["name"] == NOMBRE_TABLERO]
    if existente:
        dash_id = existente[0]["id"]
    else:
        dash_id = mb.req("POST", "/dashboard", json={
            "name": NOMBRE_TABLERO, "collection_id": col_id,
            "description": "Indicadores de viajes de taxis amarillos y verdes de NYC construidos con DuckDB."})["id"]

    textos = {"texto_encabezado": TEXTO_ENCABEZADO, "texto_nota": TEXTO_NOTA}
    dashcards = []
    for i, (clave, fila, col, ancho, alto) in enumerate(LAYOUT, start=1):
        base = {"id": -i, "row": fila, "col": col, "size_x": ancho, "size_y": alto,
                "parameter_mappings": [], "series": []}
        if clave in textos:
            base.update(card_id=None, visualization_settings={
                "virtual_card": {"name": None, "display": "text", "visualization_settings": {},
                                 "dataset_query": {}, "archived": False},
                "text": textos[clave]})
        else:
            base.update(card_id=ids[clave], visualization_settings={})
        dashcards.append(base)
    mb.req("PUT", f"/dashboard/{dash_id}", json={"dashcards": dashcards, "width": "full"})
    return dash_id


def enlace_publico(mb: Metabase, dash_id: int) -> str:
    mb.req("PUT", "/setting/enable-public-sharing", json={"value": True})
    uuid = mb.req("POST", f"/dashboard/{dash_id}/public_link")["uuid"]
    return uuid


def main() -> int:
    mb = Metabase(MB_URL)
    props = esperar(mb)
    autenticar(mb, props)
    db_id = base_de_datos(mb)
    col_id = coleccion(mb)
    ids = preguntas(mb, db_id, col_id)
    dash_id = tablero(mb, col_id, ids)
    uuid = enlace_publico(mb, dash_id)
    print("\nTablero listo:")
    print(f"  privado : http://127.0.0.1:3000/dashboard/{dash_id}")
    print(f"  publico : http://127.0.0.1:3000/public/dashboard/{uuid}")
    (lab_db.RAIZ / "data" / "processed" / "metabase_dashboard.json").write_text(
        json.dumps({"dashboard_id": dash_id, "public_uuid": uuid, "cards": ids}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
