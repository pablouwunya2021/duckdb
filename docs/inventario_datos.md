# Inventario de datos descargados

Generado por `python scripts/verify_data.py --salida docs/inventario_datos.md`.

## Resumen por tipo y anio

| tipo | anio | archivos | meses | filas | tamanio (MiB) |
|---|---|---:|---|---:|---:|
| green | 2024 | 12 | 01-12 | 660,218 | 15.2 |
| green | 2026 | 8 | 01-08 | 337,114 | 7.9 |
| yellow | 2024 | 12 | 01-12 | 41,169,720 | 660.9 |
| yellow | 2026 | 8 | 01-08 | 29,703,355 | 487.8 |
| **total** | | **40** | | **71,870,407** | **1,171.7** |

## Detalle por archivo

| archivo | filas | row groups | MiB | legible |
|---|---:|---:|---:|---|
| `data/raw/green/2024/green_tripdata_2024-01.parquet` | 56,551 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-02.parquet` | 53,577 | 1 | 1.2 | si |
| `data/raw/green/2024/green_tripdata_2024-03.parquet` | 57,457 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-04.parquet` | 56,471 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-05.parquet` | 61,003 | 1 | 1.4 | si |
| `data/raw/green/2024/green_tripdata_2024-06.parquet` | 54,748 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-07.parquet` | 51,837 | 1 | 1.2 | si |
| `data/raw/green/2024/green_tripdata_2024-08.parquet` | 51,771 | 1 | 1.2 | si |
| `data/raw/green/2024/green_tripdata_2024-09.parquet` | 54,440 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-10.parquet` | 56,147 | 1 | 1.3 | si |
| `data/raw/green/2024/green_tripdata_2024-11.parquet` | 52,222 | 1 | 1.2 | si |
| `data/raw/green/2024/green_tripdata_2024-12.parquet` | 53,994 | 1 | 1.3 | si |
| `data/raw/green/2026/green_tripdata_2026-01.parquet` | 40,272 | 1 | 0.9 | si |
| `data/raw/green/2026/green_tripdata_2026-02.parquet` | 37,373 | 1 | 0.9 | si |
| `data/raw/green/2026/green_tripdata_2026-03.parquet` | 44,208 | 1 | 1.0 | si |
| `data/raw/green/2026/green_tripdata_2026-04.parquet` | 44,238 | 1 | 1.0 | si |
| `data/raw/green/2026/green_tripdata_2026-05.parquet` | 44,921 | 1 | 1.1 | si |
| `data/raw/green/2026/green_tripdata_2026-06.parquet` | 44,163 | 1 | 1.0 | si |
| `data/raw/green/2026/green_tripdata_2026-07.parquet` | 41,252 | 1 | 1.0 | si |
| `data/raw/green/2026/green_tripdata_2026-08.parquet` | 40,687 | 1 | 1.0 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-01.parquet` | 2,964,624 | 3 | 47.6 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-02.parquet` | 3,007,526 | 3 | 48.0 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-03.parquet` | 3,582,628 | 4 | 57.3 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-04.parquet` | 3,514,289 | 4 | 56.4 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-05.parquet` | 3,723,833 | 4 | 59.7 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-06.parquet` | 3,539,193 | 4 | 57.1 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-07.parquet` | 3,076,903 | 3 | 49.9 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-08.parquet` | 2,979,183 | 3 | 48.7 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-09.parquet` | 3,633,030 | 4 | 58.3 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-10.parquet` | 3,833,771 | 4 | 61.4 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-11.parquet` | 3,646,369 | 4 | 57.8 | si |
| `data/raw/yellow/2024/yellow_tripdata_2024-12.parquet` | 3,668,371 | 4 | 58.7 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-01.parquet` | 3,724,889 | 4 | 61.2 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-02.parquet` | 3,399,866 | 4 | 56.0 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-03.parquet` | 3,952,451 | 4 | 64.7 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-04.parquet` | 3,831,240 | 4 | 61.8 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-05.parquet` | 4,090,836 | 4 | 66.5 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-06.parquet` | 3,837,248 | 4 | 62.4 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-07.parquet` | 3,530,109 | 4 | 58.8 | si |
| `data/raw/yellow/2026/yellow_tripdata_2026-08.parquet` | 3,336,716 | 4 | 56.3 | si |
