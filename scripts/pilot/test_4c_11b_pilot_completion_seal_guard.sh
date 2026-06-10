#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_11a_final_closure_inventory_report.md"
CRITERIA_ENV="docs/pilot/faz4c/4c_11a_completion_seal_criteria.env"

GUARD_DOC="docs/pilot/faz4c/4c_11b_pilot_completion_seal_guard.md"
REPORT_FILE="reports/pilot/faz4c/4c_11b_pilot_completion_seal_guard_report.md"

echo "===== 4C-11B PILOT COMPLETION SEAL GUARD TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

get_env_value() {
  local key="$1"
  grep -E "^${key}=" "$CRITERIA_ENV" | tail -n 1 | cut -d'=' -f2- | sed 's/^"//; s/"$//'
}

[ -f "$PREV_REPORT" ] || fail "4C-11A report yok: $PREV_REPORT"
pass "4C-11A report var"

[ -f "$CRITERIA_ENV" ] || fail "4C-11A criteria env yok: $CRITERIA_ENV"
pass "4C-11A criteria env var"

grep -q "4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS" "$PREV_REPORT" || fail "4C-11A inventory PASS degil"
pass "4C-11A inventory PASS"

grep -q "4C_11A_REQUIRED_FINAL_CLOSURE_COUNT=10" "$PREV_REPORT" || fail "4C-11A required closure count 10 degil"
pass "4C-11A required closure count 10"

grep -q "4C_11A_FOUND_FINAL_CLOSURE_COUNT=10" "$PREV_REPORT" || fail "4C-11A found closure count 10 degil"
pass "4C-11A found closure count 10"

grep -q "4C_11A_MISSING_FINAL_CLOSURE_COUNT=0" "$PREV_REPORT" || fail "4C-11A missing closure count 0 degil"
pass "4C-11A missing closure count 0"

grep -q "4C_11A_COMPLETION_SEAL_CRITERIA_STATUS=FROZEN" "$PREV_REPORT" || fail "4C-11A criteria FROZEN degil"
pass "4C-11A criteria FROZEN"

grep -q "4C_11B_READY=YES" "$PREV_REPORT" || fail "4C-11B ready YES yok"
pass "4C-11B ready YES"

FINAL_GO_NO_GO_DECISION="$(get_env_value FINAL_GO_NO_GO_DECISION)"
HANDOFF_PACKAGE_STATUS="$(get_env_value HANDOFF_PACKAGE_STATUS)"
REQUIRED_FINAL_CLOSURE_COUNT="$(get_env_value REQUIRED_FINAL_CLOSURE_COUNT)"
FOUND_FINAL_CLOSURE_COUNT="$(get_env_value FOUND_FINAL_CLOSURE_COUNT)"
MISSING_FINAL_CLOSURE_COUNT="$(get_env_value MISSING_FINAL_CLOSURE_COUNT)"
PILOT_TENANT_STATUS="$(get_env_value PILOT_TENANT_STATUS)"
PILOT_USER_ROLE_STATUS="$(get_env_value PILOT_USER_ROLE_STATUS)"
DATA_IMPORT_STATUS="$(get_env_value DATA_IMPORT_STATUS)"
TECHNICAL_UAT_STATUS="$(get_env_value TECHNICAL_UAT_STATUS)"
BUSINESS_ACCEPTANCE_STATUS="$(get_env_value BUSINESS_ACCEPTANCE_STATUS)"
BUG_BLOCKER_BURNDOWN_STATUS="$(get_env_value BUG_BLOCKER_BURNDOWN_STATUS)"
FOLLOWUP_ACTION_CLASSIFICATION_STATUS="$(get_env_value FOLLOWUP_ACTION_CLASSIFICATION_STATUS)"
HANDOFF_EVIDENCE_PACKAGE_STATUS="$(get_env_value HANDOFF_EVIDENCE_PACKAGE_STATUS)"
CRITICAL_BLOCKER_COUNT="$(get_env_value CRITICAL_BLOCKER_COUNT)"
BLOCKING_ACTION_COUNT="$(get_env_value BLOCKING_ACTION_COUNT)"
COMPLETION_SEAL_CRITERIA_STATUS="$(get_env_value COMPLETION_SEAL_CRITERIA_STATUS)"
DB_WRITE_APPLIED="$(get_env_value DB_WRITE_APPLIED)"

[ "$FINAL_GO_NO_GO_DECISION" = "GO" ] || fail "Final GO/NO-GO GO degil: $FINAL_GO_NO_GO_DECISION"
pass "Final GO/NO-GO GO"

