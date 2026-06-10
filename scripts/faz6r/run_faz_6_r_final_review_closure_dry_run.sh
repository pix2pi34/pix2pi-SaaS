#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-configs/faz6r/faz_6_r_final_review_closure.v1.json}"
MANIFEST_FILE="${2:-configs/faz6r/faz_6_r_final_review_closure_manifest.v1.json}"
FIXTURE_FILE="${3:-tests/faz6r/faz_6_r_final_review_closure_test.json}"

python3 - "$CONFIG_FILE" "$MANIFEST_FILE" "$FIXTURE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
manifest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

evidence_files = config.get("required_evidence_files", [])
evidence_results = []
for f in evidence_files:
    p = Path(f)
    exists = p.exists()
    text = p.read_text(encoding="utf-8") if exists else ""
    final_pass = "FINAL_STATUS=PASS" in text
    evidence_results.append({
        "file": f,
        "exists": exists,
        "final_pass": final_pass,
        "status": "PASS" if exists and final_pass else "FAIL"
    })

all_evidence_ready = all(x["status"] == "PASS" for x in evidence_results)
priority_ready = all(x.get("status") == "PASS" and x.get("ready") is True for x in manifest.get("priority_closure", []))

print(json.dumps({
    "runtime_status": "PASS" if all_evidence_ready and priority_ready else "FAIL",
    "mode": "faz_6_r_final_review_closure_dry_run",
    "runtime_mutation_allowed": config.get("runtime_mutation_allowed"),
    "provider_mutation_allowed": config.get("provider_mutation_allowed"),
    "production_release_execute_allowed": config.get("production_release_execute_allowed"),
    "deploy_execute_allowed": config.get("deploy_execute_allowed"),
    "dns_mutation_allowed": config.get("dns_mutation_allowed"),
    "cdn_invalidation_allowed": config.get("cdn_invalidation_allowed"),
    "db_mutation_allowed": config.get("db_mutation_allowed"),
    "build_publish_allowed": config.get("build_publish_allowed"),
    "failover_execute_allowed": config.get("failover_execute_allowed"),
    "remediation_execute_allowed": config.get("remediation_execute_allowed"),
    "required_evidence_count": len(evidence_results),
    "required_evidence_pass_count": sum(1 for x in evidence_results if x["status"] == "PASS"),
    "all_required_evidence_status": "READY" if all_evidence_ready else "FAIL",
    "all_priority_blocks_status": "PASS" if priority_ready else "FAIL",
    "sre_edge_release_status": "PASS" if all_evidence_ready and priority_ready else "FAIL",
    "final_closure_status": "SEALED" if all_evidence_ready and priority_ready else "OPEN",
    "ready_for_next_phase": bool(all_evidence_ready and priority_ready),
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "next_step": manifest.get("next_step", {}).get("step"),
    "evidence_results": evidence_results,
    "priority_closure": manifest.get("priority_closure", [])
}, indent=2, ensure_ascii=False))
PY
