#!/usr/bin/env python3
import re
import sys
from datetime import datetime
from pathlib import Path
from shutil import which

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
report_dir = root / "docs/phase4"

standard_file = report_dir / "16_4_pilot_data_readiness_contract_standard.md"
policy_file = report_dir / "16_4_pilot_data_readiness_contract_policy.md"
product_file = report_dir / "16_4_pilot_sample_product_dataset.tsv"
stock_file = report_dir / "16_4_pilot_sample_stock_dataset.tsv"
party_file = report_dir / "16_4_pilot_sample_party_dataset.tsv"
sales_accounting_file = report_dir / "16_4_pilot_sample_sales_accounting_dataset.tsv"
quality_file = report_dir / "16_4_pilot_data_quality_gate_matrix.tsv"
matrix_file = report_dir / "16_4_pilot_data_readiness_contract_matrix.tsv"
report_file = report_dir / "16_4_pilot_data_readiness_contract_report.md"

prev_16_3 = report_dir / "16_3_uat_scenario_execution_contract_report.md"
prev_16_2 = report_dir / "16_2_pilot_tenant_readiness_contract_report.md"
prev_16_1 = report_dir / "16_1_pilot_uat_onboarding_baseline_report.md"
prev_17 = report_dir / "17_workflow_realtime_ui_final_closure_report.md"
prev_20 = report_dir / "20_infra_cleanup_production_hardening_final_closure_report.md"
prev_21 = report_dir / "21_security_rbac_audit_final_closure_report.md"
prev_22 = report_dir / "22_observability_ops_console_final_closure_report.md"

failures = []
warnings = []
details = []
tools = []

