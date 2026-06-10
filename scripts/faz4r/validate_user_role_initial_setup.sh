#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_1_3_kullanici_rol_ilk_kurulumu.v1.json}"
TEMPLATE_FILE="${TEMPLATE_FILE:-configs/faz4r/user_role_initial_setup.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "USER_ROLE_SETUP_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  fail "TEMPLATE_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$TEMPLATE_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$TEMPLATE_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
template_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
template = json.loads(template_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 197, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_1_3", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("setup_policy", {})
required_roles = set(config.get("required_roles", []))
required_permissions = set(config.get("required_permissions", []))

tenant = payload.get("tenant", {})
users = payload.get("users", [])
roles = payload.get("roles", [])
permissions = set(payload.get("permissions", []))
role_permissions = payload.get("role_permissions", {})
assignments = payload.get("assignments", [])
invite_policy = payload.get("invite_policy", {})
mfa_policy = payload.get("mfa_policy", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(payload.get("setup_status") == policy.get("setup_status_required"), "SETUP_STATUS_NOT_READY")
require(tenant.get("tenant_id"), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == policy.get("tenant_scope_required"), "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == policy.get("pilot_mode_required"), "PILOT_MODE_INVALID")

tenant_id = tenant.get("tenant_id")

role_codes = {role.get("role_code") for role in roles if role.get("role_code")}
missing_roles = sorted(required_roles - role_codes)
require(not missing_roles, "REQUIRED_ROLES_MISSING:" + ",".join(missing_roles))

missing_permissions = sorted(required_permissions - permissions)
require(not missing_permissions, "REQUIRED_PERMISSIONS_MISSING:" + ",".join(missing_permissions))

for role_code in required_roles:
    assigned_permissions = set(role_permissions.get(role_code, []))
    require(assigned_permissions, f"ROLE_PERMISSION_EMPTY:{role_code}")
    unknown_permissions = sorted(assigned_permissions - permissions)
    require(not unknown_permissions, f"ROLE_PERMISSION_UNKNOWN:{role_code}:{','.join(unknown_permissions)}")

tenant_admin_permissions = set(role_permissions.get("TENANT_ADMIN", []))
for permission in required_permissions:
    require(permission in tenant_admin_permissions, f"TENANT_ADMIN_PERMISSION_MISSING:{permission}")

user_ids = {user.get("user_id") for user in users if user.get("user_id")}
assignment_user_ids = {assignment.get("user_id") for assignment in assignments if assignment.get("user_id")}
assignment_role_codes = {assignment.get("role_code") for assignment in assignments if assignment.get("role_code")}

for assignment in assignments:
    require(assignment.get("tenant_id") == tenant_id, f"ASSIGNMENT_TENANT_MISMATCH:{assignment.get('user_id')}")
    require(assignment.get("status") == "ACTIVE", f"ASSIGNMENT_NOT_ACTIVE:{assignment.get('user_id')}")
    require(assignment.get("user_id") in user_ids, f"ASSIGNMENT_USER_UNKNOWN:{assignment.get('user_id')}")
    require(assignment.get("role_code") in role_codes, f"ASSIGNMENT_ROLE_UNKNOWN:{assignment.get('role_code')}")

for user in users:
    require(user.get("tenant_id") == tenant_id, f"USER_TENANT_MISMATCH:{user.get('user_id')}")
    require(user.get("status") in {"INVITE_READY", "ACTIVE"}, f"USER_STATUS_INVALID:{user.get('user_id')}")
    require(user.get("mfa_required") is True, f"USER_MFA_REQUIRED_FALSE:{user.get('user_id')}")
    email = user.get("email", "")
    require(bool(re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", email)), f"USER_EMAIL_INVALID:{user.get('user_id')}")

admin_assignments = [
    assignment for assignment in assignments
    if assignment.get("role_code") == "TENANT_ADMIN" and assignment.get("status") == "ACTIVE"
]
require(len(admin_assignments) >= policy.get("min_tenant_admin_count", 1), "TENANT_ADMIN_ASSIGNMENT_MISSING")

admin_user_count = summary.get("admin_user_count")
operator_user_count = summary.get("operator_user_count")
accountant_user_count = summary.get("accountant_user_count")

require(isinstance(admin_user_count, int), "ADMIN_USER_COUNT_INVALID")
require(isinstance(operator_user_count, int), "OPERATOR_USER_COUNT_INVALID")
require(isinstance(accountant_user_count, int), "ACCOUNTANT_USER_COUNT_INVALID")

if isinstance(admin_user_count, int):
    require(admin_user_count >= policy.get("min_tenant_admin_count", 1), "ADMIN_USER_COUNT_TOO_LOW")
    require(admin_user_count <= policy.get("max_admin_user_count", 3), "ADMIN_USER_COUNT_EXCEEDS_LIMIT")
if isinstance(operator_user_count, int):
    require(operator_user_count <= policy.get("max_operator_user_count", 10), "OPERATOR_USER_COUNT_EXCEEDS_LIMIT")
if isinstance(accountant_user_count, int):
    require(accountant_user_count <= policy.get("max_accountant_user_count", 5), "ACCOUNTANT_USER_COUNT_EXCEEDS_LIMIT")

require(invite_policy.get("status") == policy.get("invite_policy_status_required"), "INVITE_POLICY_NOT_READY")
require(invite_policy.get("send_real_email") is False, "REAL_INVITE_EMAIL_NOT_ALLOWED")
require(invite_policy.get("invite_token_required") is True, "INVITE_TOKEN_REQUIRED_FALSE")
require(invite_policy.get("manual_review_required") is True, "INVITE_MANUAL_REVIEW_REQUIRED_FALSE")

require(mfa_policy.get("status") in set(policy.get("mfa_policy_allowed_statuses", [])), "MFA_POLICY_STATUS_INVALID")
require(mfa_policy.get("mfa_required_for_admin") is True, "MFA_REQUIRED_FOR_ADMIN_FALSE")
require(mfa_policy.get("mfa_required_for_all_pilot_users") is True, "MFA_REQUIRED_FOR_ALL_FALSE")

require(summary.get("critical_issue_count") == 0, "CRITICAL_ISSUE_COUNT_MUST_BE_ZERO")
require(summary.get("audit_evidence_status") == "READY", "AUDIT_EVIDENCE_STATUS_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if errors:
    print("USER_ROLE_SETUP_STATUS=FAIL")
    for error in errors:
        print(f"USER_ROLE_SETUP_FAIL={error}")
    sys.exit(1)

print("USER_ROLE_SETUP_STATUS=PASS")
print(f"USER_ROLE_SETUP_TENANT_ID={tenant_id}")
print("USER_ROLE_SETUP_REQUIRED_ROLES_STATUS=PASS")
print("USER_ROLE_SETUP_REQUIRED_PERMISSIONS_STATUS=PASS")
print("USER_ROLE_SETUP_ASSIGNMENTS_STATUS=PASS")
print("USER_ROLE_SETUP_INVITE_POLICY=READY")
print("USER_ROLE_SETUP_EXTERNAL_POLICY=CLOSED")
PY_EOF
