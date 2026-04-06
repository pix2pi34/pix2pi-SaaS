#!/bin/bash
set -e

echo "=== WATCHDOG FILE FIND ==="

echo
echo "1. cmd altini tarama..."
find ~/pix2pi -type f -name "*watchdog*main.go"

echo
echo "2. tum go dosyalari icinde ara..."
grep -R "package main" ~/pix2pi | grep watchdog || true

echo
echo "3. binary kontrol..."
ps aux | grep watchdog | grep -v grep

echo
echo "4. porttan calisan binary..."
lsof -i :8090 || true

echo
echo "OK ✅ arama tamam"
