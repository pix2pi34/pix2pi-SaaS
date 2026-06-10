#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_BASE="${ARCHIVE_BASE:-/var/log/pix2pi/archive}"
BACKUP_BASE="${BACKUP_BASE:-/root/pix2pi/pix2pi-SaaS/backups}"

ARCHIVE_RETENTION_DAYS="${ARCHIVE_RETENTION_DAYS:-14}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
APPLY="${APPLY:-0}"

info() {
  echo "INFO ▶ $1" >&2
}

ok() {
  echo "OK ✅ $1"
}

fail() {
  echo "ERROR ❌ $1" >&2
  exit 1
}

is_protected_name() {
  local base="$1"

  case "$base" in
    keep_*|api-gateway|app|nginx|panel|scripts|step_*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_rotatable_dirname() {
  local base="$1"

  if [[ "$base" =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
    return 0
  fi

  if [[ "$base" =~ ^[A-Za-z0-9._-]+_[0-9]{8}_[0-9]{6}$ ]]; then
    return 0
  fi

  return 1
}

collect_candidates() {
  local base_dir="$1"
  local retention_days="$2"

  if [ ! -d "$base_dir" ]; then
    return 0
  fi

  while IFS= read -r path; do
    [ -n "$path" ] || continue

    local base_name
    base_name="$(basename "$path")"

    if is_protected_name "$base_name"; then
      info "protected skip -> $path"
      continue
    fi

    if ! is_rotatable_dirname "$base_name"; then
      info "naming guard skip -> $path"
      continue
    fi

    echo "$path"
  done < <(
    find "$base_dir" -mindepth 1 -maxdepth 1 -type d -mtime +"$retention_days" 2>/dev/null | sort
  )
}

delete_candidates() {
  local label="$1"
  shift

  if [ "$#" -eq 0 ]; then
    ok "$label aday yok"
    return 0
  fi

  if [ "$APPLY" != "1" ]; then
    ok "dry-run modunda, silme yapilmadi"
    return 0
  fi

  local path
  for path in "$@"; do
    rm -rf -- "$path"
    ok "silindi -> $path"
  done
}

print_candidate_block() {
  local title="$1"
  shift

  echo
  echo "===== $title ====="

  if [ "$#" -eq 0 ]; then
    ok "aday yok"
    return 0
  fi

  local path
  for path in "$@"; do
    du -sh "$path"
  done
}

main() {
  echo "===== STEP 57Z / OPS RETENTION CLEANUP ====="
  info "ARCHIVE_BASE=$ARCHIVE_BASE"
  info "BACKUP_BASE=$BACKUP_BASE"
  info "ARCHIVE_RETENTION_DAYS=$ARCHIVE_RETENTION_DAYS"
  info "BACKUP_RETENTION_DAYS=$BACKUP_RETENTION_DAYS"
  info "APPLY=$APPLY"

  mapfile -t archive_candidates < <(collect_candidates "$ARCHIVE_BASE" "$ARCHIVE_RETENTION_DAYS")
  mapfile -t backup_candidates < <(collect_candidates "$BACKUP_BASE" "$BACKUP_RETENTION_DAYS")

  print_candidate_block "ARCHIVE SILINECEK ADAYLAR" "${archive_candidates[@]}"
  print_candidate_block "BACKUP SILINECEK ADAYLAR" "${backup_candidates[@]}"

  info "archive_aday_sayisi=${#archive_candidates[@]}"
  info "backup_aday_sayisi=${#backup_candidates[@]}"

  echo
  echo "===== APPLY MODU ====="
  delete_candidates "archive" "${archive_candidates[@]}"
  delete_candidates "backup" "${backup_candidates[@]}"

  ok "step_57z_retention_cleanup_gecti"
}

main "$@"
