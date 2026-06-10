#!/usr/bin/env bash
set -euo pipefail
echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 18.3 gateway route controlled apply candidate execution plan."
echo "18.3 does not apply runtime/gateway changes."
echo "Actual controlled apply belongs to 18.4 after explicit apply decision."
exit 99

# FAZ 4 / 18.3 - Gateway Route Controlled Apply Candidate Execution
# Generated at: 2026-04-27 20:09:34 
# This file is intentionally blocked by exit 99 above.

ROOT_DIR="."
SELECTED_ENTRY_TARGET="cmd/api-gateway/api_gateway_main.go"
SELECTED_ENTRY_TARGET_SHA256="9bf59d57ae0d2f15c927fd2a9e58779db9ee7a6721e396e9498dcde035bec7ac"
RUNTIME_REGISTRATION_FILE="internal/platform/reporting/runtime/registration.go"
RUNTIME_REGISTRATION_SHA256="6c4abbf5cd01faab8de6352322098392ce1abd689d6a758856cc85720c5e382a"

# Proposed import:
# reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"

# Proposed route registration call after mux/router creation:
# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {
#   log.Fatalf("reporting route registration failed: %v", err)
# }

# Idempotency rule:
# 1. If reportingruntime import already exists, do not add duplicate import.
# 2. If RegisterReportingRoutes call already exists, do not add duplicate call.
# 3. Patch only api-gateway target, never accounting-service or unrelated cmd.

# Controlled apply sequence for 18.4:
# 1. Backup cmd/api-gateway/api_gateway_main.go.
# 2. Detect mux/router symbol in api-gateway entry.
# 3. Add reportingruntime import if missing.
# 4. Add reportingruntime.RegisterReportingRoutes(mux) if missing.
# 5. Run gofmt on changed file.
# 6. Run go test ./internal/platform/reporting/... .
# 7. Run go test ./cmd/api-gateway with route/runtime tests.
# 8. Build or compile api-gateway if needed.
# 9. Restart only controlled gateway runtime if explicitly approved.
# 10. Run live HTTP smoke in 18.4/18.5.

# Rollback:
# 1. Restore backed-up cmd/api-gateway/api_gateway_main.go.
# 2. Run gofmt.
# 3. Run go test ./cmd/api-gateway.
# 4. Verify gateway returns to previous route set.
