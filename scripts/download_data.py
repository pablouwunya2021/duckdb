#!/usr/bin/env python3
"""Descarga los archivos Parquet del NYC TLC Trip Record Data.

Descarga los registros de viajes de taxis amarillos (yellow) y verdes (green)
para los anios configurados en ANIOS (o los indicados con --anio).

Fuente oficial de los datos:
    https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

Uso:
    python scripts/download_data.py                       # anios configurados, ambos tipos
    python scripts/download_data.py --taxi yellow
    python scripts/download_data.py --anio 2026           # solo un anio
    python scripts/download_data.py --anio 2024 2026      # varios anios
    python scripts/download_data.py --verificar           # revalida tamanios locales vs servidor

Los archivos se guardan en:
    data/raw/<tipo>/<anio>/<nombre-original>.parquet

Comportamiento:
  - La TLC publica cada mes con varias semanas de atraso, por lo que no todos
    los meses existen todavia. El script consulta al servidor que meses estan
    publicados en lugar de suponerlos.
  - Un archivo que ya existe localmente no se vuelve a descargar.
  - La descarga se hace sobre un nombre temporal y solo se renombra al
    terminar, de modo que una interrupcion no deja archivos .parquet a medias.
  - Se compara el tamanio descargado con el Content-Length informado por el
    servidor; si no coincide la descarga se considera fallida.
  - Al terminar se escribe data/raw/manifest.csv con el inventario de archivos
    (tipo, anio, mes, ruta, bytes, estado), que sirve como evidencia de que el
    conjunto descargado esta completo.

Cambios respecto al script original (Ejercicio 2.6):
  - El anio ya no esta fijo en el codigo: ANIOS es una tupla configurable y el
    argumento --anio permite elegir uno o varios anios.
  - Las funciones de nombre/URL/ruta reciben el anio como parametro.
  - Se valida el tamanio contra Content-Length (deteccion de descargas truncadas).
  - Un error de red en la peticion HEAD ya no se confunde con "no publicado".
  - Se genera un manifiesto CSV con el inventario de lo descargado.
  - Se descarga tambien la tabla de zonas (data/raw/reference/taxi_zone_lookup.csv).
"""

import argparse
import csv
import sys
from pathlib import Path

import requests

# Anios que forman parte del conjunto de datos del laboratorio.
# Para incorporar un anio nuevo basta con agregarlo aqui (o usar --anio).
ANIOS = (2026,)
TIPOS_TAXI = ("yellow", "green")
URL_BASE = "https://d37ci6vzurychx.cloudfront.net/trip-data"
DIR_DESTINO = Path("data/raw")
MANIFIESTO = DIR_DESTINO / "manifest.csv"
# Tabla de referencia de zonas de taxi (LocationID -> Borough/Zone), necesaria
# para traducir PULocationID/DOLocationID en el analisis.
URL_ZONAS = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
RUTA_ZONAS = DIR_DESTINO / "reference" / "taxi_zone_lookup.csv"

TIEMPO_ESPERA = 60          # segundos por peticion
INTENTOS = 3                # intentos por archivo antes de darse por vencido
BLOQUE = 1024 * 1024        # 1 MiB por bloque de descarga
SUFIJO_TEMPORAL = ".part"


def construir_nombre(tipo: str, anio: int, mes: int) -> str:
    """Nombre del archivo publicado por la TLC, p. ej. yellow_tripdata_2026-01.parquet."""
    return f"{tipo}_tripdata_{anio}-{mes:02d}.parquet"


def construir_url(tipo: str, anio: int, mes: int) -> str:
    """URL completa del archivo Parquet mensual."""
    return f"{URL_BASE}/{construir_nombre(tipo, anio, mes)}"


def ruta_destino(tipo: str, anio: int, mes: int) -> Path:
    """Ruta local donde se guarda el archivo."""
    return DIR_DESTINO / tipo / str(anio) / construir_nombre(tipo, anio, mes)


