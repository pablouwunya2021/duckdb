#!/bin/sh
# Reproduce todo el laboratorio dentro del contenedor `lab` (directorio /workspace):
#
#   docker exec lab8-lab sh scripts/run_all.sh            # todo
#   docker exec lab8-lab sh scripts/run_all.sh --sin-benchmark
#
# Pasos: descarga -> verificacion -> reportes SQL sobre Parquet -> base materializada
# + indicadores -> benchmark -> tablero de Metabase.
# Despues de reconstruir la base, reinicie Metabase desde el host para que suelte el
# archivo anterior:  docker compose restart metabase  (y vuelva a correr setup_metabase.py).
set -e
cd "$(dirname "$0")/.."

echo "== 1. Descarga de datos (solo lo que falta) =="
python scripts/download_data.py

echo "== 2. Verificacion de integridad y completitud =="
python scripts/verify_data.py --salida docs/inventario_datos.md

echo "== 3. Consultas documentadas sobre Parquet =="
python scripts/run_sql.py sql/03_exploracion.sql --max-filas 400 --salida docs/resultados/03_exploracion_3anios.md
python scripts/run_sql.py sql/04_eda.sql --max-filas 400 --salida docs/resultados/04_eda_3anios.md
python scripts/run_sql.py sql/05_validacion_2024.sql --max-filas 400 --salida docs/resultados/05_validacion_2024_3anios.md
python scripts/run_sql.py sql/08_validacion_2025.sql --max-filas 400

echo "== 4. Base DuckDB materializada + tablas de indicadores =="
python scripts/build_db.py
python scripts/run_sql.py sql/07_indicadores.sql --db data/processed/taxi.duckdb --max-filas 400 \
    --salida docs/resultados/07_indicadores_3anios.md

if [ "$1" != "--sin-benchmark" ]; then
  echo "== 5. Benchmark Parquet vs tabla =="
  python scripts/benchmark.py --repeticiones 5 --limpiar
fi

echo "== 6. Tablero de Metabase =="
python scripts/setup_metabase.py || echo "Metabase no disponible: ejecute scripts/setup_metabase.py cuando este arriba"
