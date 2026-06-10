# FAZ 5-R / 276 — FAZ 5-19.4 API Key Yönetim Ekranı

## Amaç

Bu adım, public/developer surface hattında API key yönetim ekranını internal preview olarak hazırlar.

Bu çalışma production screen yayını, gerçek developer erişimi, API key oluşturma, API key reveal, API key rotation veya canlı sandbox erişimi açmaz.

## Kapsam

1. key_inventory
2. key_create_disabled_panel
3. key_masked_secret_panel
4. key_rotation_preview
5. key_revoke_preview
6. permission_scope_panel
7. tenant_scope_panel
8. audit_trail_panel
9. security_policy_panel
10. sandbox_surface_deferred_marker

## Kritik kurallar

- Production screen publish kapalı kalır.
- Real developer access kapalı kalır.
- API key creation kapalı kalır.
- API key reveal kapalı kalır.
- API key rotation kapalı kalır.
- Sandbox live kapalı kalır.
- tenant_id zorunludur.
- developer account zorunludur.
- role guard zorunludur.
- permission scope zorunludur.
- key name zorunludur.
- masked secret display zorunludur.
- create disabled guard zorunludur.
- reveal disabled guard zorunludur.
- rotate disabled guard zorunludur.
- revoke preview zorunludur.
- audit trail zorunludur.
- rate limit policy zorunludur.
- expiry policy zorunludur.
- security notice zorunludur.
- legal review zorunludur.
- founder approval zorunludur.
- change log zorunludur.

## Web artifact

web/faz5r/api-key-management/index.html

## Final policy

INTERNAL_API_KEY_SCREEN_READY=true  
STATIC_HTML_READY=true  
PRODUCTION_SCREEN_PUBLISHED=false  
REAL_DEVELOPER_ACCESS_ENABLED=false  
API_KEY_CREATION_ENABLED=false  
API_KEY_REVEAL_ENABLED=false  
API_KEY_ROTATION_ENABLED=false  
SANDBOX_LIVE_ENABLED=false  
SANDBOX_SURFACE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_19_5_SANDBOX_KULLANIM_YUZEYI
