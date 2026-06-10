#!/usr/bin/env bash
set -u

DOC="docs/faz5/faz5_master_plan.md"
FAIL=0

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    echo "OK ✅ $label mevcut: $file"
  else
    echo "HATA ❌ $label yok: $file"
    FAIL=1
  fi
}

check_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -Fq "$pattern" "$file"; then
    echo "OK ✅ $label"
  else
    echo "HATA ❌ $label bulunamadi: $pattern"
    FAIL=1
  fi
}

echo "===== FAZ 5 MASTER PLAN TEST BASLADI ====="

check_file "$DOC" "FAZ 5 master plan dokumani"

check_grep "$DOC" "FAZ_NO=5" "faz no"
check_grep "$DOC" "FAZ_NAME=Commercial Operations / Business Readiness" "faz adi"
check_grep "$DOC" "FAZ_PREVIOUS_STATUS=PASS" "onceki faz pass"
check_grep "$DOC" "FAZ_PREVIOUS_SEAL_STATUS=SEALED" "onceki faz sealed"
check_grep "$DOC" "FAZ_5_MASTER_PLAN_STATUS=PASS" "master plan pass"
check_grep "$DOC" "FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED" "master plan sealed"
check_grep "$DOC" "FAZ_5_1_READY=YES" "5-1 ready"

check_grep "$DOC" "5-1 — Commercial Master Plan / Scope Freeze" "5-1 adimi"
check_grep "$DOC" "5-2 — Packages / Pricing Architecture" "5-2 adimi"
check_grep "$DOC" "5-3 — Entitlement Matrix / Module Rights" "5-3 adimi"
check_grep "$DOC" "5-4 — Subscription / Billing / Payment Ops" "5-4 adimi"
check_grep "$DOC" "5-5 — Tenant Lifecycle / Commercial Ops" "5-5 adimi"
check_grep "$DOC" "5-6 — Legal / Compliance / KVKK / Terms" "5-6 adimi"
check_grep "$DOC" "5-7 — Support / SLA / Incident / Escalation" "5-7 adimi"
check_grep "$DOC" "5-8 — Sales / Demo / CRM Operations" "5-8 adimi"
check_grep "$DOC" "5-9 — Revenue Metrics / MRR / ARR / Churn" "5-9 adimi"
check_grep "$DOC" "5-10 — Public / Pricing / Developer Surfaces" "5-10 adimi"
check_grep "$DOC" "5-11 — Commercial Readiness Test Suite" "5-11 adimi"
check_grep "$DOC" "5-12 — FAZ 5 Final Closure / Seal" "5-12 adimi"

check_grep "$DOC" "Her adımda şu kurallar zorunludur:" "uygulama kurali"
check_grep "$DOC" "Önce mevcut dosya yedeği alınır." "yedek kurali"
check_grep "$DOC" "cat <<'EOF'" "cat eof kurali"
check_grep "$DOC" "Test geçmeden sonraki adıma geçilmez." "test gate kurali"

if [ "$FAIL" -eq 0 ]; then
  echo "===== FAZ 5 MASTER PLAN TEST SONUCU: OK ✅ ====="
  exit 0
else
  echo "===== FAZ 5 MASTER PLAN TEST SONUCU: HATA ❌ ====="
  exit 1
fi
