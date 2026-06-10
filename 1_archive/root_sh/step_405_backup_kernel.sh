#!/bin/bash
set -e

echo "backup aliniyor..."

FILE=~/pix2pi/pix2pi-SaaS/internal/platform/kernel/kernel.go
cp $FILE ${FILE}.bak_$(date +%s)

echo "OK ✅ backup"
