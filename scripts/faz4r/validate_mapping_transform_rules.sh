#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-configs/faz4r/faz_4_16_2_4_mapping_transform_kurallari.v1.json}"
RULES_FILE="${RULES_FILE:-configs/faz4r/mapping_transform_rules.controlled_pilot.v1.json}"
INPUT_FILE="${INPUT_FILE:-}"

fail() {
  echo "MAPPING_TRANSFORM_ERROR=$1"
  exit 1
}

if [ -z "$INPUT_FILE" ]; then
  fail "INPUT_FILE_REQUIRED"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  fail "CONFIG_FILE_NOT_FOUND"
fi

if [ ! -f "$RULES_FILE" ]; then
  fail "RULES_FILE_NOT_FOUND"
fi

if [ ! -f "$INPUT_FILE" ]; then
  fail "INPUT_FILE_NOT_FOUND"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fail "PYTHON3_NOT_FOUND"
fi

python3 - "$CONFIG_FILE" "$RULES_FILE" "$INPUT_FILE" <<'PY_EOF'
import json
import sys
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from datetime import datetime
from pathlib import Path

config_path = Path(sys.argv[1])
rules_path = Path(sys.argv[2])
input_path = Path(sys.argv[3])

config = json.loads(config_path.read_text())
rules = json.loads(rules_path.read_text())
payload = json.loads(input_path.read_text())

errors = []

def require(condition, code):
    if not condition:
        errors.append(code)

def normalize_turkish_upper(value):
    value = str(value).strip()
    translation = str.maketrans({
        "ı": "I",
        "i": "I",
        "ğ": "G",
        "Ğ": "G",
        "ü": "U",
        "Ü": "U",
        "ş": "S",
        "Ş": "S",
        "ö": "O",
        "Ö": "O",
        "ç": "C",
        "Ç": "C"
    })
    return value.translate(translation).upper()

def parse_decimal(value):
    if isinstance(value, bool) or value is None:
        raise ValueError("not decimal")
    text = str(value).strip().replace(".", "").replace(",", ".") if isinstance(value, str) and "," in value else str(value).strip()
    number = Decimal(text)
    return str(number.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))

