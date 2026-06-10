#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_4_2_yardim_merkezi_icerigi.v1.json}"
HELP_FILE="${HELP_FILE:-configs/faz4r/help_center_content.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "HELP_CENTER_CONTENT_ERROR=$1"
  exit 1
}

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$HELP_FILE" ]; then
  fail "HELP_FILE_NOT_FOUND"
fi

if [ -z "$INPUT_FILE" ]; then
  INPUT_FILE="$HELP_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$HELP_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
help_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
help_artifact = json.loads(help_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def non_empty(value):
    return isinstance(value, str) and value.strip() != ""

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 211, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_4_2", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("help_center_policy", {})
required_articles = set(config.get("required_articles", []))

require(payload.get("help_center_status") == policy.get("help_center_status_required"), "HELP_CENTER_STATUS_NOT_READY")
require(payload.get("help_center_mode") == policy.get("help_center_mode_required"), "HELP_CENTER_MODE_NOT_CONTROLLED_PILOT")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

tenant = payload.get("tenant", {})
require(non_empty(tenant.get("tenant_id")), "TENANT_ID_REQUIRED")
require(tenant.get("tenant_scope") == "SINGLE_TENANT", "TENANT_SCOPE_INVALID")
require(tenant.get("pilot_mode") == "CONTROLLED_PILOT", "PILOT_MODE_INVALID")

chain_dependencies = payload.get("chain_dependencies", {})
for dependency in config.get("depends_on", []):
    require(chain_dependencies.get(dependency) == "PASS", f"CHAIN_DEPENDENCY_NOT_PASS:{dependency}")

articles = payload.get("articles", [])
navigation = payload.get("navigation", {})
summary = payload.get("summary", {})
external_policy = payload.get("external_policy", {})

require(isinstance(articles, list), "ARTICLES_NOT_LIST")

provided_articles = []
ready_count = 0
missing_count = 0
required_fail_count = 0

if isinstance(articles, list):
    for idx, article in enumerate(articles, start=1):
        prefix = f"ARTICLE_{idx}"
        require(isinstance(article, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(article, dict):
            continue

        code = article.get("code")
        status = article.get("status")
        required = article.get("required")
        evidence_ref = article.get("evidence_ref")
        category = article.get("category")
        title = article.get("title")
        keywords = article.get("search_keywords")

        require(non_empty(code), f"{prefix}_CODE_REQUIRED")
        if non_empty(code):
            provided_articles.append(code)

        require(status in {"READY", "MISSING", "DRAFT"}, f"{prefix}_STATUS_INVALID")
        require(non_empty(category), f"{prefix}_CATEGORY_REQUIRED")
        require(non_empty(title), f"{prefix}_TITLE_REQUIRED")
        require(isinstance(keywords, list) and len(keywords) > 0, f"{prefix}_SEARCH_KEYWORDS_REQUIRED")

        if status == "READY":
            ready_count += 1
        else:
            missing_count += 1

        if required is True:
            require(status == policy.get("required_article_status_required"), f"REQUIRED_ARTICLE_NOT_READY:{code}")
            require(non_empty(evidence_ref), f"REQUIRED_EVIDENCE_MISSING:{code}")
            if status != "READY":
                required_fail_count += 1

provided_set = set(provided_articles)
missing_articles = sorted(required_articles - provided_set)
require(not missing_articles, "REQUIRED_ARTICLES_MISSING:" + ",".join(missing_articles))
require(len(provided_articles) == len(provided_set), "DUPLICATE_ARTICLE_CODE_FOUND")

total_article_count = summary.get("total_article_count")
summary_ready_article_count = summary.get("ready_article_count")
summary_missing_article_count = summary.get("missing_article_count")
summary_required_fail_count = summary.get("required_fail_count")
critical_issue_count = summary.get("critical_issue_count")

require(isinstance(total_article_count, int) and total_article_count >= 0, "TOTAL_ARTICLE_COUNT_INVALID")
require(isinstance(summary_ready_article_count, int) and summary_ready_article_count >= 0, "READY_ARTICLE_COUNT_INVALID")
require(isinstance(summary_missing_article_count, int) and summary_missing_article_count >= 0, "MISSING_ARTICLE_COUNT_INVALID")
require(isinstance(summary_required_fail_count, int) and summary_required_fail_count >= 0, "REQUIRED_FAIL_COUNT_INVALID")
require(isinstance(critical_issue_count, int) and critical_issue_count >= 0, "CRITICAL_ISSUE_COUNT_INVALID")

if isinstance(total_article_count, int):
    require(total_article_count == len(articles), "TOTAL_ARTICLE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_ready_article_count, int):
    require(summary_ready_article_count == ready_count, "READY_ARTICLE_COUNT_RECONCILIATION_FAILED")
if isinstance(summary_missing_article_count, int):
    require(summary_missing_article_count == missing_count, "MISSING_ARTICLE_COUNT_RECONCILIATION_FAILED")
    require(summary_missing_article_count == policy.get("missing_article_count_required"), "MISSING_ARTICLE_COUNT_NOT_ZERO")
if isinstance(summary_required_fail_count, int):
    require(summary_required_fail_count == required_fail_count, "REQUIRED_FAIL_COUNT_RECONCILIATION_FAILED")
    require(summary_required_fail_count == policy.get("required_fail_count_required"), "REQUIRED_FAIL_COUNT_NOT_ZERO")
if isinstance(critical_issue_count, int):
    require(critical_issue_count == policy.get("critical_issue_count_required"), "CRITICAL_ISSUE_COUNT_NOT_ZERO")

require(summary.get("training_set_status") == policy.get("training_set_status_required"), "TRAINING_SET_STATUS_NOT_PASS")
require(summary.get("searchable_index_status") == policy.get("searchable_index_status_required"), "SEARCHABLE_INDEX_STATUS_NOT_READY")
require(summary.get("support_route_status") == policy.get("support_route_status_required"), "SUPPORT_ROUTE_STATUS_NOT_READY")
require(summary.get("completion_checklist_status") == policy.get("completion_checklist_status_required"), "COMPLETION_CHECKLIST_NOT_READY")
require(summary.get("live_external_policy_status") == policy.get("live_external_policy_status_required"), "LIVE_EXTERNAL_POLICY_STATUS_NOT_CLOSED")

require(navigation.get("searchable_index_status") == "READY", "NAVIGATION_SEARCHABLE_INDEX_NOT_READY")
require(navigation.get("support_route_status") == "READY", "NAVIGATION_SUPPORT_ROUTE_NOT_READY")
require(navigation.get("completion_checklist_status") == "READY", "NAVIGATION_COMPLETION_CHECKLIST_NOT_READY")
require(navigation.get("default_language") == "tr-TR", "DEFAULT_LANGUAGE_NOT_TR")
require(navigation.get("pilot_visibility") == "CONTROLLED_PILOT_ONLY", "PILOT_VISIBILITY_INVALID")

if missing_count == 0 and required_fail_count == 0 and critical_issue_count == 0:
    require(summary.get("help_center_result") == "PASS", "HELP_CENTER_RESULT_SHOULD_BE_PASS")
else:
    require(summary.get("help_center_result") == "FAIL", "HELP_CENTER_RESULT_SHOULD_BE_FAIL")

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(external_policy.get("payment_provider") == "CLOSED", "PAYMENT_PROVIDER_NOT_CLOSED")
require(external_policy.get("real_export") == "CLOSED", "REAL_EXPORT_NOT_CLOSED")
require(external_policy.get("production_launch") == "CLOSED", "PRODUCTION_LAUNCH_NOT_CLOSED")

if errors:
    print("HELP_CENTER_CONTENT_STATUS=FAIL")
    print(f"HELP_CENTER_CONTENT_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"HELP_CENTER_CONTENT_FAIL={error}")
    sys.exit(1)

print("HELP_CENTER_CONTENT_STATUS=PASS")
print(f"HELP_CENTER_CONTENT_TENANT_ID={tenant.get('tenant_id')}")
print(f"HELP_CENTER_CONTENT_TOTAL_ARTICLE_COUNT={total_article_count}")
print(f"HELP_CENTER_CONTENT_READY_ARTICLE_COUNT={ready_count}")
print(f"HELP_CENTER_CONTENT_MISSING_ARTICLE_COUNT={missing_count}")
print(f"HELP_CENTER_CONTENT_REQUIRED_FAIL_COUNT={summary_required_fail_count}")
print(f"HELP_CENTER_CONTENT_CRITICAL_ISSUE_COUNT={critical_issue_count}")
print(f"HELP_CENTER_CONTENT_RESULT={summary.get('help_center_result')}")
print("HELP_CENTER_MODE=CONTROLLED_PILOT")
print("TRAINING_SET_STATUS=PASS")
print("SEARCHABLE_INDEX_STATUS=READY")
print("SUPPORT_ROUTE_STATUS=READY")
print("COMPLETION_CHECKLIST_STATUS=READY")
print("HELP_CENTER_CONTENT_EXTERNAL_POLICY=CLOSED")
PY_EOF
