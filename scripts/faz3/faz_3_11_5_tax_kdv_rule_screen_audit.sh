#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 159 — FAZ 3-11.5 TAX KDV RULE SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/tax-kdv-rules/index.html"
CONFIG_FILE="configs/faz3/web/tax_kdv_rule_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_5_TAX_KDV_RULE_SCREEN.md"

check_file "159 tax/KDV rule HTML screen file" "$SCREEN_FILE"
check_file "159 tax/KDV rule config file" "$CONFIG_FILE"
check_file "159 tax/KDV rule documentation file" "$DOC_FILE"

check_grep "159 phase marker" "$SCREEN_FILE" "FAZ_3_11_5"
check_grep "159 screen marker" "$SCREEN_FILE" "TAX_KDV_RULE_SCREEN"
check_grep "159 title surface" "$SCREEN_FILE" "Vergi / KDV Rule Ekranı"
check_grep "159 rule catalog surface" "$SCREEN_FILE" "Vergi Rule Kataloğu"
check_grep "159 KDV surface" "$SCREEN_FILE" "KDV"
check_grep "159 KDV 20 surface" "$SCREEN_FILE" "KDV_TR_OUTPUT_20|KDV 20|20%"
check_grep "159 KDV 10 surface" "$SCREEN_FILE" "KDV_TR_INPUT_10|KDV 10|10%"
check_grep "159 KDV zero surface" "$SCREEN_FILE" "KDV_TR_ZERO|KDV 0|0%"
check_grep "159 stopaj surface" "$SCREEN_FILE" "STOPAJ|Stopaj"
check_grep "159 exemption surface" "$SCREEN_FILE" "TAX_EXEMPTION|İstisna|Muafiyet"
check_grep "159 rule version surface" "$SCREEN_FILE" "version|Version|activeVersion"
check_grep "159 active rule surface" "$SCREEN_FILE" "ACTIVE|Active"
check_grep "159 draft rule surface" "$SCREEN_FILE" "DRAFT|Draft"
check_grep "159 canary rollout surface" "$SCREEN_FILE" "CANARY|Canary|canaryPercent"
check_grep "159 rollback surface" "$SCREEN_FILE" "ROLLBACK|Rollback"
check_grep "159 activate action surface" "$SCREEN_FILE" "ACTIVATE|Activate"
check_grep "159 audit action surface" "$SCREEN_FILE" "AUDIT|Audit"
check_grep "159 rollout strategy surface" "$SCREEN_FILE" "rolloutStrategy|Rollout Strategy|BLUE_GREEN|FULL"
check_grep "159 legal reference surface" "$SCREEN_FILE" "legalReference|Legal Reference"
check_grep "159 effective date surface" "$SCREEN_FILE" "effectiveFrom|Effective From|effectiveTo"
check_grep "159 approval status surface" "$SCREEN_FILE" "approvalStatus|Approval"
check_grep "159 TDHP output KDV account surface" "$SCREEN_FILE" "391.01.20|Hesaplanan KDV"
check_grep "159 TDHP input KDV account surface" "$SCREEN_FILE" "191.01.10|İndirilecek KDV"
check_grep "159 TDHP stopaj account surface" "$SCREEN_FILE" "360.01.20|Ödenecek Stopaj"
check_grep "159 account code surface" "$SCREEN_FILE" "accountCode|Account Code"
check_grep "159 account name surface" "$SCREEN_FILE" "accountName|Account Name"
check_grep "159 rate BPS surface" "$SCREEN_FILE" "rateBps|Rate BPS"
check_grep "159 exemption allowed surface" "$SCREEN_FILE" "exemptionAllowed|Exemption Allowed"
check_grep "159 reverse charge surface" "$SCREEN_FILE" "reverseChargeAllowed|Reverse Charge"
check_grep "159 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "159 rule artifact hash trace" "$SCREEN_FILE" "ruleArtifactHash|Rule Artifact Hash"
check_grep "159 config artifact hash trace" "$SCREEN_FILE" "configArtifactHash|Config Artifact Hash"
check_grep "159 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "159 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "159 filter bar surface" "$SCREEN_FILE" "searchInput|taxTypeFilter|statusFilter|rateFilter|actionFilter"
check_grep "159 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "159 operation action panel" "$SCREEN_FILE" "data-operation-actions|Rule Operasyonları"
check_grep "159 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "159 legal review required surface" "$SCREEN_FILE" "legalReviewRequired = true|Legal Review: REQUIRED"
check_grep "159 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "159 real external gate closed surface" "$SCREEN_FILE" "realExternalTaxProviderGate = \"CLOSED\""
check_grep "159 no production activation notice" "$SCREEN_FILE" "production activation değildir|hukuk|mali müşavir"

