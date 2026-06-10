# Phoenix Small Font + Delete Button UI Fix Audit

## Changes

- Reduced global font size
- Reduced h1 size
- Reduced cards/list/detail spacing
- Added Sil button in detail actions
- Delete flow uses safe confirm twice
- Delete endpoint fallback order:
  - POST /api/delete
  - DELETE /api/applications/:id
  - DELETE /api/companies/:id
  - DELETE /api/applications/:file
  - DELETE /api/companies/:file

## Marker

PHOENIX_SMALL_FONT_DELETE_BUTTON_UI_FIX_MARKER

## Tests

- source marker: PASS
- deleteRow exists: PASS
- CSS delete button exists: PASS
- npm build: PASS
- dist marker: PASS
- dist contains Sil: PASS
- live marker: PASS
- nginx -t: PASS
- local UI: PASS
- external UI: PASS

## Counts

- PASS_COUNT=15
- FAIL_COUNT=0
- WARN_COUNT=0

## URL

https://phoenix.pix2pi.com.tr/owner-panel/register-approvals/?v=20260517_231620
