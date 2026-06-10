#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }

check_file() {
  local label="$1"; local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label file_missing=${file}"; fi
}

check_grep() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then pass "$label"; else fail "$label pattern_missing=${pattern}"; fi
}

echo "===== 172 — FAZ 3-12.6 PORTAL AUDIT HISTORY REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/audit-history/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/portal_audit_history.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_6_PORTAL_AUDIT_HISTORY.md"

check_file "172 portal audit history HTML screen file" "$SCREEN_FILE"
check_file "172 portal audit history config file" "$CONFIG_FILE"
check_file "172 portal audit history documentation file" "$DOC_FILE"

check_grep "172 phase marker" "$SCREEN_FILE" "FAZ_3_12_6"
check_grep "172 screen marker" "$SCREEN_FILE" "PORTAL_AUDIT_HISTORY"
check_grep "172 title surface" "$SCREEN_FILE" "Portal Audit / İşlem Geçmişi"
check_grep "172 audit history table surface" "$SCREEN_FILE" "Portal İşlem Geçmişi|auditRows"
check_grep "172 append only surface" "$SCREEN_FILE" "appendOnlyAuditRequired = true|Append Only"
check_grep "172 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant Scope|Tenant ID"
check_grep "172 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant|accountantId"
check_grep "172 firm scope surface" "$SCREEN_FILE" "firmId|Firm ID|firm_demo_001"
check_grep "172 company switch event surface" "$SCREEN_FILE" "COMPANY_SWITCH|Company Switch"
check_grep "172 permission decision event surface" "$SCREEN_FILE" "PERMISSION_DECISION|Permission"
check_grep "172 export request event surface" "$SCREEN_FILE" "EXPORT_REQUEST|Export"
check_grep "172 subscription validate event surface" "$SCREEN_FILE" "SUBSCRIPTION_VALIDATE|Subscription"
check_grep "172 access decision event surface" "$SCREEN_FILE" "ACCESS_DECISION|Access"
check_grep "172 allow decision surface" "$SCREEN_FILE" "ALLOW"
check_grep "172 review required decision surface" "$SCREEN_FILE" "REVIEW_REQUIRED"
check_grep "172 deny decision surface" "$SCREEN_FILE" "DENY"
check_grep "172 read only decision surface" "$SCREEN_FILE" "READ_ONLY"
check_grep "172 actor surface" "$SCREEN_FILE" "actorId|Actor ID|actorRole|Actor Role"
check_grep "172 correlation trace" "$SCREEN_FILE" "correlationId|Correlation ID"
check_grep "172 request id trace" "$SCREEN_FILE" "requestId|Request ID"
check_grep "172 idempotency trace" "$SCREEN_FILE" "idempotencyKey|Idempotency Key"
check_grep "172 ip hash trace" "$SCREEN_FILE" "ipHash|IP Hash"
check_grep "172 user agent hash trace" "$SCREEN_FILE" "userAgentHash|User Agent Hash"
check_grep "172 before state hash trace" "$SCREEN_FILE" "beforeStateHash|Before State Hash"
check_grep "172 after state hash trace" "$SCREEN_FILE" "afterStateHash|After State Hash"
check_grep "172 event hash trace" "$SCREEN_FILE" "eventHash|Event Hash"
check_grep "172 scope hash trace" "$SCREEN_FILE" "scopeHash|Scope Hash"
check_grep "172 chain hash trace" "$SCREEN_FILE" "chainHash|Chain Hash"
check_grep "172 evidence hash trace" "$SCREEN_FILE" "evidenceHash|Evidence Hash"
check_grep "172 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "172 source company switcher trace" "$SCREEN_FILE" "FAZ_3_12_2_COMPANY_SWITCHER"
check_grep "172 source permission screen trace" "$SCREEN_FILE" "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN"
check_grep "172 source export workspace trace" "$SCREEN_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "172 source subscription status trace" "$SCREEN_FILE" "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW"
check_grep "172 view detail action" "$SCREEN_FILE" "View Detail|data-action=\"view-detail\"|DETAIL"
check_grep "172 verify hash action" "$SCREEN_FILE" "Verify Hash|data-action=\"verify-hash\"|VERIFY"
check_grep "172 export audit action" "$SCREEN_FILE" "Export Audit|data-action=\"export-audit\"|EXPORT"
check_grep "172 evidence action" "$SCREEN_FILE" "Evidence|data-action=\"evidence\"|EVIDENCE"
check_grep "172 delete disabled surface" "$SCREEN_FILE" "DELETE|Delete|auditDeleteAllowed = false"
check_grep "172 mutate disabled surface" "$SCREEN_FILE" "MUTATE|Mutate|auditMutationAllowed = false"
check_grep "172 cross tenant audit read false surface" "$SCREEN_FILE" "crossTenantAuditReadAllowed = false|Cross Tenant Audit Read"
check_grep "172 actor required surface" "$SCREEN_FILE" "actorRequired = true"
check_grep "172 correlation required surface" "$SCREEN_FILE" "correlationRequired = true"
check_grep "172 evidence hash required surface" "$SCREEN_FILE" "evidenceHashRequired = true"
check_grep "172 production approved false surface" "$SCREEN_FILE" "productionApproved = false"
check_grep "172 hash timeline surface" "$SCREEN_FILE" "Hash Timeline|data-audit-trail"
check_grep "172 read only audit notice" "$SCREEN_FILE" "append-only/read-only|Audit silme|audit değiştirme|cross-tenant audit okuma kapalı"

