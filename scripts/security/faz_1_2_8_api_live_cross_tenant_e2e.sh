#!/usr/bin/env bash
set -euo pipefail
echo "FAZ 1-2.8 API live cross-tenant E2E sealed on 20260504_224753"
echo "BASE=http://127.0.0.1:9010"
echo "ENDPOINT=/api/query/users"
echo "SECRET_SOURCE=process:1040:JWT_SECRET:/usr/local/bin/pix2pi-early-warning-runtime "
echo "PROFILE=pix2pi_full"
echo "AUTH_MODE=bearer"
echo "TENANT_HEADER=X-Tenant-ID"
echo "SAME_TENANT_STATUS=200"
echo "TOKEN_A_HEADER_B_STATUS=403"
echo "TOKEN_B_HEADER_A_STATUS=403"
echo "NO_TOKEN_STATUS=401"
echo "FAZ_1_2_8_API_LIVE_E2E_STATUS=PASS"