check_grep "159 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "159 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/tax-kdv-rules/\""
check_grep "159 config KDV visibility" "$CONFIG_FILE" "\"kdv_rule_visibility\": true"
check_grep "159 config KDV 20 visibility" "$CONFIG_FILE" "\"kdv_20_visibility\": true"
check_grep "159 config KDV 10 visibility" "$CONFIG_FILE" "\"kdv_10_visibility\": true"
check_grep "159 config KDV 0 visibility" "$CONFIG_FILE" "\"kdv_0_visibility\": true"
check_grep "159 config stopaj visibility" "$CONFIG_FILE" "\"stopaj_rule_visibility\": true"
check_grep "159 config tax exemption visibility" "$CONFIG_FILE" "\"tax_exemption_visibility\": true"
check_grep "159 config rollout visibility" "$CONFIG_FILE" "\"rule_version_rollout_visibility\": true"
check_grep "159 config canary visibility" "$CONFIG_FILE" "\"canary_rollout_visibility\": true"
check_grep "159 config rollback visibility" "$CONFIG_FILE" "\"rollback_visibility\": true"
check_grep "159 config audit persistence visibility" "$CONFIG_FILE" "\"audit_persistence_visibility\": true"
check_grep "159 config TDHP account visibility" "$CONFIG_FILE" "\"tdhp_account_visibility\": true"
check_grep "159 config legal reference visibility" "$CONFIG_FILE" "\"legal_reference_visibility\": true"
check_grep "159 config effective date visibility" "$CONFIG_FILE" "\"effective_date_visibility\": true"
check_grep "159 config approval status visibility" "$CONFIG_FILE" "\"approval_status_visibility\": true"
check_grep "159 config tenant indicator required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "159 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "159 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "159 config rule id required" "$CONFIG_FILE" "\"rule_id_required\": true"
check_grep "159 config rule code required" "$CONFIG_FILE" "\"rule_code_required\": true"
check_grep "159 config active rule version required" "$CONFIG_FILE" "\"active_rule_version_required\": true"
check_grep "159 config effective date required" "$CONFIG_FILE" "\"effective_date_required\": true"
check_grep "159 config legal reference required" "$CONFIG_FILE" "\"legal_reference_required\": true"
check_grep "159 config approved by required" "$CONFIG_FILE" "\"approved_by_required_for_activation\": true"
check_grep "159 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "159 config rule artifact hash required" "$CONFIG_FILE" "\"rule_artifact_hash_required\": true"
check_grep "159 config config artifact hash required" "$CONFIG_FILE" "\"config_artifact_hash_required\": true"
check_grep "159 config TDHP output account required" "$CONFIG_FILE" "\"tdhp_output_kdv_account_required\": true"
check_grep "159 config TDHP input account required" "$CONFIG_FILE" "\"tdhp_input_kdv_account_required\": true"
check_grep "159 config TDHP stopaj account required" "$CONFIG_FILE" "\"tdhp_stopaj_account_required\": true"
check_grep "159 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "159 config real external tax provider closed" "$CONFIG_FILE" "\"real_external_tax_provider_gate_status\": \"CLOSED\""
check_grep "159 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "159 config legal review required" "$CONFIG_FILE" "\"legal_review_required\": true"
check_grep "159 config financial advisor review required" "$CONFIG_FILE" "\"financial_advisor_review_required\": true"
check_grep "159 config dry run until legal approval" "$CONFIG_FILE" "\"ui_actions_are_dry_run_until_legal_approval\": true"
check_grep "159 config KDV backend gate" "$CONFIG_FILE" "FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION"
check_grep "159 config stopaj backend gate" "$CONFIG_FILE" "FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION"
check_grep "159 config exemption backend gate" "$CONFIG_FILE" "FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION"
check_grep "159 config rollout backend gate" "$CONFIG_FILE" "FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT"
check_grep "159 config audit persistence backend gate" "$CONFIG_FILE" "FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE"
check_grep "159 config tax smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_2_TAX_SMOKE"
check_grep "159 config next gate" "$CONFIG_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"production_approved\"[[:space:]]*:[[:space:]]*true|\"legal_review_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "159 live policy closed guard"
else
  pass "159 live policy closed guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 159 — FAZ 3-11.5 — Tax / KDV Rule Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_5_TAX_KDV_RULE_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_5_TAX_KDV_RULE_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_3_READY=${NEXT_READY}

## Scope

- KDV rule surface
- KDV 20 / KDV 10 / KDV 0 surface
- Stopaj rule surface
- Tax exemption / muafiyet rule surface
- Rule version rollout surface
- Canary rollout surface
- Rollback surface
- Audit persistence surface
- TDHP 391 / 191 / 360 account traces
- Legal reference / effective date / approval status visibility
- Rule artifact hash / config artifact hash / audit hash traces
- Tenant / correlation / request / idempotency traces
- Production approved FALSE
- Legal review REQUIRED
- Real external provider calls CLOSED

## Live Policy

- Production tax rule activation: CLOSED
- Legal review: REQUIRED
- Financial advisor review: REQUIRED
- Real external provider calls: CLOSED
- UI actions are dry-run until legal approval
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 159 — FAZ 3-11.5 TAX KDV RULE SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_5_TAX_KDV_RULE_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_5_TAX_KDV_RULE_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