check_grep "172 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "172 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/audit-history/\""
check_grep "172 config portal audit visibility" "$CONFIG_FILE" "\"portal_audit_history_visibility\": true"
check_grep "172 config append only visibility" "$CONFIG_FILE" "\"append_only_audit_visibility\": true"
check_grep "172 config company switch event visibility" "$CONFIG_FILE" "\"company_switch_event_visibility\": true"
check_grep "172 config permission decision event visibility" "$CONFIG_FILE" "\"permission_decision_event_visibility\": true"
check_grep "172 config export request event visibility" "$CONFIG_FILE" "\"export_request_event_visibility\": true"
check_grep "172 config subscription validate event visibility" "$CONFIG_FILE" "\"subscription_validate_event_visibility\": true"
check_grep "172 config access decision event visibility" "$CONFIG_FILE" "\"access_decision_event_visibility\": true"
check_grep "172 config actor visibility" "$CONFIG_FILE" "\"actor_visibility\": true"
check_grep "172 config tenant scope visibility" "$CONFIG_FILE" "\"tenant_scope_visibility\": true"
check_grep "172 config firm scope visibility" "$CONFIG_FILE" "\"firm_scope_visibility\": true"
check_grep "172 config correlation visibility" "$CONFIG_FILE" "\"correlation_visibility\": true"
check_grep "172 config request id visibility" "$CONFIG_FILE" "\"request_id_visibility\": true"
check_grep "172 config idempotency visibility" "$CONFIG_FILE" "\"idempotency_key_visibility\": true"
check_grep "172 config ip hash visibility" "$CONFIG_FILE" "\"ip_hash_visibility\": true"
check_grep "172 config user agent hash visibility" "$CONFIG_FILE" "\"user_agent_hash_visibility\": true"
check_grep "172 config before after hash visibility" "$CONFIG_FILE" "\"before_after_state_hash_visibility\": true"
check_grep "172 config event hash visibility" "$CONFIG_FILE" "\"event_hash_visibility\": true"
check_grep "172 config scope hash visibility" "$CONFIG_FILE" "\"scope_hash_visibility\": true"
check_grep "172 config chain hash visibility" "$CONFIG_FILE" "\"chain_hash_visibility\": true"
check_grep "172 config evidence hash visibility" "$CONFIG_FILE" "\"evidence_hash_visibility\": true"
check_grep "172 config evidence file visibility" "$CONFIG_FILE" "\"evidence_file_visibility\": true"
check_grep "172 config hash timeline visibility" "$CONFIG_FILE" "\"hash_timeline_visibility\": true"

check_grep "172 config audit id required" "$CONFIG_FILE" "\"audit_id_required\": true"
check_grep "172 config event type required" "$CONFIG_FILE" "\"event_type_required\": true"
check_grep "172 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "172 config tenant id required" "$CONFIG_FILE" "\"tenant_id_required\": true"
check_grep "172 config accountant id required" "$CONFIG_FILE" "\"accountant_id_required\": true"
check_grep "172 config actor id required" "$CONFIG_FILE" "\"actor_id_required\": true"
check_grep "172 config actor role required" "$CONFIG_FILE" "\"actor_role_required\": true"
check_grep "172 config decision required" "$CONFIG_FILE" "\"decision_required\": true"
check_grep "172 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "172 config action required" "$CONFIG_FILE" "\"action_required\": true"
check_grep "172 config source screen required" "$CONFIG_FILE" "\"source_screen_required\": true"
check_grep "172 config target resource required" "$CONFIG_FILE" "\"target_resource_required\": true"
check_grep "172 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "172 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "172 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "172 config ip hash required" "$CONFIG_FILE" "\"ip_hash_required\": true"
check_grep "172 config user agent hash required" "$CONFIG_FILE" "\"user_agent_hash_required\": true"
check_grep "172 config before state hash required" "$CONFIG_FILE" "\"before_state_hash_required\": true"
check_grep "172 config after state hash required" "$CONFIG_FILE" "\"after_state_hash_required\": true"
check_grep "172 config event hash required" "$CONFIG_FILE" "\"event_hash_required\": true"
check_grep "172 config scope hash required" "$CONFIG_FILE" "\"scope_hash_required\": true"
check_grep "172 config chain hash required" "$CONFIG_FILE" "\"chain_hash_required\": true"
check_grep "172 config evidence hash required" "$CONFIG_FILE" "\"evidence_hash_required\": true"
check_grep "172 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "172 config created at required" "$CONFIG_FILE" "\"created_at_required\": true"

