#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/pix2pi/pix2pi-SaaS"
cd "$ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_TXT="$ROOT/reports/event_platform_final_suite_run_${TS}.txt"
REPORT_MD="$ROOT/reports/event_platform_final_suite_run_${TS}.md"
LATEST_TXT="$ROOT/reports/event_platform_final_suite_run_latest.txt"
LATEST_MD="$ROOT/reports/event_platform_final_suite_run_latest.md"
TMP_DIR="$ROOT/tmp/event_platform_final_suite_run_${TS}"

mkdir -p "$ROOT/reports" "$ROOT/tmp" "$TMP_DIR"

echo "===== EVENT PLATFORM FINAL SUITE RUN 1 ====="
echo "Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "Root: $ROOT"
echo

echo "===== STEP 1 - TEST DOSYALARINI TOPLA ====="
find . \
  -type f \
  -name '*_test.go' \
  ! -path './backups/*' \
  ! -path './tmp/*' \
  ! -path './reports/*' \
  | sort > "$TMP_DIR/all_test_files.txt"

ALL_TEST_COUNT="$(wc -l < "$TMP_DIR/all_test_files.txt" | tr -d ' ')"
echo "ALL_TEST_COUNT=$ALL_TEST_COUNT"
echo "OK ✅ tum test dosyalari toplandi"
echo

echo "===== STEP 2 - FINAL SUITE MATRIX URET ====="
export ROOT TMP_DIR
python3 <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT"])
tmp_dir = Path(os.environ["TMP_DIR"])
all_files_path = tmp_dir / "all_test_files.txt"
matrix_path = tmp_dir / "suite_matrix.tsv"
human_path = tmp_dir / "suite_matrix_human.txt"

test_kw = re.compile(r"(event|replay|idempot|dlq|retry|schema|metadata|lifecycle|concurr|persist|usercreated|user_created|consumer)", re.I)
path_kw = re.compile(r"(user-created-consumer|idempotency|dlq|retry|replay|event|store)", re.I)

pkg_map = {}
file_map = {}

files = [line.strip() for line in all_files_path.read_text(encoding="utf-8").splitlines() if line.strip()]

for rel in files:
    p = root / rel
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        text = ""

    tests = re.findall(r"^func\s+(Test[A-Za-z0-9_]+)\s*\(", text, re.M)
    matched = [t for t in tests if test_kw.search(t)]

    if path_kw.search(rel):
        if matched:
            selected = matched
        else:
            selected = tests
    else:
        selected = matched

    selected = sorted(set(selected))
    if not selected:
        continue

    d = os.path.dirname(rel)
    pkg = "." if d == "" else f"./{d}"

    pkg_map.setdefault(pkg, set()).update(selected)
    file_map.setdefault(pkg, set()).add(rel)

with matrix_path.open("w", encoding="utf-8") as f:
    for pkg in sorted(pkg_map):
        tests = sorted(pkg_map[pkg])
        regex = "^(" + "|".join(tests) + ")$"
        files_for_pkg = sorted(file_map[pkg])
        f.write(pkg + "\t" + regex + "\t" + ",".join(tests) + "\t" + ",".join(files_for_pkg) + "\n")

with human_path.open("w", encoding="utf-8") as f:
    for pkg in sorted(pkg_map):
        tests = sorted(pkg_map[pkg])
        files_for_pkg = sorted(file_map[pkg])
        f.write(f"PKG: {pkg}\n")
        f.write("TESTS:\n")
        for t in tests:
            f.write(f"- {t}\n")
        f.write("FILES:\n")
        for fp in files_for_pkg:
            f.write(f"- {fp}\n")
        f.write("\n")

print(f"PKG_COUNT={len(pkg_map)}")
print(human_path.read_text(encoding='utf-8'))
PY

PKG_COUNT="$(grep -E '^PKG:' "$TMP_DIR/suite_matrix_human.txt" | wc -l | tr -d ' ')"
echo "PKG_COUNT=$PKG_COUNT"
echo "OK ✅ final suite matrix uretildi"
echo

echo "===== STEP 3 - MATRIX ONIZLEME ====="
sed -n '1,220p' "$TMP_DIR/suite_matrix_human.txt" || true
echo
echo "OK ✅ matrix onizleme tamam"
echo