[ "$HANDOFF_PACKAGE_STATUS" = "READY" ] || fail "Handoff package READY degil: $HANDOFF_PACKAGE_STATUS"
pass "Handoff package READY"

[ "$REQUIRED_FINAL_CLOSURE_COUNT" = "10" ] || fail "Required closure count 10 degil"
pass "Required closure count 10"

[ "$FOUND_FINAL_CLOSURE_COUNT" = "10" ] || fail "Found closure count 10 degil"
pass "Found closure count 10"

[ "$MISSING_FINAL_CLOSURE_COUNT" = "0" ] || fail "Missing closure count 0 degil"
pass "Missing closure count 0"

[ "$PILOT_TENANT_STATUS" = "VERIFIED" ] || fail "Pilot tenant VERIFIED degil"
pass "Pilot tenant VERIFIED"

[ "$PILOT_USER_ROLE_STATUS" = "VERIFIED" ] || fail "Pilot user role VERIFIED degil"
pass "Pilot user role VERIFIED"

[ "$DATA_IMPORT_STATUS" = "PASS" ] || fail "Data import PASS degil"
pass "Data import PASS"

[ "$TECHNICAL_UAT_STATUS" = "PASS" ] || fail "Technical UAT PASS degil"
pass "Technical UAT PASS"

[ "$BUSINESS_ACCEPTANCE_STATUS" = "PASS" ] || fail "Business acceptance PASS degil"
pass "Business acceptance PASS"

[ "$BUG_BLOCKER_BURNDOWN_STATUS" = "PASS" ] || fail "Bug/blocker burn-down PASS degil"
pass "Bug/blocker burn-down PASS"

[ "$FOLLOWUP_ACTION_CLASSIFICATION_STATUS" = "PASS" ] || fail "Follow-up classification PASS degil"
pass "Follow-up classification PASS"

[ "$HANDOFF_EVIDENCE_PACKAGE_STATUS" = "PASS" ] || fail "Handoff evidence package PASS degil"
pass "Handoff evidence package PASS"

[ "$CRITICAL_BLOCKER_COUNT" = "0" ] || fail "Critical blocker count 0 degil"
pass "Critical blocker count 0"

[ "$BLOCKING_ACTION_COUNT" = "0" ] || fail "Blocking action count 0 degil"
pass "Blocking action count 0"

[ "$COMPLETION_SEAL_CRITERIA_STATUS" = "FROZEN" ] || fail "Completion seal criteria FROZEN degil"
pass "Completion seal criteria FROZEN"

[ "$DB_WRITE_APPLIED" = "NO" ] || fail "DB write applied NO degil"
pass "DB write applied NO"

cat <<DOC_EOF > "$GUARD_DOC"
# FAZ 4C — 4C-11B Pilot Completion Seal Guard

## Blok

4C-11B — Pilot Completion Seal Guard

## Ana karar

FAZ 4C pilot completion seal guard PASS almıştır.

uzmanparcaci gerçek pilot çalışması completion seal için uygundur.

Bu adım DB'ye yazmaz.

---

## 1. Kaynak

4C-11A sonucu:

4C_11A_FINAL_CLOSURE_INVENTORY_STATUS=PASS
4C_11A_REQUIRED_FINAL_CLOSURE_COUNT=10
4C_11A_FOUND_FINAL_CLOSURE_COUNT=10
4C_11A_MISSING_FINAL_CLOSURE_COUNT=0
4C_11A_COMPLETION_SEAL_CRITERIA_STATUS=FROZEN
4C_11B_READY=YES

---

## 2. Guard kriterleri

| Kriter | Sonuç |
|--------|-------|
| FINAL_GO_NO_GO_DECISION | $FINAL_GO_NO_GO_DECISION |
| HANDOFF_PACKAGE_STATUS | $HANDOFF_PACKAGE_STATUS |
| REQUIRED_FINAL_CLOSURE_COUNT | $REQUIRED_FINAL_CLOSURE_COUNT |
| FOUND_FINAL_CLOSURE_COUNT | $FOUND_FINAL_CLOSURE_COUNT |
| MISSING_FINAL_CLOSURE_COUNT | $MISSING_FINAL_CLOSURE_COUNT |
| PILOT_TENANT_STATUS | $PILOT_TENANT_STATUS |
| PILOT_USER_ROLE_STATUS | $PILOT_USER_ROLE_STATUS |
| DATA_IMPORT_STATUS | $DATA_IMPORT_STATUS |
| TECHNICAL_UAT_STATUS | $TECHNICAL_UAT_STATUS |
| BUSINESS_ACCEPTANCE_STATUS | $BUSINESS_ACCEPTANCE_STATUS |
| BUG_BLOCKER_BURNDOWN_STATUS | $BUG_BLOCKER_BURNDOWN_STATUS |
| FOLLOWUP_ACTION_CLASSIFICATION_STATUS | $FOLLOWUP_ACTION_CLASSIFICATION_STATUS |
| HANDOFF_EVIDENCE_PACKAGE_STATUS | $HANDOFF_EVIDENCE_PACKAGE_STATUS |
| CRITICAL_BLOCKER_COUNT | $CRITICAL_BLOCKER_COUNT |
| BLOCKING_ACTION_COUNT | $BLOCKING_ACTION_COUNT |

