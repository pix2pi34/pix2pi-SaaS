#!/bin/bash
set -e

echo "=== TEST QUERY READ MODEL ==="

grep -q "GetReadDB" internal/services/query_read_model/service.go
echo "OK ✅ read db kullaniliyor"

echo "OK ✅ STEP 407 BASLANGIC TAMAM"
