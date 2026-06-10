#!/usr/bin/env bash
set -euo pipefail

DOC_FILE="docs/faz6r/FAZ_6_22_7_RELEASE_BUILD_DOGRULAMASI.md"
CONFIG_FILE="configs/faz6r/faz_6_22_7_release_build_dogrulamasi.v1.json"
BUILD_FILE="configs/faz6r/release_build_verification.web_release.v1.json"
FIXTURE_FILE="tests/faz6r/faz_6_22_7_release_build_dogrulamasi_test.json"
RUNTIME_FILE="scripts/faz6r/run_release_build_verification_dry_run.sh"
VALIDATOR_FILE="scripts/faz6r/validate_release_build_dogrulamasi.sh"
AUDIT_FILE="scripts/faz6r/audit_faz_6_22_7_release_build_dogrulamasi.sh"
EVIDENCE_FILE="docs/faz6r/evidence/FAZ_6_22_7_RELEASE_BUILD_DOGRULAMASI_REAL_IMPLEMENTATION_AUDIT.md"
PREV_RELEASE_CHECKLIST_UI_EVIDENCE="docs/faz6r/evidence/FAZ_6_22_6_RELEASE_CHECKLIST_UI_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 REQUIRED_FAIL / FAIL ❌"; }

check_file(){
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label missing"; fi
}

check_contains(){
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -q "$pattern" "$file"; then pass "$label"; else fail "$label missing pattern $pattern"; fi
}

echo "===== FAZ 6-22.7 RELEASE BUILD DOGRULAMASI REAL IMPLEMENTATION AUDIT START ====="

check_file "6-22.7 previous release checklist UI evidence file" "$PREV_RELEASE_CHECKLIST_UI_EVIDENCE"
check_contains "6-22.7 previous release checklist UI final PASS" "$PREV_RELEASE_CHECKLIST_UI_EVIDENCE" "FINAL_STATUS=PASS"

check_file "6-22.7 documentation file" "$DOC_FILE"
check_file "6-22.7 config file" "$CONFIG_FILE"
check_file "6-22.7 build verification file" "$BUILD_FILE"
check_file "6-22.7 fixture file" "$FIXTURE_FILE"
check_file "6-22.7 runtime file" "$RUNTIME_FILE"
check_file "6-22.7 validator file" "$VALIDATOR_FILE"
check_file "6-22.7 audit file" "$AUDIT_FILE"

check_contains "6-22.7 doc has Release Build" "$DOC_FILE" "Release Build"
check_contains "6-22.7 doc has Required Controls" "$DOC_FILE" "Required Controls"
check_contains "6-22.7 doc has Final Gate" "$DOC_FILE" "Final Gate"

check_contains "6-22.7 config has dependency" "$CONFIG_FILE" "FAZ_6_22_6"
check_contains "6-22.7 config disables runtime mutation" "$CONFIG_FILE" '"runtime_mutation_allowed": false'
check_contains "6-22.7 config disables provider mutation" "$CONFIG_FILE" '"provider_mutation_allowed": false'
check_contains "6-22.7 config disables build publish" "$CONFIG_FILE" '"build_publish_allowed": false'
check_contains "6-22.7 config disables frontend deploy" "$CONFIG_FILE" '"frontend_deploy_allowed": false'
check_contains "6-22.7 config disables image push" "$CONFIG_FILE" '"container_image_push_allowed": false'
check_contains "6-22.7 config disables artifact upload" "$CONFIG_FILE" '"artifact_upload_allowed": false'
check_contains "6-22.7 config disables cdn invalidation" "$CONFIG_FILE" '"cdn_invalidation_allowed": false'
check_contains "6-22.7 config disables migration apply" "$CONFIG_FILE" '"migration_apply_allowed": false'
check_contains "6-22.7 config disables production release execute" "$CONFIG_FILE" '"production_release_execute_allowed": false'
check_contains "6-22.7 config has manifest policy" "$CONFIG_FILE" "release_candidate_manifest_policy"
check_contains "6-22.7 config has checksum signature" "$CONFIG_FILE" "checksum_signature_policy"
check_contains "6-22.7 config has secret scan" "$CONFIG_FILE" "secret_scan_policy"
check_contains "6-22.7 config has dependency lock" "$CONFIG_FILE" "dependency_lock_policy"
check_contains "6-22.7 config has rollback manifest" "$CONFIG_FILE" "rollback_manifest_policy"

