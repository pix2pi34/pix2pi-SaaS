# FAZ 5-R / 279 — FAZ 5-19.6 Public / Developer Web Testleri

## Amaç

Bu adım, FAZ 5-R Public / Developer Surfaces hattındaki internal preview web yüzeylerini test eder.

Test edilen yüzeyler:

1. web/faz5r/developer-docs/index.html
2. web/faz5r/api-key-management/index.html
3. web/faz5r/sandbox-surface/index.html
4. web/faz5r/pricing-pages/index.html

## Kapsam

1. developer_docs_web
2. api_key_management_web
3. sandbox_surface_web
4. pricing_pages_web
5. launch_guard_matrix
6. html_quality_matrix
7. security_guard_matrix
8. final_closure_deferred_marker

## Kritik kurallar

- Production publish kapalı kalır.
- Real customer access kapalı kalır.
- Real developer access kapalı kalır.
- Checkout kapalı kalır.
- Payment collection kapalı kalır.
- API key creation kapalı kalır.
- Sandbox live kapalı kalır.
- Her HTML yüzeyde noindex bulunur.
- Her HTML yüzeyde viewport bulunur.
- Her HTML yüzeyde marker bulunur.
- Her HTML yüzeyde launch guard bulunur.
- Tenant safety, security notice ve support path kontrolleri izlenir.

## Final policy

INTERNAL_WEB_TESTS_READY=true  
PUBLIC_DEVELOPER_SURFACE_TESTS_READY=true  
PRODUCTION_PUBLISH_ALLOWED=false  
REAL_CUSTOMER_ACCESS_ENABLED=false  
REAL_DEVELOPER_ACCESS_ENABLED=false  
CHECKOUT_ENABLED=false  
PAYMENT_COLLECTION_ENABLED=false  
API_KEY_CREATION_ENABLED=false  
SANDBOX_LIVE_ENABLED=false  
FAZ_5_R_PRIORITY_4_WEB_L8_COMPLETE=true  
FAZ_5_R_FINAL_REVIEW_CLOSURE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_R_FINAL_REVIEW_CLOSURE