def normalize_date(value):
    text = str(value).strip()
    for fmt in ("%Y-%m-%d", "%d.%m.%Y", "%d/%m/%Y"):
        try:
            return datetime.strptime(text, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    raise ValueError("date format invalid")

def normalize_currency(value):
    text = normalize_turkish_upper(value)
    aliases = {
        "TL": "TRY",
        "TRY": "TRY",
        "TURK LIRASI": "TRY",
        "EUR": "EUR",
        "USD": "USD"
    }
    if text not in aliases:
        raise ValueError("currency invalid")
    return aliases[text]

def normalize_boolean(value):
    if isinstance(value, bool):
        return value
    text = normalize_turkish_upper(value)
    if text in {"EVET", "E", "YES", "TRUE", "1"}:
        return True
    if text in {"HAYIR", "H", "NO", "FALSE", "0"}:
        return False
    raise ValueError("boolean invalid")

def apply_transform(value, target, transforms, enum_maps):
    current = value

    for transform in transforms:
        if transform == "trim_string":
            current = str(current).strip()
        elif transform == "uppercase_code":
            current = normalize_turkish_upper(current)
        elif transform == "normalize_enum":
            key = normalize_turkish_upper(current)
            enum_map = enum_maps.get(target, {})
            if key not in enum_map:
                raise ValueError(f"enum invalid for {target}")
            current = enum_map[key]
        elif transform == "normalize_date":
            current = normalize_date(current)
        elif transform == "parse_decimal":
            current = parse_decimal(current)
        elif transform == "normalize_currency":
            current = normalize_currency(current)
        elif transform == "normalize_boolean":
            current = normalize_boolean(current)
        else:
            raise ValueError(f"unknown transform {transform}")

    return current

require(config.get("phase") == "FAZ_4_R", "CONFIG_PHASE_INVALID")
require(config.get("phase_no") == 201, "CONFIG_PHASE_NO_INVALID")
require(config.get("step") == "FAZ_4_16_2_4", "CONFIG_STEP_INVALID")
require(config.get("status_policy") == "COUNTER_BASED_FINAL_STATUS_ONLY", "STATUS_POLICY_INVALID")
require(config.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_MISSING")

policy = config.get("transform_policy", {})
supported_import_types = set(config.get("supported_import_types", []))
required_common_transforms = set(config.get("required_common_transforms", []))

require(rules.get("rule_set_status") == policy.get("mapping_rule_set_status_required"), "RULE_SET_STATUS_NOT_READY")
require(rules.get("transform_mode") == policy.get("transform_mode_required"), "RULE_SET_MODE_NOT_DRY_RUN")
require(rules.get("commit_allowed") is False, "RULE_SET_COMMIT_ALLOWED_TRUE")
require(required_common_transforms.issubset(set(rules.get("common_transforms", []))), "REQUIRED_COMMON_TRANSFORMS_MISSING")
require(rules.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "RULE_SET_CLOSED_POLICY_REFERENCE_MISSING")

request = payload.get("transform_request", {})
import_type = request.get("import_type")
rows = payload.get("rows", [])
expected_preview = payload.get("expected_preview", [])
external_policy = payload.get("external_policy", {})

require(request.get("transform_mode") == policy.get("transform_mode_required"), "TRANSFORM_MODE_NOT_DRY_RUN")
require(request.get("commit_requested") is False, "COMMIT_REQUESTED_NOT_ALLOWED")
require(import_type in supported_import_types, "IMPORT_TYPE_NOT_SUPPORTED")
require(import_type in rules.get("import_types", {}), "IMPORT_TYPE_RULES_MISSING")
require(isinstance(rows, list), "ROWS_NOT_LIST")
require(isinstance(expected_preview, list), "EXPECTED_PREVIEW_NOT_LIST")

transformed_rows = []

if import_type in rules.get("import_types", {}):
    rule = rules["import_types"][import_type]
    mappings = rule.get("field_mappings", [])
    enum_maps = rule.get("enum_maps", {})

    target_seen = set()
    source_fields = set()

    for mapping in mappings:
        source = mapping.get("source")
        target = mapping.get("target")
        transforms = mapping.get("transforms", [])

        require(source, "MAPPING_SOURCE_MISSING")
        require(target, "MAPPING_TARGET_MISSING")
        require(target not in target_seen, f"DUPLICATE_TARGET_FIELD:{target}")
        target_seen.add(target)
        source_fields.add(source)

        require(isinstance(transforms, list) and len(transforms) > 0, f"REQUIRED_TRANSFORM_MISSING:{target}")

    for idx, row in enumerate(rows, start=1):
        prefix = f"ROW_{idx}"
        require(isinstance(row, dict), f"{prefix}_NOT_OBJECT")
        if not isinstance(row, dict):
            continue

        unknown_fields = sorted(set(row.keys()) - source_fields)
        for unknown_field in unknown_fields:
            require(False, f"{prefix}_UNKNOWN_SOURCE_FIELD:{unknown_field}")

        transformed = {}
        for mapping in mappings:
            source = mapping.get("source")
            target = mapping.get("target")
            required = mapping.get("required") is True
            transforms = mapping.get("transforms", [])

            raw_value = row.get(source)

            if required:
                require(raw_value is not None and str(raw_value).strip() != "", f"{prefix}_REQUIRED_SOURCE_FIELD_MISSING:{source}")

            if raw_value is None or str(raw_value).strip() == "":
                continue

            try:
                transformed[target] = apply_transform(raw_value, target, transforms, enum_maps)
            except Exception:
                require(False, f"{prefix}_TRANSFORM_FAILED:{target}")

        transformed_rows.append(transformed)

require(external_policy.get("live_external_provider") == "CLOSED", "LIVE_EXTERNAL_PROVIDER_NOT_CLOSED")
require(external_policy.get("gib") == "CLOSED", "GIB_NOT_CLOSED")
require(external_policy.get("bank") == "CLOSED", "BANK_NOT_CLOSED")
require(external_policy.get("pos_provider") == "CLOSED", "POS_PROVIDER_NOT_CLOSED")
require(payload.get("closed_policy_reference") == "CLOSED_POLICY_GATE_REFERENCE_ONLY", "CLOSED_POLICY_REFERENCE_NOT_PRESENT")

if not errors:
    require(transformed_rows == expected_preview, "TRANSFORM_PREVIEW_MISMATCH")

if errors:
    print("MAPPING_TRANSFORM_STATUS=FAIL")
    print(f"MAPPING_TRANSFORM_ERROR_COUNT={len(errors)}")
    for error in errors:
        print(f"MAPPING_TRANSFORM_FAIL={error}")
    sys.exit(1)

print("MAPPING_TRANSFORM_STATUS=PASS")
print(f"MAPPING_TRANSFORM_IMPORT_TYPE={import_type}")
print(f"MAPPING_TRANSFORM_ROW_COUNT={len(transformed_rows)}")
print("MAPPING_TRANSFORM_MODE=DRY_RUN")
print("MAPPING_TRANSFORM_COMMIT_ALLOWED=false")
print("MAPPING_TRANSFORM_PREVIEW_STATUS=MATCHED")
print("MAPPING_TRANSFORM_EXTERNAL_POLICY=CLOSED")
PY_EOF