---

## 3. Completion seal kararı

PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED

Karar:

- Final GO kararı var
- 10 ana final closure dosyası mevcut
- Handoff package READY
- Critical blocker yok
- Blocking action yok
- Teknik UAT PASS
- Business acceptance PASS
- Bug/blocker burn-down PASS
- Evidence package PASS

---

## 4. Scope guard

4C-11B içinde yapılmayanlar:

- DB write yok
- Runtime değişikliği yok
- Canlı entegrasyon yok
- ERP core product apply yok
- UI geliştirme yok

---

## 5. Final status

4C_11B_PILOT_COMPLETION_SEAL_GUARD_STATUS=PASS
4C_11B_COMPLETION_SEAL_GUARD_STATUS=PASS
4C_11B_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED
4C_11B_FINAL_GO_NO_GO_DECISION=GO
4C_11B_HANDOFF_PACKAGE_STATUS=READY
4C_11B_REQUIRED_FINAL_CLOSURE_COUNT=10
4C_11B_FOUND_FINAL_CLOSURE_COUNT=10
4C_11B_MISSING_FINAL_CLOSURE_COUNT=0
4C_11B_CRITICAL_BLOCKER_COUNT=0
4C_11B_BLOCKING_ACTION_COUNT=0
4C_11B_DB_WRITE_APPLIED=NO
4C_11C_READY=YES
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-11B Pilot Completion Seal Guard Report

Step: 4C-11B
Blok: Pilot Completion Seal Guard
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_11B_PILOT_COMPLETION_SEAL_GUARD_STATUS=PASS
4C_11B_COMPLETION_SEAL_GUARD_STATUS=PASS
4C_11B_PREVIOUS_BLOCK_STATUS=PASS
4C_11B_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED
4C_11B_FINAL_GO_NO_GO_DECISION=GO
4C_11B_HANDOFF_PACKAGE_STATUS=READY
4C_11B_REQUIRED_FINAL_CLOSURE_COUNT=10
4C_11B_FOUND_FINAL_CLOSURE_COUNT=10
4C_11B_MISSING_FINAL_CLOSURE_COUNT=0
4C_11B_PILOT_TENANT_STATUS=VERIFIED
4C_11B_PILOT_USER_ROLE_STATUS=VERIFIED
4C_11B_DATA_IMPORT_STATUS=PASS
4C_11B_TECHNICAL_UAT_STATUS=PASS
4C_11B_BUSINESS_ACCEPTANCE_STATUS=PASS
4C_11B_BUG_BLOCKER_BURNDOWN_STATUS=PASS
4C_11B_FOLLOWUP_ACTION_CLASSIFICATION_STATUS=PASS
4C_11B_HANDOFF_EVIDENCE_PACKAGE_STATUS=PASS
4C_11B_CRITICAL_BLOCKER_COUNT=0
4C_11B_BLOCKING_ACTION_COUNT=0
4C_11B_DB_WRITE_APPLIED=NO
4C_11C_READY=YES

## Karar

Pilot completion seal guard PASS.
Completion seal recommendation APPROVED.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-11C FAZ 4C Final Closure Report Package.

## Sonuc

4C-11B Pilot Completion Seal Guard tamamlandı.
REPORT_EOF

pass "Guard doc olusturuldu: $GUARD_DOC"
pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-11B TEST SONUCU ====="
echo "4C_11B_PILOT_COMPLETION_SEAL_GUARD_STATUS=PASS ✅"
echo "4C_11B_PILOT_COMPLETION_SEAL_RECOMMENDATION=APPROVED ✅"
echo "4C_11B_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_11B_HANDOFF_PACKAGE_STATUS=READY ✅"
echo "4C_11B_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_11B_BLOCKING_ACTION_COUNT=0 ✅"
echo "4C_11B_DB_WRITE_APPLIED=NO ✅"
echo "4C_11C_READY=YES ✅"
