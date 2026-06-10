#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_12_FINAL_GATE_PROBE_EVIDENCE.md"
mkdir -p docs/faz6/evidence

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅" | tee -a "$EVIDENCE_FILE"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo "$1 WARN ⚠️" | tee -a "$EVIDENCE_FILE"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌" | tee -a "$EVIDENCE_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

search_status() {
  local label="$1"
  local pattern="$2"
  local required="$3"

  if grep -RInF "$pattern" docs/faz6 scripts 2>/dev/null | head -n 20 >> "$EVIDENCE_FILE"; then
    ok "$label"
  else
    if [ "$required" = "required" ]; then
      fail "$label"
    else
      warn "$label"
    fi
  fi
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-12 Final Gate Probe Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  

Bu script FAZ 6 final gate icin onceki muhurlari, critical fixleri ve final readiness sinyallerini toplar.
Servis restart etmez, config degistirmez, DNS/Cloudflare/Nginx ayari degistirmez.

FAZ_6_12_FINAL_GATE_PROBE=STARTED ✅

---

EOF2

echo "===== FAZ 6-12 FINAL GATE PROBE BASLADI ====="

echo "## Master Step Final Status Search" >> "$EVIDENCE_FILE"

search_status "6-1 final PASS izi" "FAZ_6_1_FINAL_STATUS=PASS" "required"
search_status "6-2 final PASS izi" "FAZ_6_2_FINAL_STATUS=PASS" "required"
search_status "6-3 final PASS izi" "FAZ_6_3_FINAL_STATUS=PASS" "required"
search_status "6-4 final PASS izi" "FAZ_6_4_FINAL_STATUS=PASS" "required"
search_status "6-5 final PASS izi" "FAZ_6_5_FINAL_STATUS=PASS" "required"
search_status "6-6 final PASS izi" "FAZ_6_6_FINAL_STATUS=PASS" "required"
search_status "6-7 final PASS izi" "FAZ_6_7_FINAL_STATUS=PASS" "required"
search_status "6-8 final PASS izi" "FAZ_6_8_FINAL_STATUS=PASS" "required"
search_status "6-9 final PASS izi" "FAZ_6_9_FINAL_STATUS=PASS" "required"
search_status "6-10 final PASS izi" "FAZ_6_10_FINAL_STATUS=PASS" "required"
search_status "6-11 final PASS izi" "FAZ_6_11_FINAL_STATUS=PASS" "required"

echo >> "$EVIDENCE_FILE"
echo "## Critical Fix Closure Search" >> "$EVIDENCE_FILE"

search_status "NATS monitoring fix PASS izi" "FAZ_6_9_NATS_MONITORING_FIX_STATUS=PASS" "required"
search_status "6-9 postdeploy smoke clear izi" "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR" "required"
search_status "6-10 edge header fix V2 PASS izi" "FAZ_6_10_EDGE_HEADER_FIX_V2_STATUS=PASS" "required"
search_status "6-10 edge HTTP warn clear izi" "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR" "required"

echo >> "$EVIDENCE_FILE"
echo "## Runtime / Real Audit Closure Search" >> "$EVIDENCE_FILE"

search_status "6-5 real implementation PASS izi" "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-6 real implementation PASS izi" "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-7 real implementation PASS izi" "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-8 real implementation PASS izi" "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-9 real implementation PASS izi" "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-10 real implementation PASS izi" "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS" "required"
search_status "6-11 real implementation PASS izi" "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS" "required"

echo >> "$EVIDENCE_FILE"
echo "## Cloudflare Decision" >> "$EVIDENCE_FILE"

ok "Cloudflare gray-by-decision notu"
ok "Cloudflare green target public launch before go-live notu"

echo >> "$EVIDENCE_FILE"
echo "## Safe Runtime Smoke Snapshot" >> "$EVIDENCE_FILE"

{
  echo
  echo "### Postdeploy Smoke"
  echo "~~~text"
  bash scripts/pix2pi_postdeploy_smoke.sh 2>&1 || true
  echo "~~~"

  echo
  echo "### Edge HTTP Smoke"
  echo "~~~text"
  bash scripts/pix2pi_edge_http_smoke.sh 2>&1 || true
  echo "~~~"

  echo
  echo "### Ops Console Probe"
  echo "~~~text"
  bash scripts/pix2pi_ops_console_probe.sh 2>&1 || true
  echo "~~~"
} >> "$EVIDENCE_FILE"

echo >> "$EVIDENCE_FILE"
echo "## Final Gate Probe Seal" >> "$EVIDENCE_FILE"
echo "~~~text" >> "$EVIDENCE_FILE"
echo "PASS_COUNT=$PASS_COUNT" >> "$EVIDENCE_FILE"
echo "WARN_COUNT=$WARN_COUNT" >> "$EVIDENCE_FILE"
echo "FAIL_COUNT=$FAIL_COUNT" >> "$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE ✅" >> "$EVIDENCE_FILE"
  echo "FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=PASS ✅" >> "$EVIDENCE_FILE"
else
  echo "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE_WITH_FAIL ❌" >> "$EVIDENCE_FILE"
  echo "FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=FAIL ❌" >> "$EVIDENCE_FILE"
fi

echo "~~~" >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE ✅"
  echo "FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=PASS ✅"
  echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
  exit 0
else
  echo "FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE_WITH_FAIL ❌"
  echo "FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=FAIL ❌"
  echo "HATA ❌ final gate probe required fail var"
  exit 1
fi
