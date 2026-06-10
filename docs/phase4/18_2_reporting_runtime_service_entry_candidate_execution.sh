#!/usr/bin/env bash
set -euo pipefail
echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 18.2 reporting runtime service entry candidate execution plan."
echo "18.2 does not apply runtime/gateway changes."
echo "Actual controlled apply belongs to 18.3 or later."
exit 99

# FAZ 4 / 18.2 - Reporting Runtime Service Entry Candidate Execution
# Generated at: 2026-04-27 19:52:03 +0300
# This file is intentionally blocked by exit 99 above.

ROOT_DIR="."
SELECTED_ENTRY_TARGET="cmd/api-gateway/api_gateway_main.go"
REPORTING_RUNTIME_REGISTRATION="internal/platform/reporting/runtime/registration.go"

# Candidate import to add if target is Go-based:
# reportingruntime "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/runtime"

# Candidate registration call:
# if err := reportingruntime.RegisterReportingRoutes(mux); err != nil {
#   return err
# }

# High-level controlled apply sequence:
# 1. Backup selected gateway/service entry file.
# 2. Add reporting runtime import.
# 3. Add RegisterReportingRoutes(mux) after base mux/router creation.
# 4. Run gofmt on changed Go file.
# 5. Run go test ./internal/platform/reporting/... ./cmd/... where applicable.
# 6. Do not restart runtime in 18.2.
# 7. 18.3 will perform controlled apply gate.

# Rollback plan:
# 1. Restore backed-up gateway/service entry file.
# 2. Run gofmt.
# 3. Run go test.
# 4. Confirm reporting route registration reverts to previous state.
