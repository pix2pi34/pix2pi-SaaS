# FAZ 5-R / 275 — FAZ 5-19.3 Developer Docs Portalı

## Amaç

Bu adım, public/developer surface hattında developer docs portalını internal preview olarak hazırlar.

Bu çalışma production docs yayını, gerçek developer erişimi, API key oluşturma veya canlı sandbox erişimi açmaz.

## Kapsam

1. developer_overview
2. authentication_docs
3. tenant_context_docs
4. api_reference_docs
5. webhook_docs
6. sandbox_usage_docs
7. security_compliance_docs
8. support_sla_docs
9. api_key_screen_deferred_marker

## Kritik kurallar

- Production docs publish kapalı kalır.
- Real developer access kapalı kalır.
- API key creation kapalı kalır.
- Sandbox live kapalı kalır.
- Public copy guard zorunludur.
- Versioning zorunludur.
- Endpoint catalog zorunludur.
- Auth guide zorunludur.
- Tenant header guide zorunludur.
- Rate limit notice zorunludur.
- Webhook guide zorunludur.
- Sandbox guide zorunludur.
- Security notice zorunludur.
- Support path zorunludur.
- Legal review zorunludur.
- Founder approval zorunludur.
- Change log zorunludur.
- Audit trail zorunludur.

## Web artifact

web/faz5r/developer-docs/index.html

## Final policy

INTERNAL_DEVELOPER_DOCS_PORTAL_READY=true  
STATIC_HTML_READY=true  
PRODUCTION_DOCS_PUBLISHED=false  
REAL_DEVELOPER_ACCESS_ENABLED=false  
API_KEY_CREATION_ENABLED=false  
SANDBOX_LIVE_ENABLED=false  
API_KEY_MANAGEMENT_SCREEN_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_19_4_API_KEY_YONETIM_EKRANI