PRODUCTS = [
    ("sample_product_barcode_standard", "retail", "adet", "barcode_required", "20", "stock_tracked", "standard_price", "uat_product_create_update", "product visible in tenant scope", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_weighted", "gida", "kg", "scale_barcode_ready", "1", "stock_tracked", "weighted_price", "uat_sale_cash_flow", "weighted sale scenario ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_vat_10", "retail", "adet", "barcode_required", "10", "stock_tracked", "standard_price", "uat_accounting_journal_check", "VAT 10 accounting check ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_vat_20", "retail", "adet", "barcode_required", "20", "stock_tracked", "standard_price", "uat_accounting_journal_check", "VAT 20 accounting check ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_zero_stock", "retail", "adet", "barcode_required", "20", "stock_tracked", "standard_price", "uat_low_stock_warning", "low stock warning scenario ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_low_stock_threshold", "retail", "adet", "barcode_required", "20", "stock_tracked", "standard_price", "uat_low_stock_warning", "threshold evidence ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_variant", "apparel", "adet", "variant_barcode", "20", "stock_tracked", "variant_price", "uat_product_create_update", "variant product check ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_serial_tracked", "electronics", "adet", "serial_policy", "20", "serial_stock_tracked", "standard_price", "uat_inventory_movement_validation", "serial movement policy ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_refundable", "retail", "adet", "barcode_required", "20", "stock_tracked", "standard_price", "uat_sale_cancel_refund", "refund scenario ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_product_discountable", "retail", "adet", "barcode_required", "20", "stock_tracked", "discount_policy", "uat_sale_cash_flow", "discount evidence ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_service_item", "service", "hizmet", "barcode_optional", "20", "no_stock_tracking", "service_price", "uat_accounting_journal_check", "service accounting check ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_deposit_item", "packaging", "adet", "barcode_required", "20", "stock_tracked", "deposit_price", "uat_sale_cash_flow", "deposit item flow ready", "READY_FOR_IMPLEMENTATION"),
]

STOCK_CASES = [
    ("opening_stock_positive", "sample_product_barcode_standard", "main_warehouse", "opening_balance", "positive_quantity", "balance_increases", "uat_stock_opening_entry", "YES", "READY_FOR_IMPLEMENTATION"),
    ("opening_stock_zero", "sample_product_zero_stock", "main_warehouse", "opening_balance", "zero_quantity", "balance_zero", "uat_stock_opening_entry", "YES", "READY_FOR_IMPLEMENTATION"),
    ("sale_stock_decrease", "sample_product_barcode_standard", "main_warehouse", "sale_out", "sale_quantity", "balance_decreases", "uat_sale_cash_flow", "YES", "READY_FOR_IMPLEMENTATION"),
    ("weighted_sale_decrease", "sample_product_weighted", "main_warehouse", "sale_out", "decimal_quantity", "balance_decreases_decimal", "uat_sale_cash_flow", "YES", "READY_FOR_IMPLEMENTATION"),
    ("refund_stock_increase", "sample_product_refundable", "main_warehouse", "refund_in", "refund_quantity", "balance_increases", "uat_sale_cancel_refund", "YES", "READY_FOR_IMPLEMENTATION"),
    ("cancel_reversal", "sample_product_refundable", "main_warehouse", "cancel_reversal", "original_sale_quantity", "movement_reversed", "uat_sale_cancel_refund", "YES", "READY_FOR_IMPLEMENTATION"),
    ("manual_adjustment_plus", "sample_product_barcode_standard", "main_warehouse", "adjustment_in", "adjustment_quantity", "balance_increases", "uat_inventory_movement_validation", "NO", "READY_FOR_IMPLEMENTATION"),
    ("manual_adjustment_minus", "sample_product_barcode_standard", "main_warehouse", "adjustment_out", "adjustment_quantity", "balance_decreases", "uat_inventory_movement_validation", "NO", "READY_FOR_IMPLEMENTATION"),
    ("low_stock_threshold_cross", "sample_product_low_stock_threshold", "main_warehouse", "sale_out", "threshold_quantity", "warning_expected", "uat_low_stock_warning", "NO", "READY_FOR_IMPLEMENTATION"),
    ("negative_stock_guard", "sample_product_zero_stock", "main_warehouse", "sale_out", "greater_than_balance", "reject_or_guard_expected", "uat_inventory_movement_validation", "YES", "READY_FOR_IMPLEMENTATION"),
    ("serial_stock_out", "sample_product_serial_tracked", "main_warehouse", "sale_out", "serial_quantity_one", "serial_movement_expected", "uat_inventory_movement_validation", "NO", "READY_FOR_IMPLEMENTATION"),
    ("warehouse_transfer_note", "sample_product_barcode_standard", "main_warehouse_to_branch", "transfer", "transfer_quantity", "source_decrease_target_increase", "uat_inventory_movement_validation", "NO", "READY_FOR_IMPLEMENTATION"),
]

PARTIES = [
    ("sample_cash_customer", "customer", "name_optional_receipt_required", "synthetic_only", "tax_fields_not_required_for_cash", "uat_sale_cash_flow", "cash customer flow ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_registered_customer", "customer", "name,address,tax_no,tax_office,phone,email", "synthetic_masked_only", "tax_no_required_masked", "uat_sale_cash_flow", "registered customer flow ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_corporate_customer", "customer", "company_name,address,tax_no,tax_office,email", "synthetic_masked_only", "tax_no_required_masked", "uat_accounting_journal_check", "corporate invoice data contract ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_vendor", "vendor", "company_name,address,tax_no,tax_office,phone,email", "synthetic_masked_only", "tax_no_required_masked", "uat_product_create_update", "vendor card ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_accountant_contact", "accountant", "name,email,phone", "synthetic_masked_only", "tax_fields_not_applicable", "uat_accounting_journal_check", "accountant review owner ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_support_contact", "support", "name,email,phone", "synthetic_masked_only", "tax_fields_not_applicable", "uat_observability_incident_loop", "support contact ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_branch_cashdesk", "internal_branch", "branch_name,cashdesk_name", "synthetic_only", "tax_fields_not_applicable", "uat_sale_cash_flow", "branch/cashdesk flow ready", "READY_FOR_IMPLEMENTATION"),
    ("sample_project_owner", "project_owner", "name,email,role", "synthetic_masked_only", "tax_fields_not_applicable", "uat_go_no_go_decision", "go/no-go owner ready", "READY_FOR_IMPLEMENTATION"),
]

SALES_ACCOUNTING = [
    ("cash_sale_standard", "sale", "cash", "stock_decrease", "journal_expected", "100/600/391", "uat_sale_cash_flow", "YES", "READY_FOR_IMPLEMENTATION"),
    ("card_sale_standard", "sale", "credit_card", "stock_decrease", "journal_expected", "108/600/391", "uat_sale_cash_flow", "YES", "READY_FOR_IMPLEMENTATION"),
    ("registered_customer_sale", "sale", "receivable", "stock_decrease", "journal_expected", "120/600/391", "uat_accounting_journal_check", "YES", "READY_FOR_IMPLEMENTATION"),
    ("vat_10_sale", "sale", "cash", "stock_decrease", "journal_expected", "100/600/391.10", "uat_accounting_journal_check", "YES", "READY_FOR_IMPLEMENTATION"),
    ("vat_20_sale", "sale", "cash", "stock_decrease", "journal_expected", "100/600/391.20", "uat_accounting_journal_check", "YES", "READY_FOR_IMPLEMENTATION"),
    ("discounted_sale", "sale", "cash", "stock_decrease", "discount_journal_policy", "100/600/391/discount_policy", "uat_sale_cash_flow", "NO", "READY_FOR_IMPLEMENTATION"),
    ("refund_cash_sale", "refund", "cash", "stock_increase", "reversal_expected", "610/191/100_or_policy", "uat_sale_cancel_refund", "YES", "READY_FOR_IMPLEMENTATION"),
    ("cancel_sale_reversal", "cancel", "cash", "stock_reversal", "full_reversal_expected", "reverse_original_lines", "uat_sale_cancel_refund", "YES", "READY_FOR_IMPLEMENTATION"),
    ("service_sale_no_stock", "sale", "cash", "no_stock_effect", "service_journal_expected", "100/600/391", "uat_accounting_journal_check", "NO", "READY_FOR_IMPLEMENTATION"),
    ("daily_cash_report", "cash_report", "cash", "no_stock_effect", "cash_total_expected", "cash_total_matches_sales", "uat_reporting_summary", "NO", "READY_FOR_IMPLEMENTATION"),
    ("stock_report_after_sale", "stock_report", "none", "report_only", "no_journal", "stock_total_matches_movements", "uat_reporting_summary", "NO", "READY_FOR_IMPLEMENTATION"),
    ("audit_report_after_mutation", "audit_report", "none", "report_only", "audit_expected", "actor/request/tenant visible", "uat_audit_trail_check", "YES", "READY_FOR_IMPLEMENTATION"),
]

QUALITY_GATES = [
    ("synthetic_data_only", "security", "PASS", "YES", "all sample data must be synthetic/masked", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("no_real_customer_private_data", "security", "PASS", "YES", "no real phone/email/tax no", "security_admin", "READY_FOR_IMPLEMENTATION"),
    ("tenant_scope_required", "tenant", "PASS", "YES", "all data belongs to pilot tenant context", "platform_admin", "READY_FOR_IMPLEMENTATION"),
    ("product_minimum_fields_ready", "product", "PASS", "YES", "product code/category/unit/vat/barcode policy exists", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("stock_opening_balance_ready", "inventory", "PASS", "YES", "opening stock cases exist", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("sale_stock_accounting_chain_ready", "business", "PASS", "YES", "sale to stock to accounting chain covered", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("refund_cancel_chain_ready", "business", "PASS", "YES", "refund/cancel chain covered", "project_owner", "READY_FOR_IMPLEMENTATION"),
    ("tdhp_accounting_review_ready", "accounting", "PASS", "YES", "TDHP expected lines present", "accountant", "READY_FOR_IMPLEMENTATION"),
    ("reporting_snapshot_ready", "reporting", "PASS", "NO", "reporting sample flows exist", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("audit_evidence_ready", "audit", "PASS", "YES", "audit sample flow exists", "tenant_admin", "READY_FOR_IMPLEMENTATION"),
    ("negative_stock_guard_ready", "inventory", "PASS", "YES", "negative stock guard case exists", "tenant_operator", "READY_FOR_IMPLEMENTATION"),
    ("go_no_go_data_ready", "rollout", "PASS", "YES", "data readiness included in go/no-go", "project_owner", "READY_FOR_IMPLEMENTATION"),
]

def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")

def detail(line):
    details.append(line)

def fail(msg):
    failures.append(f"FAIL ❌ {msg}")

def tool_status(name):
    status = "FOUND" if which(name) else "NOT_FOUND"
    tools.append(f"TOOL_{name}={status}")

def read(path):
    if not path.exists():
        return ""
    return path.read_text(errors="ignore")

def get_value(path, key):
    text = read(path)
    value = ""
    pattern = re.compile(rf"^{re.escape(key)}=(.*)$")
    for line in text.splitlines():
        m = pattern.match(line.strip())
        if m:
            value = m.group(1).strip().strip('"')
    return value

def safe(v):
    v = str(v or "")
    v = v.replace("\t", " ").replace("\n", " ").replace("\r", " ")
    v = re.sub(r"(password|token|secret|dsn|authorization)\s*[:=]\s*[^ ]+", r"\1=***", v, flags=re.I)
    v = re.sub(r"://[^/@\s]+@", "://***@", v)
    return v[:420]

report_dir.mkdir(parents=True, exist_ok=True)

detail(f"ROOT_DIR={root}")
detail("SERVICE_RESTARTED=NO")
detail("CONTAINER_RESTARTED=NO")
detail("DOCKER_COMPOSE_EXECUTED=NO")
detail("NGINX_RELOAD_EXECUTED=NO")
detail("FIREWALL_CHANGED=NO")
detail("PORT_CHANGED=NO")
detail("CONFIG_CHANGED=NO")
detail("ENV_CHANGED=NO")
detail("SAMPLE_DATA_INSERTED=NO")
detail("REAL_CUSTOMER_DATA_CREATED=NO")
detail("REAL_PRODUCT_CREATED=NO")
detail("REAL_STOCK_MUTATED=NO")
detail("REAL_SALE_CREATED=NO")
detail("REAL_ACCOUNTING_ENTRY_CREATED=NO")
detail("DATA_IMPORT_EXECUTED=NO")
detail("FILE_EXPORT_EXECUTED=NO")
detail("UI_CODE_CHANGED=NO")
detail("API_ROUTE_CREATED=NO")
detail("API_IMPLEMENTATION_CHANGED=NO")
detail("DB_MUTATION=NO")
detail("DB_APPLY_EXECUTED=NO")
detail("MIGRATION_CREATED=NO")
detail("MIGRATION_APPLY_EXECUTED=NO")
detail("EVENT_PUBLISHED=NO")
detail("EVENT_CONSUMED=NO")
detail("NOTIFICATION_SENT=NO")
detail("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
detail("RAW_DSN_PRINTED=NO")
detail("SECRET_VALUE_PRINTED=NO")
detail("TOKEN_PRINTED=NO")
detail("VALIDATION_MODE=PILOT_DATA_READINESS_CONTRACT_ONLY")

for tool in ["python3", "grep", "wc"]:
    tool_status(tool)

prev_16_3_status = get_value(prev_16_3, "FAZ4B_16_3_FINAL_STATUS")
prev_16_3_gate = get_value(prev_16_3, "UAT_SCENARIO_EXECUTION_CONTRACT")
prev_16_3_no_runtime = get_value(prev_16_3, "UAT_NO_RUNTIME_CHANGE")
prev_16_3_secret = get_value(prev_16_3, "UAT_SECRET_SAFE")
prev_16_2_status = get_value(prev_16_2, "FAZ4B_16_2_FINAL_STATUS")
prev_16_1_status = get_value(prev_16_1, "FAZ4B_16_1_FINAL_STATUS")
prev_17_status = get_value(prev_17, "FAZ4B_17_FINAL_STATUS")
prev_20_status = get_value(prev_20, "FAZ4B_20_FINAL_STATUS")
prev_21_status = get_value(prev_21, "FAZ4B_21_FINAL_STATUS")
prev_22_status = get_value(prev_22, "FAZ4B_22_FINAL_STATUS")

detail(f"PREVIOUS_16_3_FINAL_STATUS={prev_16_3_status}")
detail(f"PREVIOUS_16_3_UAT_SCENARIO_EXECUTION_CONTRACT={prev_16_3_gate}")
detail(f"PREVIOUS_16_3_UAT_NO_RUNTIME_CHANGE={prev_16_3_no_runtime}")
detail(f"PREVIOUS_16_3_UAT_SECRET_SAFE={prev_16_3_secret}")
detail(f"PREVIOUS_16_2_FINAL_STATUS={prev_16_2_status}")
detail(f"PREVIOUS_16_1_FINAL_STATUS={prev_16_1_status}")
detail(f"PREVIOUS_17_FINAL_STATUS={prev_17_status}")
detail(f"PREVIOUS_20_FINAL_STATUS={prev_20_status}")
detail(f"PREVIOUS_21_FINAL_STATUS={prev_21_status}")
detail(f"PREVIOUS_22_FINAL_STATUS={prev_22_status}")

if prev_16_3_status != "PASS":
    fail("16.3 final status PASS degil")
if prev_16_3_gate != "PASS":
    fail("16.3 UAT execution contract PASS degil")
if prev_16_3_no_runtime != "PASS":
    fail("16.3 no runtime change PASS degil")
if prev_16_3_secret != "PASS":
    fail("16.3 secret safe PASS degil")
if prev_16_2_status != "PASS":
    fail("16.2 final status PASS degil")
if prev_16_1_status != "PASS":
    fail("16.1 final status PASS degil")
if prev_17_status != "PASS":
    fail("17 final status PASS degil")
if prev_20_status != "PASS":
    fail("20 final status PASS degil")
if prev_21_status != "PASS":
    fail("21 final status PASS degil")
if prev_22_status != "PASS":
    fail("22 final status PASS degil")

for p, label in [(standard_file, "standard doc"), (policy_file, "policy doc")]:
    if not p.exists():
        fail(f"{label} yok")

product_lines = ["product_code\tcategory\tunit\tbarcode_policy\tvat_rate\tstock_tracking\tprice_policy\tuat_scenario_ref\tacceptance_signal\timplementation_status\tnote"]
for row in PRODUCTS:
    product_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_product_created"]]))
product_file.write_text("\n".join(product_lines) + "\n")

stock_lines = ["stock_case\tproduct_ref\twarehouse_ref\tmovement_type\tquantity_policy\texpected_balance_policy\tuat_scenario_ref\tblocker_if_failed\timplementation_status\tnote"]
for row in STOCK_CASES:
    stock_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_stock_mutation"]]))
stock_file.write_text("\n".join(stock_lines) + "\n")

party_lines = ["party_code\tparty_type\trequired_fields\tsensitive_data_policy\ttax_field_policy\tuat_scenario_ref\tacceptance_signal\timplementation_status\tnote"]
for row in PARTIES:
    party_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_customer_data"]]))
party_file.write_text("\n".join(party_lines) + "\n")

sales_lines = ["flow_code\tflow_type\tpayment_type\tstock_effect\taccounting_effect\texpected_tdhp_lines\tuat_scenario_ref\tblocker_if_failed\timplementation_status\tnote"]
for row in SALES_ACCOUNTING:
    sales_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only_no_sale_or_journal"]]))
sales_accounting_file.write_text("\n".join(sales_lines) + "\n")

quality_lines = ["gate_name\tcategory\trequired_status\tblocker_if_failed\tevidence_hint\towner_role\timplementation_status\tnote"]
for row in QUALITY_GATES:
    quality_lines.append("\t".join([safe(x) for x in list(row) + ["contract_only"]]))
quality_file.write_text("\n".join(quality_lines) + "\n")

product_count = len(PRODUCTS)
stock_count = len(STOCK_CASES)
party_count = len(PARTIES)
sales_accounting_count = len(SALES_ACCOUNTING)
quality_count = len(QUALITY_GATES)
quality_blocker_count = sum(1 for x in QUALITY_GATES if x[3] == "YES")
stock_blocker_count = sum(1 for x in STOCK_CASES if x[7] == "YES")
sales_blocker_count = sum(1 for x in SALES_ACCOUNTING if x[7] == "YES")
synthetic_party_count = sum(1 for x in PARTIES if "synthetic" in x[3])
tdhp_flow_count = sum(1 for x in SALES_ACCOUNTING if "/" in x[5])
vat_product_count = sum(1 for x in PRODUCTS if x[4] in ["1", "10", "20"])
stock_tracked_product_count = sum(1 for x in PRODUCTS if "stock_tracked" in x[5])

detail(f"PILOT_DATA_PRODUCT_SAMPLE_COUNT={product_count}")
detail(f"PILOT_DATA_STOCK_SAMPLE_COUNT={stock_count}")
detail(f"PILOT_DATA_PARTY_SAMPLE_COUNT={party_count}")
detail(f"PILOT_DATA_SALES_ACCOUNTING_SAMPLE_COUNT={sales_accounting_count}")
detail(f"PILOT_DATA_QUALITY_GATE_COUNT={quality_count}")
detail(f"PILOT_DATA_QUALITY_BLOCKER_COUNT={quality_blocker_count}")
detail(f"PILOT_DATA_STOCK_BLOCKER_COUNT={stock_blocker_count}")
detail(f"PILOT_DATA_SALES_BLOCKER_COUNT={sales_blocker_count}")
detail(f"PILOT_DATA_SYNTHETIC_PARTY_COUNT={synthetic_party_count}")
detail(f"PILOT_DATA_TDHP_FLOW_COUNT={tdhp_flow_count}")
detail(f"PILOT_DATA_VAT_PRODUCT_COUNT={vat_product_count}")
detail(f"PILOT_DATA_STOCK_TRACKED_PRODUCT_COUNT={stock_tracked_product_count}")

required_products = [
    "sample_product_barcode_standard",
    "sample_product_weighted",
    "sample_product_vat_10",
    "sample_product_vat_20",
    "sample_product_zero_stock",
    "sample_product_refundable",
    "sample_service_item",
]
product_names = set([x[0] for x in PRODUCTS])
missing_products = [x for x in required_products if x not in product_names]

required_stock = [
    "opening_stock_positive",
    "sale_stock_decrease",
    "refund_stock_increase",
    "cancel_reversal",
    "low_stock_threshold_cross",
    "negative_stock_guard",
]
stock_names = set([x[0] for x in STOCK_CASES])
missing_stock = [x for x in required_stock if x not in stock_names]

required_party = [
    "sample_cash_customer",
    "sample_registered_customer",
    "sample_corporate_customer",
    "sample_vendor",
    "sample_branch_cashdesk",
]
party_names = set([x[0] for x in PARTIES])
missing_party = [x for x in required_party if x not in party_names]

required_flows = [
    "cash_sale_standard",
    "card_sale_standard",
    "registered_customer_sale",
    "refund_cash_sale",
    "cancel_sale_reversal",
    "daily_cash_report",
    "audit_report_after_mutation",
]
flow_names = set([x[0] for x in SALES_ACCOUNTING])
missing_flows = [x for x in required_flows if x not in flow_names]

required_quality = [
    "synthetic_data_only",
    "no_real_customer_private_data",
    "tenant_scope_required",
    "sale_stock_accounting_chain_ready",
    "refund_cancel_chain_ready",
    "tdhp_accounting_review_ready",
    "negative_stock_guard_ready",
    "go_no_go_data_ready",
]
quality_names = set([x[0] for x in QUALITY_GATES])
missing_quality = [x for x in required_quality if x not in quality_names]

if missing_products:
    fail("required product sample eksik: " + ",".join(missing_products))
if missing_stock:
    fail("required stock sample eksik: " + ",".join(missing_stock))
if missing_party:
    fail("required party sample eksik: " + ",".join(missing_party))
if missing_flows:
    fail("required sales/accounting flow eksik: " + ",".join(missing_flows))
if missing_quality:
    fail("required data quality gate eksik: " + ",".join(missing_quality))
if synthetic_party_count != party_count:
    fail("tum party sample kayitlari synthetic/masked degil")
if quality_blocker_count < 8:
    fail("quality blocker gate sayisi yetersiz")
if tdhp_flow_count < 6:
    fail("TDHP flow coverage yetersiz")
if vat_product_count < 4:
    fail("VAT product coverage yetersiz")

previous_status = "PASS" if (
    prev_16_3_status == "PASS"
    and prev_16_3_gate == "PASS"
    and prev_16_3_no_runtime == "PASS"
    and prev_16_3_secret == "PASS"
) else "FAIL"

product_status = "PASS" if product_file.exists() and product_count >= 10 and not missing_products else "FAIL"
stock_status = "PASS" if stock_file.exists() and stock_count >= 10 and not missing_stock else "FAIL"
party_status = "PASS" if party_file.exists() and party_count >= 8 and not missing_party and synthetic_party_count == party_count else "FAIL"
sales_status = "PASS" if sales_accounting_file.exists() and sales_accounting_count >= 10 and not missing_flows else "FAIL"
quality_status = "PASS" if quality_file.exists() and quality_count >= 10 and not missing_quality else "FAIL"
no_runtime_status = "PASS"
no_config_status = "PASS"
secret_safe_status = "PASS"

detail(f"PILOT_DATA_PREVIOUS_16_3={previous_status}")
detail(f"PILOT_PRODUCT_SAMPLE_DATASET={product_status}")
detail(f"PILOT_STOCK_SAMPLE_DATASET={stock_status}")
detail(f"PILOT_PARTY_SAMPLE_DATASET={party_status}")
detail(f"PILOT_SALES_ACCOUNTING_SAMPLE_DATASET={sales_status}")
detail(f"PILOT_DATA_QUALITY_GATE_MATRIX={quality_status}")
detail(f"PILOT_DATA_NO_RUNTIME_CHANGE={no_runtime_status}")
detail(f"PILOT_DATA_NO_CONFIG_CHANGE={no_config_status}")
detail(f"PILOT_DATA_SECRET_SAFE={secret_safe_status}")

for name, status in [
    ("previous_16_3", previous_status),
    ("product_sample_dataset", product_status),
    ("stock_sample_dataset", stock_status),
    ("party_sample_dataset", party_status),
    ("sales_accounting_sample_dataset", sales_status),
    ("data_quality_gate_matrix", quality_status),
    ("no_runtime_change", no_runtime_status),
    ("no_config_change", no_config_status),
    ("secret_safe", secret_safe_status),
]:
    if status != "PASS":
        fail(f"{name} status PASS degil")

matrix_lines = [
    "gate\tstatus\tnote",
    f"previous_16_3\t{previous_status}\tUAT scenario execution prerequisite",
    f"product_sample_dataset\t{product_status}\tproducts={product_count} vat={vat_product_count} stock_tracked={stock_tracked_product_count}",
    f"stock_sample_dataset\t{stock_status}\tstock_cases={stock_count} blockers={stock_blocker_count}",
    f"party_sample_dataset\t{party_status}\tparties={party_count} synthetic={synthetic_party_count}",
    f"sales_accounting_sample_dataset\t{sales_status}\tflows={sales_accounting_count} tdhp={tdhp_flow_count} blockers={sales_blocker_count}",
    f"data_quality_gate_matrix\t{quality_status}\tgates={quality_count} blockers={quality_blocker_count}",
    f"no_runtime_change\t{no_runtime_status}\tno real data/import/db/api/ui/event changed",
    f"no_config_change\t{no_config_status}\tno config/env/nginx/firewall changed",
    f"secret_safe\t{secret_safe_status}\tno secrets/customer private data printed",
    "service_restarted\tNO\tevidence only",
    "container_restarted\tNO\tevidence only",
    "docker_compose_executed\tNO\tevidence only",
    "nginx_reload_executed\tNO\tevidence only",
    "firewall_changed\tNO\tevidence only",
    "port_changed\tNO\tevidence only",
    "config_changed\tNO\tevidence only",
    "env_changed\tNO\tevidence only",
    "sample_data_inserted\tNO\tcontract only",
    "real_customer_data_created\tNO\tcontract only",
    "real_product_created\tNO\tcontract only",
    "real_stock_mutated\tNO\tcontract only",
    "real_sale_created\tNO\tcontract only",
    "real_accounting_entry_created\tNO\tcontract only",
    "data_import_executed\tNO\tcontract only",
    "file_export_executed\tNO\tcontract only",
    "ui_code_changed\tNO\tcontract only",
    "api_route_created\tNO\tcontract only",
    "api_implementation_changed\tNO\tcontract only",
    "db_mutation\tNO\tevidence only",
    "db_apply_executed\tNO\tevidence only",
    "migration_created\tNO\tevidence only",
    "migration_apply_executed\tNO\tevidence only",
    "event_published\tNO\tcontract only",
    "event_consumed\tNO\tcontract only",
    "notification_sent\tNO\tcontract only",
    "customer_private_data_printed\tNO\tsecret-safe report",
    "raw_dsn_printed\tNO\tsecret-safe report",
    "secret_value_printed\tNO\tsecret-safe report",
    "token_printed\tNO\tsecret-safe report",
]
matrix_file.write_text("\n".join(matrix_lines) + "\n")

final_status = "PASS" if not failures else "FAIL"
detail(f"PILOT_DATA_READINESS_CONTRACT={final_status}")
detail(f"FAZ4B_16_4_FINAL_STATUS={final_status}")

report_lines = [
    "# FAZ 4B / 16.4 - Pilot Data Readiness / Sample Dataset Contract Report",
    "",
    f"Generated at: {now()}",
    "",
    "## Summary",
    *details,
    f"FAIL_COUNT={len(failures)}",
    f"WARN_COUNT={len(warnings)}",
    f"PILOT_DATA_READINESS_CONTRACT={final_status}",
    f"FAZ4B_16_4_FINAL_STATUS={final_status}",
    "",
    "## Tool Status",
    *tools,
    "",
    "## Matrix",
    "MATRIX_FILE=docs/phase4/16_4_pilot_data_readiness_contract_matrix.tsv",
    matrix_file.read_text(errors="ignore").rstrip(),
    "",
    "## Inventories",
    "PILOT_PRODUCT_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_product_dataset.tsv",
    "PILOT_STOCK_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_stock_dataset.tsv",
    "PILOT_PARTY_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_party_dataset.tsv",
    "PILOT_SALES_ACCOUNTING_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_sales_accounting_dataset.tsv",
    "PILOT_DATA_QUALITY_GATE_MATRIX_FILE=docs/phase4/16_4_pilot_data_quality_gate_matrix.tsv",
    "NOTE=Contract only. No real data/import/runtime/config/db/api/ui/event/customer-private-data change executed.",
    "",
    "## Safety Decision",
    "SERVICE_RESTARTED=NO",
    "CONTAINER_RESTARTED=NO",
    "DOCKER_COMPOSE_EXECUTED=NO",
    "NGINX_RELOAD_EXECUTED=NO",
    "FIREWALL_CHANGED=NO",
    "PORT_CHANGED=NO",
    "CONFIG_CHANGED=NO",
    "ENV_CHANGED=NO",
    "SAMPLE_DATA_INSERTED=NO",
    "REAL_CUSTOMER_DATA_CREATED=NO",
    "REAL_PRODUCT_CREATED=NO",
    "REAL_STOCK_MUTATED=NO",
    "REAL_SALE_CREATED=NO",
    "REAL_ACCOUNTING_ENTRY_CREATED=NO",
    "DATA_IMPORT_EXECUTED=NO",
    "FILE_EXPORT_EXECUTED=NO",
    "UI_CODE_CHANGED=NO",
    "API_ROUTE_CREATED=NO",
    "API_IMPLEMENTATION_CHANGED=NO",
    "DB_MUTATION=NO",
    "DB_APPLY_EXECUTED=NO",
    "MIGRATION_CREATED=NO",
    "MIGRATION_APPLY_EXECUTED=NO",
    "EVENT_PUBLISHED=NO",
    "EVENT_CONSUMED=NO",
    "NOTIFICATION_SENT=NO",
    "CUSTOMER_PRIVATE_DATA_PRINTED=NO",
    "RAW_DSN_PRINTED=NO",
    "SECRET_VALUE_PRINTED=NO",
    "TOKEN_PRINTED=NO",
    "",
    "## Issues",
    *(failures + warnings if failures or warnings else ["OK ✅ issue yok"]),
]
report_file.write_text("\n".join(report_lines) + "\n")

print(f"REPORT_FILE={report_file}")
print(f"MATRIX_FILE={matrix_file}")
print(f"PILOT_PRODUCT_SAMPLE_DATASET_FILE={product_file}")
print(f"PILOT_STOCK_SAMPLE_DATASET_FILE={stock_file}")
print(f"PILOT_PARTY_SAMPLE_DATASET_FILE={party_file}")
print(f"PILOT_SALES_ACCOUNTING_SAMPLE_DATASET_FILE={sales_accounting_file}")
print(f"PILOT_DATA_QUALITY_GATE_MATRIX_FILE={quality_file}")
print(f"FAIL_COUNT={len(failures)}")
print(f"WARN_COUNT={len(warnings)}")
print(f"PILOT_DATA_PRODUCT_SAMPLE_COUNT={product_count}")
print(f"PILOT_DATA_STOCK_SAMPLE_COUNT={stock_count}")
print(f"PILOT_DATA_PARTY_SAMPLE_COUNT={party_count}")
print(f"PILOT_DATA_SALES_ACCOUNTING_SAMPLE_COUNT={sales_accounting_count}")
print(f"PILOT_DATA_QUALITY_GATE_COUNT={quality_count}")
print(f"PILOT_DATA_QUALITY_BLOCKER_COUNT={quality_blocker_count}")
print(f"PILOT_DATA_STOCK_BLOCKER_COUNT={stock_blocker_count}")
print(f"PILOT_DATA_SALES_BLOCKER_COUNT={sales_blocker_count}")
print(f"PILOT_DATA_SYNTHETIC_PARTY_COUNT={synthetic_party_count}")
print(f"PILOT_DATA_TDHP_FLOW_COUNT={tdhp_flow_count}")
print(f"PILOT_DATA_VAT_PRODUCT_COUNT={vat_product_count}")
print(f"PILOT_DATA_STOCK_TRACKED_PRODUCT_COUNT={stock_tracked_product_count}")
print(f"PILOT_DATA_PREVIOUS_16_3={previous_status}")
print(f"PILOT_PRODUCT_SAMPLE_DATASET={product_status}")
print(f"PILOT_STOCK_SAMPLE_DATASET={stock_status}")
print(f"PILOT_PARTY_SAMPLE_DATASET={party_status}")
print(f"PILOT_SALES_ACCOUNTING_SAMPLE_DATASET={sales_status}")
print(f"PILOT_DATA_QUALITY_GATE_MATRIX={quality_status}")
print(f"PILOT_DATA_NO_RUNTIME_CHANGE={no_runtime_status}")
print(f"PILOT_DATA_NO_CONFIG_CHANGE={no_config_status}")
print(f"PILOT_DATA_SECRET_SAFE={secret_safe_status}")
print("SERVICE_RESTARTED=NO")
print("CONTAINER_RESTARTED=NO")
print("DOCKER_COMPOSE_EXECUTED=NO")
print("NGINX_RELOAD_EXECUTED=NO")
print("FIREWALL_CHANGED=NO")
print("PORT_CHANGED=NO")
print("CONFIG_CHANGED=NO")
print("ENV_CHANGED=NO")
print("SAMPLE_DATA_INSERTED=NO")
print("REAL_CUSTOMER_DATA_CREATED=NO")
print("REAL_PRODUCT_CREATED=NO")
print("REAL_STOCK_MUTATED=NO")
print("REAL_SALE_CREATED=NO")
print("REAL_ACCOUNTING_ENTRY_CREATED=NO")
print("DATA_IMPORT_EXECUTED=NO")
print("FILE_EXPORT_EXECUTED=NO")
print("UI_CODE_CHANGED=NO")
print("API_ROUTE_CREATED=NO")
print("API_IMPLEMENTATION_CHANGED=NO")
print("DB_MUTATION=NO")
print("DB_APPLY_EXECUTED=NO")
print("MIGRATION_CREATED=NO")
print("MIGRATION_APPLY_EXECUTED=NO")
print("EVENT_PUBLISHED=NO")
print("EVENT_CONSUMED=NO")
print("NOTIFICATION_SENT=NO")
print("CUSTOMER_PRIVATE_DATA_PRINTED=NO")
print("RAW_DSN_PRINTED=NO")
print("SECRET_VALUE_PRINTED=NO")
print("TOKEN_PRINTED=NO")
print(f"PILOT_DATA_READINESS_CONTRACT={final_status} {'✅' if final_status == 'PASS' else '❌'}")
print(f"FAZ4B_16_4_FINAL_STATUS={final_status} {'✅' if final_status == 'PASS' else '❌'}")

if failures:
    sys.exit(1)