def consultar_servidor(url: str) -> tuple[bool, int | None]:
    """Consulta (HEAD) si el archivo existe en el servidor y su tamanio.

    Devuelve (publicado, bytes). Los errores de red se reintentan; si persisten
    se propaga la excepcion para no confundirlos con un mes no publicado.
    """
    ultimo_error = None
    for _ in range(INTENTOS):
        try:
            respuesta = requests.head(url, timeout=TIEMPO_ESPERA, allow_redirects=True)
        except requests.RequestException as error:
            ultimo_error = error
            continue
        if not respuesta.ok:
            return False, None
        longitud = respuesta.headers.get("Content-Length")
        return True, int(longitud) if longitud else None
    raise requests.RequestException(f"no se pudo consultar {url}: {ultimo_error}")


def formato_tamanio(n: float) -> str:
    for unidad in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unidad == "GiB":
            return f"{n:.1f} {unidad}"
        n /= 1024
    return f"{n:.1f} GiB"


def descargar_archivo(url: str, destino: Path, esperado: int | None) -> int:
    """Descarga `url` en `destino`. Devuelve la cantidad de bytes escritos."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_name(destino.name + SUFIJO_TEMPORAL)

    ultimo_error = None
    for intento in range(1, INTENTOS + 1):
        try:
            with requests.get(url, stream=True, timeout=TIEMPO_ESPERA) as respuesta:
                respuesta.raise_for_status()
                escritos = 0
                with temporal.open("wb") as archivo:
                    for bloque in respuesta.iter_content(chunk_size=BLOQUE):
                        if bloque:
                            archivo.write(bloque)
                            escritos += len(bloque)
            if escritos == 0:
                raise requests.RequestException("el servidor devolvio un archivo vacio")
            if esperado is not None and escritos != esperado:
                raise requests.RequestException(
                    f"descarga incompleta ({escritos} de {esperado} bytes)"
                )
            temporal.replace(destino)
            return escritos
        except requests.RequestException as error:
            ultimo_error = error
            temporal.unlink(missing_ok=True)
            if intento < INTENTOS:
                print(f"      intento {intento}/{INTENTOS} fallido ({error}); reintentando")

    raise requests.RequestException(f"no se pudo descargar {url}: {ultimo_error}")


def descargar(tipo: str, anio: int, verificar: bool, inventario: list) -> dict:
    """Descarga todos los meses publicados de un tipo de taxi para un anio."""
    print(f"\n=== {tipo.upper()} {anio} ===")
    resumen = {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}

    for mes in range(1, 13):
        etiqueta = f"{anio}-{mes:02d}"
        destino = ruta_destino(tipo, anio, mes)
        url = construir_url(tipo, anio, mes)
        fila = {"tipo": tipo, "anio": anio, "mes": mes, "archivo": destino.as_posix(),
                "bytes_local": "", "bytes_servidor": "", "estado": ""}

        existe = destino.exists() and destino.stat().st_size > 0
        if existe and not verificar:
            print(f"  {etiqueta}  ya existe, se omite")
            resumen["omitidos"] += 1
            fila.update(bytes_local=destino.stat().st_size, estado="existente")
            inventario.append(fila)
            continue

        try:
            publicado, esperado = consultar_servidor(url)
        except requests.RequestException as error:
            print(f"  {etiqueta}  ERROR: {error}")
            resumen["fallidos"].append(etiqueta)
            fila["estado"] = "error_consulta"
            inventario.append(fila)
            continue

        if not publicado:
            print(f"  {etiqueta}  aun no publicado por la TLC")
            resumen["no_publicados"].append(etiqueta)
            fila["estado"] = "no_publicado"
            inventario.append(fila)
            continue

        fila["bytes_servidor"] = esperado if esperado is not None else ""

        if existe:  # modo --verificar
            local = destino.stat().st_size
            fila["bytes_local"] = local
            if esperado is None or local == esperado:
                print(f"  {etiqueta}  verificado ({formato_tamanio(local)})")
                resumen["omitidos"] += 1
                fila["estado"] = "verificado"
                inventario.append(fila)
                continue
            print(f"  {etiqueta}  tamanio distinto al del servidor ({local} vs {esperado}); se vuelve a descargar")

        print(f"  {etiqueta}  descargando...")
        try:
            escritos = descargar_archivo(url, destino, esperado)
        except requests.RequestException as error:
            print(f"  {etiqueta}  ERROR: {error}")
            resumen["fallidos"].append(etiqueta)
            fila["estado"] = "fallido"
        else:
            print(f"  {etiqueta}  listo ({formato_tamanio(escritos)}) -> {destino}")
            resumen["descargados"] += 1
            fila.update(bytes_local=escritos, estado="descargado")
        inventario.append(fila)

    return resumen


def descargar_zonas() -> None:
    """Descarga la tabla de zonas de la TLC si aun no existe localmente."""
    if RUTA_ZONAS.exists() and RUTA_ZONAS.stat().st_size > 0:
        print(f"\nzonas: {RUTA_ZONAS} ya existe, se omite")
        return
    publicado, esperado = consultar_servidor(URL_ZONAS)
    if not publicado:
        print("\nzonas: tabla de zonas no disponible en el servidor")
        return
    escritos = descargar_archivo(URL_ZONAS, RUTA_ZONAS, esperado)
    print(f"\nzonas: listo ({formato_tamanio(escritos)}) -> {RUTA_ZONAS}")


def escribir_manifiesto(inventario: list) -> None:
    """Escribe el inventario en data/raw/manifest.csv (fuera de Git)."""
    MANIFIESTO.parent.mkdir(parents=True, exist_ok=True)
    campos = ["tipo", "anio", "mes", "archivo", "bytes_local", "bytes_servidor", "estado"]
    with MANIFIESTO.open("w", newline="") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=campos)
        escritor.writeheader()
        escritor.writerows(inventario)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Descarga los datos de taxis amarillos y verdes del NYC TLC."
    )
    parser.add_argument(
        "--taxi", choices=(*TIPOS_TAXI, "all"), default="all",
        help="tipo de taxi a descargar (por defecto: all)",
    )
    parser.add_argument(
        "--anio", type=int, nargs="+", default=list(ANIOS),
        help=f"anio(s) a descargar (por defecto: {' '.join(map(str, ANIOS))})",
    )
    parser.add_argument(
        "--verificar", action="store_true",
        help="compara el tamanio de los archivos existentes con el del servidor",
    )
    argumentos = parser.parse_args()

    tipos = TIPOS_TAXI if argumentos.taxi == "all" else (argumentos.taxi,)
    anios = sorted(set(argumentos.anio))

    total = {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}
    inventario: list = []
    for tipo in tipos:
        for anio in anios:
            resumen = descargar(tipo, anio, argumentos.verificar, inventario)
            total["descargados"] += resumen["descargados"]
            total["omitidos"] += resumen["omitidos"]
            total["no_publicados"] += [f"{tipo} {m}" for m in resumen["no_publicados"]]
            total["fallidos"] += [f"{tipo} {m}" for m in resumen["fallidos"]]

    escribir_manifiesto(inventario)
    try:
        descargar_zonas()
    except requests.RequestException as error:
        print(f"\nzonas: ERROR: {error}")
        total["fallidos"].append("taxi_zone_lookup.csv")

    print("\n" + "=" * 60)
    print(f"RESUMEN  (anios: {', '.join(map(str, anios))})")
    print("=" * 60)
    print(f"  descargados   : {total['descargados']}")
    print(f"  ya existian   : {total['omitidos']}")
    print(f"  no publicados : {len(total['no_publicados'])}")
    if total["no_publicados"]:
        print(f"      {', '.join(total['no_publicados'])}")
    print(f"  fallidos      : {len(total['fallidos'])}")
    if total["fallidos"]:
        print(f"      {', '.join(total['fallidos'])}")
    print(f"  manifiesto    : {MANIFIESTO}")
    print("=" * 60)

    return 1 if total["fallidos"] else 0


if __name__ == "__main__":
    sys.exit(main())
