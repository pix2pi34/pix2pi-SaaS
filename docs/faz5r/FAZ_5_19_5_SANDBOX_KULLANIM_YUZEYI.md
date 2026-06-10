# FAZ 5-R / 277 — FAZ 5-19.5 Sandbox Kullanım Yüzeyi

## Amaç

Bu adım, public/developer surface hattında sandbox kullanım yüzeyini internal preview olarak hazırlar.

Bu çalışma production sandbox yayını, gerçek developer erişimi, canlı API çağrısı, canlı veri mutasyonu, gerçek ödeme simülasyonu veya gerçek API key oluşturma açmaz.

## Kapsam

1. sandbox_overview
2. mock_credentials_panel
3. sample_requests_panel
4. sample_responses_panel
5. webhook_mock_panel
6. tenant_scope_panel
7. data_reset_policy_panel
8. security_notice_panel
9. pricing_pages_deferred_marker

## Kritik kurallar

- Production sandbox publish kapalı kalır.
- Real developer access kapalı kalır.
- Live API call kapalı kalır.
- Live data mutation kapalı kalır.
- Payment simulation live kapalı kalır.
- API key creation kapalı kalır.
- tenant_id zorunludur.
- mock credential zorunludur.
- sample request zorunludur.
- sample response zorunludur.
- tenant isolation notice zorunludur.
- rate limit preview zorunludur.
- webhook mock guide zorunludur.
- data reset policy zorunludur.
- audit trail zorunludur.
- security notice zorunludur.
- support path zorunludur.
- legal review zorunludur.
- founder approval zorunludur.
- change log zorunludur.

## Web artifact

web/faz5r/sandbox-surface/index.html

## Final policy

INTERNAL_SANDBOX_SURFACE_READY=true  
STATIC_HTML_READY=true  
PRODUCTION_SANDBOX_PUBLISHED=false  
REAL_DEVELOPER_ACCESS_ENABLED=false  
LIVE_API_CALL_ENABLED=false  
LIVE_DATA_MUTATION_ENABLED=false  
PAYMENT_SIMULATION_LIVE_ENABLED=false  
API_KEY_CREATION_ENABLED=false  
PRICING_PAGES_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_19_2_FIYATLAMA_SAYFALARI
