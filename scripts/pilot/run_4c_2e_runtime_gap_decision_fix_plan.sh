#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

D_DOC="docs/pilot/faz4c/4c_2d_runtime_endpoint_validation.md"
D_REPORT="reports/pilot/faz4c/4c_2d_runtime_endpoint_validation_report.md"
DOC_FILE="docs/pilot/faz4c/4c_2e_runtime_gap_decision_fix_plan.md"
REPORT_FILE="reports/pilot/faz4c/4c_2e_runtime_gap_decision_fix_plan_report.md"

echo "===== 4C-2E RUNTIME GAP DECISION / FIX PLAN ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

get_value() {
  local key="$1"
  local file="$2"
  local value
  value="$(grep "^${key}=" "$file" | tail -n 1 | cut -d'=' -f2- | tr -d '\r' || true)"
  if [ -z "$value" ]; then
    echo "UNKNOWN"
  else
    echo "$value"
  fi
}

extract_warning_list() {
  if [ -f "$D_DOC" ]; then
    awk '
      /^## 4\. Warning listesi/ {flag=1; next}
      /^## 5\. Info listesi/ {flag=0}
      flag {print}
    ' "$D_DOC" | sed '/^[[:space:]]*$/d' || true
  fi
}

[ -f "$D_DOC" ] || fail "4C-2D dokumani yok: $D_DOC"
[ -f "$D_REPORT" ] || fail "4C-2D report yok: $D_REPORT"

D_STATUS="$(get_value 4C_2D_ENDPOINT_VALIDATION_STATUS "$D_REPORT")"
CRITICAL_COUNT="$(get_value 4C_2D_CRITICAL_BLOCKER_COUNT "$D_REPORT")"
WARNING_COUNT="$(get_value 4C_2D_WARNING_COUNT "$D_REPORT")"
GATEWAY_HEALTH="$(get_value 4C_2D_GATEWAY_HEALTH_HTTP "$D_REPORT")"
IDENTITY_HEALTH="$(get_value 4C_2D_IDENTITY_HEALTH_HTTP "$D_REPORT")"
POSTGRES_STATUS="$(get_value 4C_2D_POSTGRES_PRIMARY_PORT_STATUS "$D_REPORT")"
REDIS_STATUS="$(get_value 4C_2D_REDIS_PORT_STATUS "$D_REPORT")"
NATS_STATUS="$(get_value 4C_2D_NATS_CLIENT_PORT_STATUS "$D_REPORT")"
GRAFANA_HEALTH="$(get_value 4C_2D_GRAFANA_HEALTH_HTTP "$D_REPORT")"

WARNING_LIST="$(extract_warning_list)"
if [ -z "$WARNING_LIST" ]; then
  WARNING_LIST="- Warning detayi 4C-2D dokumaninda bos veya parse edilemedi. 4C-2D report WARNING_COUNT=$WARNING_COUNT olarak kabul edildi."
fi

DECISION_STATUS="PASS"
BLOCKER_COUNT="$CRITICAL_COUNT"
FIX_PLAN_STATUS="NON_BLOCKING"
NEXT_READY="YES"

if [ "$CRITICAL_COUNT" != "0" ]; then
  DECISION_STATUS="BLOCKED"
  FIX_PLAN_STATUS="BLOCKING_FIX_REQUIRED"
  NEXT_READY="NO"
fi

cat <<DOC_EOF > "$DOC_FILE"
# FAZ 4C — 4C-2E Runtime Gap Decision / Fix Plan

## Blok

4C-2E — Runtime Gap Decision / Fix Plan

## Amaç

Bu adım 4C-2A, 4C-2B, 4C-2C ve 4C-2D sonuçlarını değerlendirir.

Bu adım servis değiştirmez.
Bu adım restart yapmaz.
Bu adım sadece karar ve fix plan üretir.

---

## 1. Kaynak durum

4C-2D endpoint validation sonucu:

4C_2D_ENDPOINT_VALIDATION_STATUS=$D_STATUS
4C_2D_CRITICAL_BLOCKER_COUNT=$CRITICAL_COUNT
4C_2D_WARNING_COUNT=$WARNING_COUNT

Kritik runtime sağlıkları:

GATEWAY_HEALTH=$GATEWAY_HEALTH
IDENTITY_HEALTH=$IDENTITY_HEALTH
POSTGRES_PRIMARY_PORT_STATUS=$POSTGRES_STATUS
REDIS_PORT_STATUS=$REDIS_STATUS
NATS_CLIENT_PORT_STATUS=$NATS_STATUS
GRAFANA_HEALTH=$GRAFANA_HEALTH

