SHELL := /bin/bash

.PHONY: help tidy fmt vet test testcore check migrate identity finance gateway ports ps

help:
	@echo "Pix2pi-SaaS - Enterprise Commands"
	@echo ""
	@echo "  make tidy       -> go mod tidy"
	@echo "  make fmt        -> gofmt"
	@echo "  make vet        -> go vet"
	@echo "  make test       -> go test ./..."
	@echo "  make testcore   -> core paket testleri"
	@echo "  make check      -> tidy + fmt + vet + test"
	@echo "  make migrate    -> migration runner"
	@echo "  make identity   -> Identity API (PORT=9001)"
	@echo "  make finance    -> Finance API  (PORT=9002)"
	@echo "  make gateway    -> Gateway      (PORT=9003)"
	@echo "  make ports      -> port kontrol"
	@echo "  make ps         -> docker ps"

tidy:
	go mod tidy

fmt:
	gofmt -w .

vet:
	go vet ./...

test:
	go test ./... -count=1

testcore:
	go test ./pkg/... -count=1
	go test ./internal/... -count=1
	go test ./test/... -count=1

check: tidy fmt vet test

migrate:
	@echo "🧱 Running migrations..."
	@go run ./cmd/migrate/migrate_main.go

identity:
	@PORT=9001 ./scripts/run_identity.sh

finance:
	@PORT=9002 ./scripts/run_finance.sh

gateway:
	@PORT=9003 ./scripts/run_gateway.sh

# --- PIX2PI Enterprise Control Panel ---
all: core

core:
	@./scripts/run_all.sh

stop:
	@./scripts/stop_all.sh

restart:
	@./scripts/restart_all.sh

logs:
	@./scripts/logs.sh $(svc)

health:
	@./scripts/health.sh

ports:
	@echo "---- Listening Ports ----"
	@ss -lntp | grep -E ':(9[0-9]{3}|3[012][0-9]{2}|5432|6379|4222|8080|8443)\b' || true

ps:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

status: ports ps
# =========================
# L5 Observability (Enterprise)
# =========================
obs-up:
	@echo "📈 Starting Observability Stack (Prometheus/Grafana/Loki)..."
	@docker-compose -f deploy/observability/docker-compose.yml up -d

obs-down:
	@echo "🧹 Stopping Observability Stack..."
	@docker-compose -f deploy/observability/docker-compose.yml down

obs-ps:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "pix2pi_(prometheus|grafana|loki|promtail|node_exporter|cadvisor)" || true
