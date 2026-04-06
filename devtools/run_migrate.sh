#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "PIX2PI ROOT => $ROOT"
echo "🗄️  Running migrations..."
go run ./cmd/migrate
