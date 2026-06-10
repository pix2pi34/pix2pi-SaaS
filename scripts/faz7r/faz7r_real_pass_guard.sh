#!/usr/bin/env bash
set -Eeuo pipefail

faz7r_forbidden_partial_pattern() {
  printf '%s' 'disabled|placeholder|preview|dry[- ]?run|real[_[:alnum:]]*enabled[[:space:]]*[:=][[:space:]]*("?false"?|false)|backend disabled|provider closed|closed_until|not_started|mutation disabled|activation disabled|send disabled|issue disabled|enforcement disabled'
}

faz7r_pass_claim_pattern() {
  printf '%s' 'FINAL_STATUS=PASS|REAL_IMPLEMENTATION_STATUS=PASS|_REAL_IMPLEMENTATION_STATUS=PASS|PASS_COUNT=[1-9][0-9]*'
}

faz7r_scan_evidence_file() {
  local file="$1"
  local partial_pattern
  local pass_pattern
  local has_pass=0
  local marker=""

  partial_pattern="$(faz7r_forbidden_partial_pattern)"
  pass_pattern="$(faz7r_pass_claim_pattern)"

  if grep -Eiq "$pass_pattern" "$file"; then
    has_pass=1
  fi

  marker="$(grep -Eini "$partial_pattern" "$file" | head -n 1 || true)"

  if [[ "$has_pass" -eq 1 && -n "$marker" ]]; then
    printf "%s\t%s\t%s\t%s\n" "$file" "INVALID_PARTIAL_PASS" "PASS evidence contains forbidden partial/dry-run/disabled marker" "$marker"
    return 20
  fi

  if [[ "$has_pass" -eq 1 ]]; then
    printf "%s\t%s\t%s\t%s\n" "$file" "OLD_PASS_NO_FORBIDDEN_MARKER_FOUND" "PASS evidence has no forbidden marker by scanner" "-"
    return 0
  fi

  if [[ -n "$marker" ]]; then
    printf "%s\t%s\t%s\t%s\n" "$file" "PARTIAL_MARKER_NO_PASS" "Partial marker exists but no PASS claim found" "$marker"
    return 10
  fi

  return 0
}
