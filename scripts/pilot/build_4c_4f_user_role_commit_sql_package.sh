#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREVIEW_SQL="sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql"
COMMIT_SQL="sql/pilot/faz4c/4c_4f_commit_user_role_uzmanparcaci.sql"

DRY_RUN_REPORT="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_test_report.md"
DRY_RUN_MAIN_REPORT="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_report.md"
FIX4_REPORT="reports/pilot/faz4c/4c_4d_fix4_password_hash_role_name_report.md"

DOC_FILE="docs/pilot/faz4c/4c_4f_user_role_commit_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_4f_user_role_commit_sql_package_report.md"

echo "===== 4C-4F USER ROLE COMMIT SQL PACKAGE / APPLY GUARD ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

[ -f "$PREVIEW_SQL" ] || fail "Preview SQL yok: $PREVIEW_SQL"
[ -f "$DRY_RUN_REPORT" ] || fail "4C-4E dry-run test report yok: $DRY_RUN_REPORT"
[ -f "$DRY_RUN_MAIN_REPORT" ] || fail "4C-4E dry-run main report yok: $DRY_RUN_MAIN_REPORT"
[ -f "$FIX4_REPORT" ] || fail "4C-4D-FIX4 report yok: $FIX4_REPORT"

grep -q "4C_4E_TEST_STATUS=PASS" "$DRY_RUN_REPORT" || fail "4C-4E test PASS degil"
grep -q "4C_4E_SQL_EXECUTION_STATUS=PASS" "$DRY_RUN_REPORT" || fail "4C-4E SQL execution PASS degil"
grep -q "4C_4E_ROLLBACK_VERIFIED=YES" "$DRY_RUN_REPORT" || fail "4C-4E rollback verified YES degil"
grep -q "4C_4E_DB_WRITE_APPLIED=NO" "$DRY_RUN_REPORT" || fail "4C-4E DB write NO degil"
grep -q "4C_4F_READY=YES" "$DRY_RUN_REPORT" || fail "4C-4F ready YES degil"

grep -q "4C_4D_FIX4_STATUS=PASS" "$FIX4_REPORT" || fail "4C-4D-FIX4 PASS degil"
grep -q "4C_4D_FIX4_PASSWORD_HASH_MAPPING=YES" "$FIX4_REPORT" || fail "password_hash mapping YES degil"
grep -q "4C_4D_FIX4_ROLE_NAME_MAPPING=YES" "$FIX4_REPORT" || fail "role_name mapping YES degil"

grep -q "ROLLBACK;" "$PREVIEW_SQL" || fail "Preview SQL ROLLBACK icermiyor"

if grep -q "COMMIT;" "$PREVIEW_SQL"; then
  fail "Preview SQL COMMIT icermemeli"
fi

python3 - <<'PY'
from pathlib import Path

preview = Path("sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql")
commit = Path("sql/pilot/faz4c/4c_4f_commit_user_role_uzmanparcaci.sql")

text = preview.read_text()

text = text.replace(
    "-- FAZ 4C — 4C-4D User / Role SQL Package Preview",
    "-- FAZ 4C — 4C-4F User / Role Commit SQL Package"
)

text = text.replace(
    "--   This SQL file is preview only.\n--   It ends with ROLLBACK intentionally.\n--   4C-4D does NOT perform permanent DB write.",
    "--   This SQL file is a COMMIT package.\n--   4C-4F only creates this file.\n--   4C-4F does NOT execute it.\n--   Execution must happen only in 4C-4G."
)

text = text.replace(
    "ROLLBACK;\n\n-- Note:\n-- This preview intentionally ends with ROLLBACK.\n-- Later commit/apply steps will be generated only after successful dry-run.",
    """DO $$
DECLARE
  final_user_count integer;
  final_role_count integer;
  final_assignment_count integer;
BEGIN
  SELECT count(*) INTO final_user_count
  FROM auth.users
  WHERE lower(email::text)=lower('uzmanparcaci1@gmail.com');

  SELECT count(*) INTO final_role_count
  FROM auth.roles
  WHERE upper(role_code::text)=upper('PILOT_ADMIN');

  SELECT count(*) INTO final_assignment_count
  FROM auth.user_role_assignments a
  JOIN auth.users u ON u.id = a.user_id
  JOIN auth.roles r ON r.id = a.role_id
  WHERE lower(u.email::text)=lower('uzmanparcaci1@gmail.com')
    AND upper(r.role_code::text)=upper('PILOT_ADMIN');

  IF final_user_count <> 1 THEN
    RAISE EXCEPTION 'User verification failed. final_user_count=%', final_user_count;
  END IF;

  IF final_role_count <> 1 THEN
    RAISE EXCEPTION 'Role verification failed. final_role_count=%', final_role_count;
  END IF;

  IF final_assignment_count <> 1 THEN
    RAISE EXCEPTION 'Assignment verification failed. final_assignment_count=%', final_assignment_count;
  END IF;
END
$$;

COMMIT;

-- Note:
-- This commit package must be executed only by 4C-4G guarded apply step."""
)

commit.write_text(text)
PY

[ -f "$COMMIT_SQL" ] || fail "Commit SQL olusmadi: $COMMIT_SQL"

grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL icinde COMMIT yok"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi

grep -q "INSERT INTO auth.users" "$COMMIT_SQL" || fail "Commit SQL auth.users insert yok"
grep -q "INSERT INTO auth.roles" "$COMMIT_SQL" || fail "Commit SQL auth.roles insert yok"
grep -q "INSERT INTO auth.user_role_assignments" "$COMMIT_SQL" || fail "Commit SQL auth.user_role_assignments insert yok"
grep -q "password_hash" "$COMMIT_SQL" || fail "Commit SQL password_hash yok"
grep -q "role_name" "$COMMIT_SQL" || fail "Commit SQL role_name yok"
grep -q "PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED" "$COMMIT_SQL" || fail "Commit SQL temp password hash yok"

{
  echo "# FAZ 4C — 4C-4F User Role Commit SQL Package / Apply Guard"
  echo
  echo "## Amac"
  echo
  echo "uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment icin COMMIT SQL paketini hazirlamak."
  echo
  echo "Bu adim SQL dosyasini hazirlar ama calistirmaz."
  echo
  echo "---"
  echo
  echo "## On kosullar"
  echo
  echo "4C_4E_TEST_STATUS=PASS"
  echo "4C_4E_SQL_EXECUTION_STATUS=PASS"
  echo "4C_4E_ROLLBACK_VERIFIED=YES"
  echo "4C_4E_DB_WRITE_APPLIED=NO"
  echo "4C_4D_FIX4_PASSWORD_HASH_MAPPING=YES"
  echo "4C_4D_FIX4_ROLE_NAME_MAPPING=YES"
  echo
  echo "---"
  echo
  echo "## Commit SQL"
  echo
  echo "COMMIT_SQL=$COMMIT_SQL"
  echo
  echo "---"
  echo
  echo "## Guvenlik karari"
  echo
  echo "4C-4F dosya uretir."
  echo "4C-4F DB apply yapmaz."
  echo "DB apply sadece 4C-4G icinde yapilacaktir."
  echo
  echo "---"
  echo
  echo "## Parola karari"
  echo
  echo "password_hash gecici placeholder ile olusturulur:"
  echo "PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED"
  echo
  echo "Bu kullanici icin canli giris acilmadan once parola reset / davet akisi zorunlu kapidir."
  echo
  echo "---"
  echo
  echo "## Status"
  echo
  echo "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS"
  echo "4C_4F_COMMIT_SQL_FILE_CREATED=YES"
  echo "4C_4F_COMMIT_SQL_HAS_COMMIT=YES"
  echo "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO"
  echo "4C_4F_PASSWORD_HASH_MAPPING=YES"
  echo "4C_4F_ROLE_NAME_MAPPING=YES"
  echo "4C_4F_DB_WRITE_APPLIED=NO"
  echo "4C_4G_READY=YES"
} > "$DOC_FILE"

{
  echo "# FAZ 4C — 4C-4F User Role Commit SQL Package Report"
  echo
  echo "Step: 4C-4F"
  echo "Blok: User / Role Commit SQL Package / Apply Guard"
  echo "Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')"
  echo
  echo "## Test sonucu"
  echo
  echo "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS"
  echo "4C_4F_COMMIT_SQL_FILE_CREATED=YES"
  echo "4C_4F_COMMIT_SQL_FILE=$COMMIT_SQL"
  echo "4C_4F_COMMIT_SQL_HAS_COMMIT=YES"
  echo "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO"
  echo "4C_4F_SELECTED_USER_TABLE=auth.users"
  echo "4C_4F_SELECTED_ROLE_TABLE=auth.roles"
  echo "4C_4F_SELECTED_MAPPING_TABLE=auth.user_role_assignments"
  echo "4C_4F_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com"
  echo "4C_4F_PILOT_ROLE_CODE=PILOT_ADMIN"
  echo "4C_4F_PASSWORD_HASH_MAPPING=YES"
  echo "4C_4F_ROLE_NAME_MAPPING=YES"
  echo "4C_4F_DB_WRITE_APPLIED=NO"
  echo "4C_4G_READY=YES"
  echo
  echo "## Sonuc"
  echo
  echo "User/role COMMIT SQL paketi hazirlandi."
  echo "Bu adimda DB yazma yapilmadi."
  echo "Sonraki adim: 4C-4G User / Role Apply Execution."
} > "$REPORT_FILE"

echo "OK ✅ User role commit SQL paketi olusturuldu: $COMMIT_SQL"
echo "OK ✅ User role commit SQL report olusturuldu: $REPORT_FILE"

echo
echo "===== 4C-4F OZET ====="
echo "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS ✅"
echo "4C_4F_COMMIT_SQL_FILE_CREATED=YES ✅"
echo "4C_4F_COMMIT_SQL_HAS_COMMIT=YES ✅"
echo "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO ✅"
echo "4C_4F_PASSWORD_HASH_MAPPING=YES ✅"
echo "4C_4F_ROLE_NAME_MAPPING=YES ✅"
echo "4C_4F_DB_WRITE_APPLIED=NO ✅"
echo "4C_4G_READY=YES ✅"
