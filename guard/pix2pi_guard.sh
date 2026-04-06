set -euo pipefail
cd /root/pix2pi/pix2pi-SaaS

# ---------- load thresholds ----------
GATES_FILE="guard/quality_gates.env"
if [ -f "$GATES_FILE" ]; then
  # shellcheck disable=SC1090
  . "$GATES_FILE"
fi

: "${MAX_SHARED_PKGS:=5}"
: "${MIN_V1_SCHEMAS:=2}"
: "${MAX_SUSPECT_QUERIES:=0}"
: "${RUN_GO_MOD_TIDY:=1}"

ok()   { echo "OK ✅ $1"; }
warn() { echo "UYARI ⚠️ $1"; }
fail() { echo "HATA ❌ $1"; exit 1; }

has_rg=0
command -v rg >/dev/null 2>&1 && has_rg=1

grep_like() {
  # usage: grep_like <pattern> <path>
  if [ "$has_rg" -eq 1 ]; then
    rg -n "$1" "$2"
  else
    grep -RIn --include='*.go' "$1" "$2"
  fi
}

echo "============================================================"
echo "PIX2PI GUARD (quality gates) ✅"
echo "============================================================"
echo "MAX_SHARED_PKGS=$MAX_SHARED_PKGS"
echo "MIN_V1_SCHEMAS=$MIN_V1_SCHEMAS"
echo "MAX_SUSPECT_QUERIES=$MAX_SUSPECT_QUERIES"
echo "RUN_GO_MOD_TIDY=$RUN_GO_MOD_TIDY"
echo "------------------------------------------------------------"

# ---------- Gate A: Kernel pollution (0 tolerance) ----------
echo
echo "[Gate A] Kernel kirlenmesi (kernel -> services import YASAK)"
if grep_like 'pix2pi-SaaS/services/' kernel >/dev/null 2>&1; then
  echo "Bulunanlar:"
  grep_like 'pix2pi-SaaS/services/' kernel || true
  fail "kernel içinde services import bulundu."
fi
ok "kernel -> services import yok"

# ---------- Gate B: Shared safety ----------
echo
echo "[Gate B] Shared güvenliği (behavior/shared çöp olmasın)"
# forbidden patterns inside shared
FORBIDDEN_PATTERNS='(SELECT |INSERT |UPDATE |DELETE |gorm\.|sql\.Open|repository|Repo|service|Service|ApplyDiscount|Calculate|Workflow)'
if [ -d shared ]; then
  if [ "$has_rg" -eq 1 ]; then
    if rg -n --glob 'shared/**/*.go' "$FORBIDDEN_PATTERNS" shared >/dev/null 2>&1; then
      echo "Bulunanlar:"
      rg -n --glob 'shared/**/*.go' "$FORBIDDEN_PATTERNS" shared || true
      fail "shared içinde behavior/db/repo/service kokusu var. Shared sadece agreement olmalı."
    fi
  else
    # best-effort grep fallback
    if grep -RIn --include='*.go' -E "$FORBIDDEN_PATTERNS" shared >/dev/null 2>&1; then
      echo "Bulunanlar:"
      grep -RIn --include='*.go' -E "$FORBIDDEN_PATTERNS" shared || true
      fail "shared içinde behavior/db/repo/service kokusu var."
    fi
  fi

  # package count limit
  PKG_COUNT="$(find shared -type f -name '*.go' -maxdepth 4 -print0 2>/dev/null | xargs -0 -I{} dirname {} | sort -u | wc -l | tr -d ' ')"
  if [ "${PKG_COUNT:-0}" -gt "$MAX_SHARED_PKGS" ]; then
    warn "shared paket sayısı yüksek: $PKG_COUNT > $MAX_SHARED_PKGS"
    warn "Çözüm: shared'i küçült, domain logic'i services içine taşı."
    fail "shared package limit aşıldı"
  fi
  ok "shared temiz + paket sayısı OK ($PKG_COUNT <= $MAX_SHARED_PKGS)"
else
  warn "shared klasörü yok (atlandı)"