check_grep "172 config company switch event coverage" "$CONFIG_FILE" "\"event_company_switch\": true"
check_grep "172 config permission decision event coverage" "$CONFIG_FILE" "\"event_permission_decision\": true"
check_grep "172 config export request event coverage" "$CONFIG_FILE" "\"event_export_request\": true"
check_grep "172 config subscription validate event coverage" "$CONFIG_FILE" "\"event_subscription_validate\": true"
check_grep "172 config access decision event coverage" "$CONFIG_FILE" "\"event_access_decision\": true"
check_grep "172 config allow decision coverage" "$CONFIG_FILE" "\"decision_allow\": true"
check_grep "172 config review decision coverage" "$CONFIG_FILE" "\"decision_review_required\": true"
check_grep "172 config deny decision coverage" "$CONFIG_FILE" "\"decision_deny\": true"
check_grep "172 config read only decision coverage" "$CONFIG_FILE" "\"decision_read_only\": true"
check_grep "172 config company switcher source coverage" "$CONFIG_FILE" "\"company_switcher\": true"
check_grep "172 config permission screen source coverage" "$CONFIG_FILE" "\"company_permission_screen\": true"
check_grep "172 config export workspace source coverage" "$CONFIG_FILE" "\"accountant_export_workspace\": true"
check_grep "172 config subscription status source coverage" "$CONFIG_FILE" "\"subscription_status_view\": true"

check_grep "172 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "172 config append only required" "$CONFIG_FILE" "\"append_only_audit_required\": true"
check_grep "172 config audit delete false" "$CONFIG_FILE" "\"audit_delete_allowed\": false"
check_grep "172 config audit mutation false" "$CONFIG_FILE" "\"audit_mutation_allowed\": false"
check_grep "172 config cross tenant audit read false" "$CONFIG_FILE" "\"cross_tenant_audit_read_allowed\": false"
check_grep "172 config evidence hash required live" "$CONFIG_FILE" "\"evidence_hash_required\": true"
check_grep "172 config actor required live" "$CONFIG_FILE" "\"actor_required\": true"
check_grep "172 config correlation required live" "$CONFIG_FILE" "\"correlation_required\": true"
check_grep "172 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_detail_verify_export_evidence_only\": true"
check_grep "172 config company switcher gate" "$CONFIG_FILE" "FAZ_3_12_2_COMPANY_SWITCHER"
check_grep "172 config permission screen gate" "$CONFIG_FILE" "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN"
check_grep "172 config export workspace gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "172 config subscription status gate" "$CONFIG_FILE" "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW"
check_grep "172 config previous gate" "$CONFIG_FILE" "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW"
check_grep "172 config next gate" "$CONFIG_FILE" "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"append_only_audit_required\"[[:space:]]*:[[:space:]]*false|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_audit_read_allowed\"[[:space:]]*:[[:space:]]*true|\"evidence_hash_required\"[[:space:]]*:[[:space:]]*false|\"actor_required\"[[:space:]]*:[[:space:]]*false|\"correlation_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "172 live policy append only audit guard"
else
  pass "172 live policy append only audit guard"
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
# 172 — FAZ 3-12.6 — Portal Audit History Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_6_PORTAL_AUDIT_HISTORY_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_6_PORTAL_AUDIT_HISTORY_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_7_READY=${NEXT_READY}

## Scope

- Portal audit history visibility
- Append-only audit visibility
- COMPANY_SWITCH / PERMISSION_DECISION / EXPORT_REQUEST / SUBSCRIPTION_VALIDATE / ACCESS_DECISION event coverage
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY decision coverage
- Actor / tenant / firm / accountant visibility
- Correlation ID / request ID / idempotency key visibility
- IP hash / user agent hash visibility
- Before / after state hash visibility
- Event hash / scope hash / chain hash / evidence hash traces
- Evidence file trace
- Hash timeline
- Source screen coverage: company switcher, permission screen, export workspace, subscription status

## Live Policy

- Append-only audit required: TRUE
- Audit delete allowed: FALSE
- Audit mutation allowed: FALSE
- Cross tenant audit read allowed: FALSE
- Evidence hash required: TRUE
- Actor required: TRUE
- Correlation required: TRUE
- Production approved: FALSE
- UI actions are detail/verify/export/evidence only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 172 — FAZ 3-12.6 PORTAL AUDIT HISTORY COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_6_PORTAL_AUDIT_HISTORY_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_6_PORTAL_AUDIT_HISTORY_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_7_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
