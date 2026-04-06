#!/bin/bash

PORT=${PORT:-9001}

echo "🧹 Killing old Identity processes..."
fuser -k ${PORT}/tcp 2>/dev/null || true
pkill -f identity_main.go 2>/dev/null || true
pkill -f identity-api 2>/dev/null || true

sleep 1

echo "🚀 Starting Identity API on :$PORT"

cd "$(dirname "$0")/.." || exit 1

PORT=$PORT go run ./cmd/identity-api/identity_main.go
