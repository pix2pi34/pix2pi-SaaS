# Phoenix Registered Companies List Fix Audit

## Problem

Phoenix UI showed no registered companies although API contained records.

## Fix

- UI now reads /api/companies first
- Falls back to /api/applications and /api/list
- Supports payload arrays:
  - companies
  - applications
  - items
  - data
  - results
  - records
  - rows
- Preserves Basic Auth/session credentials with same-origin fetch
- Keeps approve/reject only for PENDING records

## Counts

- API_COUNT=7
- PASS_COUNT=16
- FAIL_COUNT=0
- WARN_COUNT=0

## Marker

PHOENIX_REGISTERED_COMPANIES_LIST_FIX_MARKER

## URL

https://phoenix.pix2pi.com.tr/owner-panel/register-approvals/?v=20260517_231232
