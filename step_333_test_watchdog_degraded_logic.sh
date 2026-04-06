#!/bin/bash
set -e

echo "=== WATCHDOG STATUS ==="
curl -s http://127.0.0.1:8090/status
echo
echo "OK ✅ degraded logic test cikti alindi"