fi

# ---------- Gate C: Tenant isolation (best-effort static checks) ----------
echo
echo "[Gate C] Tenant isolation (best-effort)"
SUSPECT=0

# 1) migrations/services içinde tenant_id yoksa şüpheli
if [ -d migrations/services ]; then
  if [ "$has_rg" -eq 1 ]; then
    # tablo yaratma var ama tenant_id geçmiyorsa şüpheli say
    if rg -n 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
      # çok kaba bir kontrol: tenant_id hiç geçmiyorsa şüpheli +1
      if ! rg -n 'tenant_id' migrations/services >/dev/null 2>&1; then
        SUSPECT=$((SUSPECT+1))
      fi
    fi
  else
    if grep -RIn 'CREATE TABLE' migrations/services >/dev/null 2>&1; then
      if ! grep -RIn 'tenant_id' migrations/services >/dev/null 2>&1; then
        SUSPECT=$((SUSPECT+1))
      fi
    fi
  fi
fi

# 2) repository içinde tenant filtresi izleri yoksa şüpheli
if [ -d services ]; then
  if [ "$has_rg" -eq 1 ]; then
    # repo dosyalarında SELECT var ama tenant_id/tenantID hiç yoksa şüpheli say
    # (kaba ama iyi alarm)
    while IFS= read -r f; do
      if rg -n 'SELECT ' "$f" >/dev/null 2>&1; then
        if ! rg -n '(tenant_id|tenantID)' "$f" >/dev/null 2>&1; then
          SUSPECT=$((SUSPECT+1))
        fi
      fi
    done < <(find services -type f -name '*repo*.go' -o -name '*repository*.go' 2>/dev/null | sort)
  fi
fi

echo "Şüpheli tenant kontrol sayısı: $SUSPECT"
if [ "$SUSPECT" -gt "$MAX_SUSPECT_QUERIES" ]; then
  fail "Tenant isolation şüpheli: $SUSPECT > $MAX_SUSPECT_QUERIES (repo/migration kontrollerini gözden geçir)"
fi
ok "Tenant isolation statik alarm OK (suspect=$SUSPECT)"

# ---------- Gate D: Contracts versioning ----------
echo
echo "[Gate D] Contracts (v1) disiplini"
[ -d shared/contracts/v1 ] || fail "shared/contracts/v1 yok"
[ -d shared/contracts/v1/events ] || fail "shared/contracts/v1/events yok"
SCHEMA_COUNT="$(ls -1 shared/contracts/v1/events 2>/dev/null | wc -l | tr -d ' ')"
if [ "$SCHEMA_COUNT" -lt "$MIN_V1_SCHEMAS" ]; then
  fail "v1 event schema az: $SCHEMA_COUNT < $MIN_V1_SCHEMAS"
fi
ok "Contracts v1 OK (schemas=$SCHEMA_COUNT)"

# ---------- Gate E: Event backbone presence ----------
echo
echo "[Gate E] Event backbone"
[ -f kernel/events/publisher/publisher.go ] || fail "kernel/events/publisher/publisher.go yok"
[ -f kernel/events/publisher/noop.go ] || fail "kernel/events/publisher/noop.go yok"
ok "Event backbone dosyaları OK"

# ---------- Gate F: Build/Test ----------
echo
echo "[Gate F] go test / build"
if [ "$RUN_GO_MOD_TIDY" = "1" ]; then
  go mod tidy >/tmp/go_mod_tidy_guard.log 2>&1 || (tail -n 80 /tmp/go_mod_tidy_guard.log && fail "go mod tidy hata")
  ok "go mod tidy OK"
else
  warn "go mod tidy atlandı (RUN_GO_MOD_TIDY=0)"
fi

go test ./... >/tmp/go_test_guard.log 2>&1 || (tail -n 120 /tmp/go_test_guard.log && fail "go test ./... hata")
ok "go test ./... OK"

echo
echo "============================================================"
echo "TÜM QUALITY GATES GEÇTİ ✅"
echo "============================================================"
