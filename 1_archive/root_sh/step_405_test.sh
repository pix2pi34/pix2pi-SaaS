#!/bin/bash
set -e

echo "=== TEST DB SPLIT ==="

grep -q "DBManager" internal/platform/kernel/kernel.go
echo "OK ✅ struct var"

grep -q "GetWriteDB" internal/platform/kernel/kernel.go
echo "OK ✅ write func"

grep -q "GetReadDB" internal/platform/kernel/kernel.go
echo "OK ✅ read func"

echo "OK ✅ STEP 405 TEST"
