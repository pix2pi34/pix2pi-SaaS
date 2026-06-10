# FAZ 7-R / 334 PWA MOBILE REAL FINAL AUDIT

- PASS_COUNT=43
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- PWA_RUN_ID=pwa-mobile-334-20260513_203626
- CACHE_VERSION=pix2pi-pos-pwa-334-20260513_203626

## Manifest
```json
{
  "id": "/mobile-pos/",
  "name": "Pix2pi POS",
  "short_name": "Pix2pi POS",
  "description": "Pix2pi POS PWA mobile offline-ready shell",
  "lang": "tr-TR",
  "dir": "ltr",
  "start_url": "/mobile-pos/?source=pwa",
  "scope": "/",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#07090d",
  "theme_color": "#ffd60a",
  "categories": ["business", "productivity"],
  "icons": [
    {
      "src": "/assets/pwa/icon-192.svg",
      "sizes": "192x192",
      "type": "image/svg+xml",
      "purpose": "any maskable"
    },
    {
      "src": "/assets/pwa/icon-512.svg",
      "sizes": "512x512",
      "type": "image/svg+xml",
      "purpose": "any maskable"
    }
  ],
  "screenshots": [
    {
      "src": "/assets/pwa/splash.svg",
      "sizes": "1080x1920",
      "type": "image/svg+xml",
      "form_factor": "narrow"
    }
  ]
}

```
## Manifest headers
```
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Wed, 13 May 2026 17:36:27 GMT
content-type: application/json
content-length: 866
last-modified: Wed, 13 May 2026 17:36:26 GMT
etag: "6a04b69a-362"
cache-control: no-cache
x-pix2pi-route: 334-pwa-manifest
accept-ranges: bytes

```
## Service worker headers
```
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Wed, 13 May 2026 17:36:27 GMT
content-type: application/javascript
content-length: 1431
last-modified: Wed, 13 May 2026 17:36:26 GMT
etag: "6a04b69a-597"
service-worker-allowed: /
cache-control: no-cache
x-pix2pi-route: 334-pwa-service-worker
accept-ranges: bytes

```
## DB SELECT
```
pwa_runtime_check=1
pwa_cache_version=1
pwa_audit_events=6
pwa_audit_deny=0
```
## Rollback SELECT
```
rollback_audit=0
```
## Final SELECT
```
final_pwa_runtime=1
final_pwa_events=6
final_cache_version=pix2pi-pos-pwa-334-20260513_203626
```
## Check log
```
dependency PASS evidence: FAZ_7R_333_OFFLINE_POS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: pos_pwa.pwa_audit_events / OK ✅
table exists: pos_pwa.pwa_runtime_checks / OK ✅
PWA manifest/service worker/offline shell/mobile/icons written and mirrored to public root / OK ✅
manifest JSON valid / OK ✅
manifest display standalone / OK ✅
manifest start_url / OK ✅
manifest scope root / OK ✅
manifest icon 192 / OK ✅
manifest icon 512 / OK ✅
service worker cache version present / OK ✅
service worker skipWaiting present / OK ✅
service worker clients.claim present / OK ✅
cache update guard deletes old caches / OK ✅
offline shell marker present / OK ✅
mobile viewport safe-area present / OK ✅
mobile responsive media query present / OK ✅
mobile service worker registration present / OK ✅
nginx PWA/mobile route bind / OK ✅
MANIFEST_ROUTE_STATUS HTTP 200 valid JSON / OK ✅
SERVICE_WORKER_ROUTE_STATUS HTTP 200 cache version + scope header / OK ✅
OFFLINE_SHELL_ROUTE_STATUS HTTP 200 marker / OK ✅
MOBILE_POS_ROUTE_STATUS HTTP 200 marker + service worker register / OK ✅
PWA_ICON_STATUS icon-192 HTTP 200 / OK ✅
PWA_ICON_STATUS icon-512 HTTP 200 / OK ✅
PWA_SPLASH_STATUS splash HTTP 200 / OK ✅
INSTALLABILITY_SEMANTIC_STATUS manifest installable / OK ✅
PWA_DB_AUDIT_WRITE_STATUS runtime check/events inserted / OK ✅
REAL_DB_SELECT_STATUS pwa_runtime_check=1 / OK ✅
REAL_DB_SELECT_STATUS pwa_cache_version=1 / OK ✅
REAL_DB_SELECT_STATUS pwa_audit_events=6 / OK ✅
REAL_DB_SELECT_STATUS pwa_audit_deny=0 / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
FINAL_PWA_STATUS final_pwa_runtime=1 / OK ✅
FINAL_PWA_STATUS final_pwa_events=6 / OK ✅
FINAL_PWA_STATUS cache_version exact / OK ✅
config semantic validation / OK ✅
```