echo "===== STEP 4 - FINAL SUITE CALISTIR ====="
PASS_PKG_COUNT=0
FAIL_PKG_COUNT=0
: > "$TMP_DIR/run_summary.txt"

while IFS=$'\t' read -r pkg regex tests files; do
  [ -n "${pkg:-}" ] || continue

  SAFE_NAME="$(echo "$pkg" | sed 's#[/.]#_#g')"
  LOG_FILE="$TMP_DIR/${SAFE_NAME}.log"

  echo "---- PKG: $pkg ----"
  echo "REGEX: $regex"
  echo "TESTS: $tests"
  echo "FILES: $files"

  if go test "$pkg" -run "$regex" -count=1 -v >"$LOG_FILE" 2>&1; then
    PASS_PKG_COUNT=$((PASS_PKG_COUNT+1))
    echo "PASS | $pkg | $tests" | tee -a "$TMP_DIR/run_summary.txt"
    sed -n '1,120p' "$LOG_FILE" || true
  else
    FAIL_PKG_COUNT=$((FAIL_PKG_COUNT+1))
    echo "FAIL | $pkg | $tests" | tee -a "$TMP_DIR/run_summary.txt"
    sed -n '1,160p' "$LOG_FILE" || true
  fi

  echo
done < "$TMP_DIR/suite_matrix.tsv"

echo "PASS_PKG_COUNT=$PASS_PKG_COUNT"
echo "FAIL_PKG_COUNT=$FAIL_PKG_COUNT"
echo "OK ✅ final suite calistirma tamam"
echo

echo "===== STEP 5 - RAPOR YAZ ====="
{
  echo "time=$(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "root=$ROOT"
  echo "all_test_count=$ALL_TEST_COUNT"
  echo "pkg_count=$PKG_COUNT"
  echo "pass_pkg_count=$PASS_PKG_COUNT"
  echo "fail_pkg_count=$FAIL_PKG_COUNT"
  echo
  echo "[suite_matrix]"
  cat "$TMP_DIR/suite_matrix_human.txt"
  echo
  echo "[run_summary]"
  cat "$TMP_DIR/run_summary.txt"
} > "$REPORT_TXT"

{
  echo "# Event Platform Final Suite Run 1"
  echo
  echo "- Tarih: $(date '+%Y-%m-%d %H:%M:%S %z')"
  echo "- Root: $ROOT"
  echo "- Tum test dosyalari: $ALL_TEST_COUNT"
  echo "- Paket sayisi: $PKG_COUNT"
  echo "- Gecen paket: $PASS_PKG_COUNT"
  echo "- Kalan paket: $FAIL_PKG_COUNT"
  echo
  echo "## Suite Matrix"
  echo
  sed 's/^/- /' "$TMP_DIR/suite_matrix_human.txt"
  echo
  echo "## Run Summary"
  echo
  sed 's/^/- /' "$TMP_DIR/run_summary.txt"
} > "$REPORT_MD"

cp -f "$REPORT_TXT" "$LATEST_TXT"
cp -f "$REPORT_MD" "$LATEST_MD"

echo "OK ✅ txt rapor yazildi: $REPORT_TXT"
echo "OK ✅ md rapor yazildi: $REPORT_MD"
echo "OK ✅ latest txt: $LATEST_TXT"
echo "OK ✅ latest md: $LATEST_MD"
echo

echo "===== STEP 6 - FINAL ====="
echo "PKG_COUNT=$PKG_COUNT"
echo "PASS_PKG_COUNT=$PASS_PKG_COUNT"
echo "FAIL_PKG_COUNT=$FAIL_PKG_COUNT"

if [ "$PKG_COUNT" -eq 0 ]; then
  echo "HATA ❌ hic final suite paketi secilemedi"
  exit 1
fi

if [ "$FAIL_PKG_COUNT" -eq 0 ]; then
  echo "OK ✅ EVENT-PLATFORM-FINAL-SUITE-RUN-1 basarili"
else
  echo "HATA ❌ event platform final suite icinde failing paket var"
  exit 1
fi
