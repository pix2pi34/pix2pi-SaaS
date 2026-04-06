#!/bin/bash
set -e

echo "=== NGINX / OPENRESTY PROCESSLER ==="
ps -ef | grep nginx | grep -v grep || true
echo

MASTER_PID="$(ps -ef | grep 'nginx: master process' | grep -v grep | awk 'NR==1{print $2}')"

echo "MASTER_PID=$MASTER_PID"
echo

if [ -z "$MASTER_PID" ]; then
  echo "HATA: nginx master process bulunamadi"
  exit 1
fi

echo "=== /proc/$MASTER_PID/cmdline ==="
tr '\0' ' ' < /proc/$MASTER_PID/cmdline || true
echo
echo

echo "=== /proc/$MASTER_PID/exe ==="
readlink -f /proc/$MASTER_PID/exe || true
echo

echo "=== /proc/$MASTER_PID/cwd ==="
readlink -f /proc/$MASTER_PID/cwd || true
echo

echo "=== /proc/$MASTER_PID/root ==="
readlink -f /proc/$MASTER_PID/root || true
echo

echo "=== MASTER ENV (KONG / PREFIX / NGINX) ==="
tr '\0' '\n' < /proc/$MASTER_PID/environ | grep -Ei 'kong|nginx|prefix|openresty' || true
echo

echo "=== MASTER OPEN FILES (config benzeri) ==="
ls -l /proc/$MASTER_PID/fd 2>/dev/null | grep -Ei 'conf|nginx|kong|openresty' || true
echo

echo "=== MASTER MAPS (conf path ipucu) ==="
grep -Ei 'openresty|kong|nginx' /proc/$MASTER_PID/maps || true
echo

echo "=== 8001/8002/8007 SAHIBI ==="
ss -ltnp | grep -E '8001|8002|8007' || true
echo

echo "OK ✅ runtime trace bitti"
