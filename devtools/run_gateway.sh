#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export PORT="${PORT:-9003}"
echo "🌐 Starting Gateway on :$PORT"

# Not: Gateway main dosyan farklıysa burada yolu değiştiririz.
# Şimdilik varsayılan: ./cmd/gateway/main.go
go run ./cmd/gateway/main.go