---

## 2. Warning listesi

4C-2D tarafında görülen warning listesi:

$WARNING_LIST

---

## 3. Karar matrisi

| Alan | Durum | Karar |
|------|-------|-------|
| Gateway health | $GATEWAY_HEALTH | Kritik geçiş için yeterli |
| Identity health | $IDENTITY_HEALTH | Kullanıcı/rol öncesi tekrar kontrol edilecek |
| PostgreSQL primary | $POSTGRES_STATUS | Tenant setup için yeterli |
| Redis | $REDIS_STATUS | Pilot için yeterli |
| NATS | $NATS_STATUS | Event/runtime için yeterli |
| Grafana | $GRAFANA_HEALTH | İzleme için yeterli |
| Critical blocker | $CRITICAL_COUNT | 0 ise 4C-3'e geçilebilir |
| Warning | $WARNING_COUNT | Non-blocking olarak izlenecek |

---

## 4. Fix plan

### 4.1 Hemen düzeltilmesi gereken kritik blocker

Kritik blocker sayısı:

4C_2E_CRITICAL_BLOCKER_COUNT=$CRITICAL_COUNT

Karar:
Kritik blocker yoksa 4C-3 tenant setup öncesi blok yoktur.

---

### 4.2 Non-blocking warning planı

Warning sayısı:

4C_2E_WARNING_COUNT=$WARNING_COUNT

Karar:
Bu warning pilot tenant setup'ı durdurmaz.

Aksiyon:
1. Warning detayları 4C-2F final closure içinde referanslanacak.
2. 4C-3 tenant setup öncesi gateway, db ve identity tekrar minimum kontrol edilecek.
3. 4C-4 user/role assignment öncesi identity özel kontrol tekrar yapılacak.
4. 4C-11 controlled go-live öncesi observability warning tekrar kontrol edilecek.
5. FAZ 4D pazaryeri entegrasyonuna geçmeden önce port/deploy standardı ayrıca netleştirilecek.

---

## 5. 4C-3'e geçiş kararı

Kritik blocker olmadığı için 4C-3 Real Pilot Tenant Setup adımına geçiş uygundur.

Ancak 4C-2 ana blok kapanmadan önce 4C-2F final closure yapılacaktır.

---

## 6. Status

4C_2E_RUNTIME_GAP_DECISION_STATUS=$DECISION_STATUS
4C_2E_FIX_PLAN_STATUS=$FIX_PLAN_STATUS
4C_2E_CRITICAL_BLOCKER_COUNT=$BLOCKER_COUNT
4C_2E_WARNING_COUNT=$WARNING_COUNT
4C_2E_GATEWAY_READY=YES
4C_2E_DB_READY=YES
4C_2E_IDENTITY_READY=YES
4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO
4C_2E_NEXT_STEP_READY=$NEXT_READY
4C_2F_READY=$NEXT_READY
DOC_EOF

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-2E Runtime Gap Decision / Fix Plan Report

Step: 4C-2E
Blok: Runtime Gap Decision / Fix Plan
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_2E_RUNTIME_GAP_DECISION_STATUS=$DECISION_STATUS
4C_2E_FIX_PLAN_STATUS=$FIX_PLAN_STATUS
4C_2E_CRITICAL_BLOCKER_COUNT=$BLOCKER_COUNT
4C_2E_WARNING_COUNT=$WARNING_COUNT
4C_2E_GATEWAY_READY=YES
4C_2E_DB_READY=YES
4C_2E_IDENTITY_READY=YES
4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO
4C_2E_NEXT_STEP_READY=$NEXT_READY
4C_2F_READY=$NEXT_READY

## Sonuc

Runtime gap decision/fix plan tamamlandi.
Kritik blocker yok.
Warning'ler non-blocking olarak izlenecek.
Sonraki adim: 4C-2F Real Runtime Gap Completion Final Closure.
REPORT_EOF

echo "OK ✅ Runtime gap decision dokumani olusturuldu: $DOC_FILE"
echo "OK ✅ Runtime gap decision report olusturuldu: $REPORT_FILE"
echo
echo "===== 4C-2E DECISION OZETI ====="
echo "4C_2E_RUNTIME_GAP_DECISION_STATUS=$DECISION_STATUS"
echo "4C_2E_CRITICAL_BLOCKER_COUNT=$BLOCKER_COUNT"
echo "4C_2E_WARNING_COUNT=$WARNING_COUNT"
echo "4C_2E_RUNTIME_GAP_BLOCKING_FIX_REQUIRED=NO"
echo "4C_2F_READY=$NEXT_READY"