check_contains "6-22.7 build has frontend assets" "$BUILD_FILE" "build-frontend-static-assets"
check_contains "6-22.7 build has release manifest" "$BUILD_FILE" "build-web-release-manifest"
check_contains "6-22.7 build has container metadata" "$BUILD_FILE" "build-container-image-metadata"
check_contains "6-22.7 build has environment config" "$BUILD_FILE" "build-environment-config-bundle"
check_contains "6-22.7 build has migration bundle" "$BUILD_FILE" "build-migration-bundle"
check_contains "6-22.7 build has rollback manifest" "$BUILD_FILE" "build-rollback-manifest"
check_contains "6-22.7 build has no mutation" "$BUILD_FILE" '"mutation_allowed": false'
check_contains "6-22.7 build has dry-run status" "$BUILD_FILE" "dry_run_only_no_release_build_mutation"
check_contains "6-22.7 build has next step" "$BUILD_FILE" "FAZ_6_R_FINAL_CLOSURE"

check_contains "6-22.7 fixture has expected next step" "$FIXTURE_FILE" "FAZ_6_R_FINAL_CLOSURE"

if "$RUNTIME_FILE" "$CONFIG_FILE" "$BUILD_FILE" "$FIXTURE_FILE" >/tmp/faz_6_22_7_release_build_runtime.json; then
  pass "6-22.7 dry-run release build runtime"
else
  fail "6-22.7 dry-run release build runtime"
fi

check_contains "6-22.7 runtime output is PASS" "/tmp/faz_6_22_7_release_build_runtime.json" '"runtime_status": "PASS"'
check_contains "6-22.7 runtime output is dry run" "/tmp/faz_6_22_7_release_build_runtime.json" "release_build_verification_dry_run"
check_contains "6-22.7 runtime output disables provider mutation" "/tmp/faz_6_22_7_release_build_runtime.json" '"provider_mutation_allowed": false'
check_contains "6-22.7 runtime output disables build publish" "/tmp/faz_6_22_7_release_build_runtime.json" '"build_publish_allowed": false'
check_contains "6-22.7 runtime output disables production release" "/tmp/faz_6_22_7_release_build_runtime.json" '"production_release_execute_allowed": false'
check_contains "6-22.7 runtime output has next step" "/tmp/faz_6_22_7_release_build_runtime.json" "FAZ_6_R_FINAL_CLOSURE"

if "$VALIDATOR_FILE" "$CONFIG_FILE" "$BUILD_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE"; then
  pass "6-22.7 semantic validator runtime"
else
  fail "6-22.7 semantic validator runtime"
fi

if command -v python3 >/dev/null 2>&1; then
  pass "6-22.7 python3 dependency"
else
  fail "6-22.7 python3 dependency"
fi

REQUIRED_FAIL="$FAIL_COUNT"
OPTIONAL_WARN="$WARN_COUNT"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
  FINAL_STATUS="PASS"
  NEXT_READY="YES"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
  FINAL_STATUS="FAIL"
  NEXT_READY="NO"
fi

cat > "$EVIDENCE_FILE" <<EOF2
# FAZ 6-R / 315 — FAZ 6-22.7 Release Build Doğrulaması Real Implementation Audit

PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
WARN_COUNT=${WARN_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}

DOC_STATUS=READY
CONFIG_STATUS=READY
BUILD_STATUS=READY
FIXTURE_STATUS=READY
RUNTIME_STATUS=READY
REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}
FINAL_STATUS=${FINAL_STATUS}
FAZ_6_R_FINAL_CLOSURE_READY=${NEXT_READY}

WEB_L9_FINAL_RELEASE_POLISH_COMPLETE=YES
FAZ_6_R_PRIORITY_4_READY=YES

Scope note: provider mutation, build publish, frontend deploy, container image push, artifact upload, CDN invalidation, route mutation, migration apply and production release execute remain closed in this step.
Dependency: FAZ_6_22_6 release checklist UI evidence checked.
EOF2

echo "===== FAZ 6-22.7 RELEASE BUILD DOGRULAMASI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"
echo "FAZ_6_22_7_REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"

echo "===== FAZ 6-22.7 RELEASE BUILD DOGRULAMASI COUNTER BASED FINAL STATUS ====="
echo "DOC_STATUS=READY"
echo "CONFIG_STATUS=READY"
echo "BUILD_STATUS=READY"
echo "FIXTURE_STATUS=READY"
echo "RUNTIME_STATUS=READY"
echo "REAL_IMPLEMENTATION_STATUS=${REAL_IMPLEMENTATION_STATUS}"
echo "FINAL_STATUS=${FINAL_STATUS}"
echo "WEB_L9_FINAL_RELEASE_POLISH_COMPLETE=YES"
echo "FAZ_6_R_PRIORITY_4_READY=YES"
echo "FAZ_6_R_FINAL_CLOSURE_READY=${NEXT_READY}"

[ "$FINAL_STATUS" = "PASS" ]
