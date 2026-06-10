# FAZ 5-R / 273 — FAZ 5-18.1.4 Muhasebeci Özel Paketleri

## Amaç

Bu adım, muhasebeci portalı için özel paketleri contract seviyesinde hazırlar.

Bu çalışma production paket yayını, gerçek müşteri billing, gerçek tahsilat veya muhasebeci portal commercial aktivasyon açmaz. Amaç; muhasebeci paketlerinin firma başı ücret, kullanıcı limiti, export hakkı, portal entitlement, firma atama politikası, aylık revalidation ve KVKK/data access sınırlarıyla kontrollü şekilde tanımlanmasıdır.

## Kapsam

1. accountant_starter_package
2. accountant_pro_package
3. accountant_enterprise_package
4. pricing_validation_deferred_marker

## Kritik kurallar

- Production package publish kapalı kalır.
- Real customer billing kapalı kalır.
- Payment collection kapalı kalır.
- Accountant portal commercial activation kapalı kalır.
- Package code zorunludur.
- Currency zorunludur.
- Monthly base fee zorunludur.
- Per company fee zorunludur.
- VAT / KDV policy zorunludur.
- Company limit zorunludur.
- Accountant user limit zorunludur.
- Export rights zorunludur.
- Portal entitlement zorunludur.
- Company assignment policy zorunludur.
- Monthly revalidation zorunludur.
- Billing policy zorunludur.
- KVKK scope zorunludur.
- Data access policy zorunludur.
- Legal review zorunludur.
- Founder approval zorunludur.
- Change log zorunludur.
- Public copy guard zorunludur.

## Final policy

INTERNAL_ACCOUNTANT_PACKAGE_READY=true  
PRODUCTION_PACKAGE_PUBLISHED=false  
REAL_CUSTOMER_BILLING_ENABLED=false  
PAYMENT_COLLECTION_ENABLED=false  
ACCOUNTANT_PORTAL_COMMERCIAL_ENABLED=false  
PRICING_VALIDATION_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_1_5_FIYATLAMA_DOGRULAMA
