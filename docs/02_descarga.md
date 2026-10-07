# Ejercicio 2 - Sistema de descarga

## 2.1 Análisis del script proporcionado

El script original `scripts/download_data.py` ya resolvía bien varias cosas
(descarga por bloques, archivo temporal `.part`, reintentos, omitir archivos existentes,
consulta `HEAD` para saber qué meses están publicados). Sus limitaciones eran:

| # | Problema en el script original | Consecuencia |
|---|---|---|
| 1 | `ANIO = 2026` fijo en una constante global usada por `construir_nombre`, `construir_url` y `ruta_destino` | Imposible descargar 2024/2025 (Ejercicios 5 y 8) sin editar el código cada vez |
| 2 | No había argumento de línea de comandos para el año | No se puede elegir qué años descargar |
| 3 | Solo verificaba `st_size > 0` y que la descarga no estuviera vacía | Una descarga truncada (p. ej. conexión cortada pero respuesta "exitosa") se aceptaba como válida |
| 4 | `esta_publicado` devolvía `False` ante **cualquier** excepción de red | Un fallo de red se reportaba como "aún no publicado", ocultando el error |
| 5 | No quedaba registro de qué se descargó | No hay evidencia para demostrar que el conjunto está completo |

## 2.2 - 2.4 / 2.6 Cambios realizados

1. **Año parametrizable:** `ANIOS = (2026,)` es ahora una tupla configurable y todas las
   funciones (`construir_nombre`, `construir_url`, `ruta_destino`, `descargar`) reciben el año.
   Nuevo argumento `--anio` (acepta uno o varios años).
2. **Detección automática de meses:** se mantiene la consulta `HEAD` mes a mes (1-12), de forma
   que el script obtiene automáticamente **todos** los meses publicados sin suponerlos.
3. **Validación de integridad:** se lee `Content-Length` en el `HEAD` y se compara con los bytes
   escritos; si difieren, la descarga se reintenta y finalmente se marca como fallida.
4. **Errores de red explícitos:** `consultar_servidor` reintenta y, si sigue fallando, reporta
   `error_consulta` en lugar de "no publicado".
5. **Modo `--verificar`:** revalida los archivos existentes contra el tamaño del servidor y vuelve
   a descargar solo los que no coinciden.
6. **Manifiesto:** se genera `data/raw/manifest.csv` (tipo, año, mes, ruta, bytes local/servidor,
   estado: `descargado`, `existente`, `verificado`, `no_publicado`, `fallido`).
7. **Estructura de directorios:** se conserva `data/raw/<tipo>/<anio>/<archivo-original>.parquet` (2.3).
8. **Idempotencia (2.4):** si el archivo existe y no está vacío, se omite (`ya existe, se omite`).

Además se agregó `scripts/verify_data.py`, que abre cada Parquet con DuckDB
(`parquet_file_metadata`) para confirmar que es legible, cuenta filas desde los metadatos y
detecta meses faltantes en la secuencia.

## 2.5 Ejecución

```bash
docker exec lab8-lab python scripts/download_data.py
```

Primera ejecución (resumen):

```text
=== YELLOW 2026 ===
  2026-01  listo (61.2 MiB) -> data/raw/yellow/2026/yellow_tripdata_2026-01.parquet
  ...
  2026-08  listo (56.3 MiB) -> data/raw/yellow/2026/yellow_tripdata_2026-08.parquet
  2026-09  aun no publicado por la TLC
  ...
RESUMEN  (anios: 2026)
  descargados   : 16
  ya existian   : 0
  no publicados : 8   (sep-dic 2026 de ambos tipos)
  fallidos      : 0
```

Segunda ejecución (comprueba 2.4, no se vuelve a descargar nada):

```text
  descargados   : 0
  ya existian   : 16
  fallidos      : 0
```

## 2.7 ¿Cómo se determinó que el conjunto está completo?

Se usaron tres comprobaciones independientes:

1. **Contra el servidor:** para cada mes 1-12 se hizo `HEAD` a la URL oficial. Los meses de
   enero a agosto 2026 responden `200` y fueron descargados; septiembre a diciembre responden
   `403` (aún no publicados por la TLC; la TLC publica con ~2 meses de atraso). El modo
   `--verificar` confirmó que los 16 archivos locales tienen exactamente el `Content-Length`
   del servidor (16/16 `verificado`).
2. **Integridad del Parquet:** `scripts/verify_data.py` leyó los metadatos de los 16 archivos con
   DuckDB sin errores (0 ilegibles) y sin huecos en la secuencia de meses (0 faltantes).
3. **Conteo de registros:** 16 archivos, **30,040,469** filas (29,703,355 yellow + 337,114 green).
   Detalle en [`inventario_datos.md`](inventario_datos.md).

```bash
docker exec lab8-lab python scripts/download_data.py --verificar
docker exec lab8-lab python scripts/verify_data.py --salida docs/inventario_datos.md
```
