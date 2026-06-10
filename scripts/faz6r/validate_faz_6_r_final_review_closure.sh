#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_r_final_review_closure.v1.json}"
MANIFEST_FILE="${2:-configs/faz6r/faz_6_r_final_review_closure_manifest.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_r_final_review_closure_test.json}"
RUNTIME_FILE="${4:-scripts/faz6r/run_faz_6_r_final_review_closure_dry_run.sh}"

python3 - "$CONFIG_FILE" "$MANIFEST_FILE" "$FIXTURE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
fixture_path = Path(sys.argv[3])
runtime_path = Path(sys.argv[4])
errors = []

def require(ok, msg):
    if not ok:
        errors.append(msg)

require(config_path.exists(), f"config missing: {config_path}")
require(manifest_path.exists(), f"manifest missing: {manifest_path}")
require(fixture_path.exists(), f"fixture missing: {fixture_path}")
require(runtime_path.exists(), f"runtime missing: {runtime_path}")

if not errors:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    fixture = json.loads(fixture_path.read_text(encoding="utf-8"))

    require(config.get("phase") == fixture.get("expected_phase"), "phase mismatch")
    require(config.get("code") == fixture.get("expected_code"), "code mismatch")
    require(manifest.get("phase") == fixture.get("expected_phase"), "manifest phase mismatch")
    require(manifest.get("code") == fixture.get("expected_code"), "manifest code mismatch")

    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "production_release_execute_allowed",
        "deploy_execute_allowed",
        "dns_mutation_allowed",
        "cdn_invalidation_allowed",
        "db_mutation_allowed",
        "build_publish_allowed",
        "failover_execute_allowed",
        "remediation_execute_allowed"
    ]:
        require(config.get(field) is False, f"{field} must be false")

    required_evidence = config.get("required_evidence_files", [])
    require(len(required_evidence) >= fixture.get("expected_required_evidence_count"), "required evidence count mismatch")

    for f in required_evidence:
        p = Path(f)
        require(p.exists(), f"required evidence missing: {f}")
        if p.exists():
            text = p.read_text(encoding="utf-8")
            require("FINAL_STATUS=PASS" in text, f"required evidence not final PASS: {f}")

    priorities = manifest.get("priority_closure", [])
    require(len(priorities) == fixture.get("expected_priority_count"), "priority count mismatch")
    for p in priorities:
        require(p.get("status") == fixture.get("expected_priority_status"), f"priority not PASS: {p.get('priority')}")
        require(p.get("ready") is True, f"priority not ready: {p.get('priority')}")

    release = manifest.get("release_readiness", {})
    require(release.get("sre_edge_release_status") == "PASS", "SRE edge release status must be PASS")
    require(release.get("all_priority_blocks_status") == "PASS", "all priority blocks must be PASS")
    require(release.get("all_required_evidence_status") == "READY", "all evidence must be READY")
    require(release.get("blocker_remaining") is False, "blocker remaining must be false")
    require(release.get("partial_remaining") is False, "partial remaining must be false")
    require(release.get("pending_remaining") is False, "pending remaining must be false")
    require(release.get("fail_remaining") is False, "fail remaining must be false")
    require(release.get("ready_for_next_phase") is True, "ready for next phase must be true")

    mutation = manifest.get("mutation_policy", {})
    for field in [
        "runtime_mutation_allowed",
        "provider_mutation_allowed",
        "production_release_execute_allowed",
        "deploy_execute_allowed",
        "dns_mutation_allowed",
        "cdn_invalidation_allowed",
        "db_mutation_allowed",
        "build_publish_allowed",
        "failover_execute_allowed",
        "remediation_execute_allowed"
    ]:
        require(mutation.get(field) is False, f"manifest mutation {field} must be false")

    proc = subprocess.run(
        [str(runtime_path), str(config_path), str(manifest_path), str(fixture_path)],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    require(proc.returncode == 0, f"runtime failed: {proc.stderr}")

    if proc.returncode == 0:
        runtime = json.loads(proc.stdout)
        require(runtime.get("runtime_status") == "PASS", "runtime status must be PASS")
        require(runtime.get("mode") == "faz_6_r_final_review_closure_dry_run", "runtime mode mismatch")
        require(runtime.get("required_evidence_count") == runtime.get("required_evidence_pass_count"), "not all evidence passed")
        require(runtime.get("all_required_evidence_status") == "READY", "runtime evidence status must be READY")
        require(runtime.get("all_priority_blocks_status") == "PASS", "runtime priority status must be PASS")
        require(runtime.get("sre_edge_release_status") == "PASS", "runtime release status must be PASS")
        require(runtime.get("final_closure_status") == "SEALED", "runtime final closure must be SEALED")
        require(runtime.get("ready_for_next_phase") is True, "runtime ready for next phase must be true")
        for field in [
            "runtime_mutation_allowed",
            "provider_mutation_allowed",
            "production_release_execute_allowed",
            "deploy_execute_allowed",
            "dns_mutation_allowed",
            "cdn_invalidation_allowed",
            "db_mutation_allowed",
            "build_publish_allowed",
            "failover_execute_allowed",
            "remediation_execute_allowed"
        ]:
            require(runtime.get(field) is False, f"runtime {field} must be false")

if errors:
    for err in errors:
        print(f"VALIDATION_FAIL: {err}")
    sys.exit(1)

print("VALIDATION_PASS: FAZ 6-R final review / closure config, manifest, fixture and dry-run runtime are semantically valid")
PY
