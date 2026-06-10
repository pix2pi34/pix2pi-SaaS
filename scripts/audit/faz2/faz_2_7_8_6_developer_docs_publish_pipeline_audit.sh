#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
GO_TEST_STATUS="NOT_RUN"

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

check_file() {
  local file="$1"
  local label="$2"
  if [ -s "$file" ]; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

echo "===== FAZ 2-7.8.6 DEVELOPER DOCS PUBLISH PIPELINE REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 runtime file"
check_file "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 test file"
check_file "configs/faz2/public_api/developer_docs_publish_pipeline.v1.json" "2-7.8.6 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE.md" "2-7.8.6 documentation file"
check_file "docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md" "2-7.8.6 published markdown trace"
check_file "docs/public_api/PIX2PI_PUBLIC_API_OPENAPI_TRACE.json" "2-7.8.6 published openapi trace"

check_grep "DeveloperDocsPublishRuntime" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 DeveloperDocsPublishRuntime type"
check_grep "DeveloperEndpointDoc" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 endpoint documentation model"
check_grep "RegisterEndpoint" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 endpoint registry function"
check_grep "PublishMarkdown" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 markdown publish function"
check_grep "PublishOpenAPITrace" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 openapi trace publish function"
check_grep "SeedRequiredPublicAPISections" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 required public API sections"
check_grep "Sandbox" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 sandbox docs section"
check_grep "API Key" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 api key docs section"
check_grep "Quota" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 quota docs section"
check_grep "App Auth" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 app auth docs section"
check_grep "ValidateReadyToPublish" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 publish validation"
check_grep "ErrDeveloperDocsDuplicateEndpoint" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 duplicate endpoint guard"
check_grep "ErrDeveloperDocsMissingSandboxDocs" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.6 missing sandbox docs guard"

check_grep "TestDeveloperDocsPublishRuntimeRegistersEndpoint" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 register endpoint test"
check_grep "TestDeveloperDocsPublishRuntimeRejectsDuplicateEndpoint" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 duplicate endpoint test"
check_grep "TestDeveloperDocsPublishRuntimeValidatesRequiredSections" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 required sections validation test"
check_grep "TestDeveloperDocsPublishRuntimePublishesMarkdown" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 markdown publish test"
check_grep "TestDeveloperDocsPublishRuntimePublishesOpenAPITrace" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 openapi trace publish test"
check_grep "TestDeveloperDocsPublishRuntimeRequiresEndpointDocs" "internal/platform/publicapi/runtime/developer_docs_publish_runtime_test.go" "2-7.8.6 endpoint docs required test"

check_grep "Sandbox" "docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md" "2-7.8.6 published sandbox docs"
check_grep "API Key" "docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md" "2-7.8.6 published api key docs"
check_grep "Quota" "docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md" "2-7.8.6 published quota docs"
check_grep "App Auth" "docs/public_api/PIX2PI_PUBLIC_API_DEVELOPER_DOCS.md" "2-7.8.6 published app auth docs"
check_grep "openapi_trace" "docs/public_api/PIX2PI_PUBLIC_API_OPENAPI_TRACE.json" "2-7.8.6 published openapi trace marker"

echo "===== FAZ 2-7.8.6 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.6 go test"
fi

echo "===== FAZ 2-7.8.6 DEVELOPER DOCS PUBLISH PIPELINE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_7_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_6_DEVELOPER_DOCS_PUBLISH_PIPELINE_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_7_READY=NO"
  exit 1
fi
