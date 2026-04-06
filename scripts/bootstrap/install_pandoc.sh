#!/bin/bash
set -e

echo "==> Pandoc kuruluyor..."
apt-get update -y
apt-get install -y pandoc

echo "OK ✅ Pandoc kuruldu"
