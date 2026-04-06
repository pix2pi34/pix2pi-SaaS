#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export PORT="${PORT:-9002}"
echo "💰 Starting Finance API on :$PORT"

# Not: Finance main dosyan farklıysa burada yolu değiştiririz.
# Şimdilik varsayılan: ./cmd/finance-api/main.go
go run ./cmd/finance-api/main.go
