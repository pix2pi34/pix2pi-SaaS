#!/bin/bash
set -euo pipefail

OUT="$HOME/pix2pi/pix2pi-SaaS/step_44c_pg_topology_report.txt"
COMMON_ENV="/opt/pix2pi/orchestrator/env/common.env"

mask() {
  sed -E 's/(password=)[^ ]+/\1***/g; s/(POSTGRES_PASSWORD=).*/\1***/g'
}

echo "=== STEP 44C-1A / PG TOPOLOGY AUDIT ==="

{
  echo "===== 1) COMMON.ENV ====="
  if [ -f "$COMMON_ENV" ]; then
    cat -n "$COMMON_ENV" | mask
  else
    echo "common.env bulunamadi"
  fi
  echo

  echo "===== 2) DOCKER PS ====="
  docker ps -a
  echo

  echo "===== 3) 5433 PORT MAP ====="
  docker ps --format '{{.Names}} {{.Ports}}' | grep '5433->5432' || true
  echo

  echo "===== 4) POSTGRES CONTAINER ADAYLARI ====="
  docker ps -a --format '{{.Names}} {{.Image}}' | grep -i postgres || true
  echo

  echo "===== 5) PIX2PI_PG INSPECT ====="
  if docker ps -a --format '{{.Names}}' | grep -qx 'pix2pi_pg'; then
    docker inspect pix2pi_pg | mask
  else
    echo "pix2pi_pg bulunamadi"
  fi
  echo

  echo "===== 6) PIX2PI_PG ENV ====="
  if docker ps -a --format '{{.Names}}' | grep -qx 'pix2pi_pg'; then
    docker inspect pix2pi_pg --format '{{range .Config.Env}}{{println .}}{{end}}' | mask
  else
    echo "pix2pi_pg bulunamadi"
  fi
  echo

  echo "===== 7) PIX2PI_PG MOUNTS ====="
  if docker ps -a --format '{{.Names}}' | grep -qx 'pix2pi_pg'; then
    docker inspect pix2pi_pg --format '{{json .Mounts}}'
  else
    echo "pix2pi_pg bulunamadi"
  fi
  echo

  echo "===== 8) PIX2PI_PG NETWORKS ====="
  if docker ps -a --format '{{.Names}}' | grep -qx 'pix2pi_pg'; then
    docker inspect pix2pi_pg --format '{{json .NetworkSettings.Networks}}'
  else
    echo "pix2pi_pg bulunamadi"
  fi
  echo

  echo "===== 9) DB ICINDEN TEMEL INFO ====="
  if docker ps --format '{{.Names}}' | grep -qx 'pix2pi_pg'; then
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "select current_user, current_database();"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show data_directory;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show config_file;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show hba_file;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show listen_addresses;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show wal_level;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show max_wal_senders;"'
    docker exec pix2pi_pg sh -lc 'psql -U pix2pi -d pix2pi -Atqc "show hot_standby;"'
  else
    echo "pix2pi_pg running degil"
  fi
  echo

  echo "===== 10) VOLUME LIST ====="
  docker volume ls
  echo

  echo "===== 11) NETWORK LIST ====="
  docker network ls
  echo

  echo "===== 12) SONUC OZET ====="
  echo "Bu rapor sonraki adimda primary+replica kurulumunu planlamak icin kullanilacak."
} > "$OUT"

echo "OK ✅ rapor olustu -> $OUT"
echo
cat "$OUT"
echo
echo "OK ✅ STEP 44C-1A tamam"
