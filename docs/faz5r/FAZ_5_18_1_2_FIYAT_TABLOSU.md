# FAZ 5-R / 272 — FAZ 5-18.1.2 Fiyat Tablosu

## Amaç

Bu adım, public launch öncesi fiyat tablosunu contract seviyesinde hazırlar.

Bu çalışma production fiyat yayını, gerçek müşteri billing, gerçek tahsilat veya public checkout açmaz. Amaç; Free, Starter, Pro ve Enterprise satırlarını plan kodu, para birimi, aylık/yıllık fiyat, KDV politikası, kullanıcı/tenant limiti, entitlement referansı ve billing politikasıyla kontrollü şekilde tanımlamaktır.

## Kapsam

1. free_plan_row
2. starter_plan_row
3. pro_plan_row
4. enterprise_plan_row
5. accountant_package_deferred_marker

## Kritik kurallar

- Production pricing publish kapalı kalır.
- Real customer billing kapalı kalır.
- Payment collection kapalı kalır.
- Public checkout kapalı kalır.
- Plan code zorunludur.
- Currency zorunludur.
- Monthly price zorunludur.
- Annual price zorunludur.
- VAT / KDV policy zorunludur.
- User limit zorunludur.
- Tenant limit zorunludur.
- Feature summary zorunludur.
- Entitlement reference zorunludur.
- Billing policy zorunludur.
- Legal review zorunludur.
- Founder approval zorunludur.
- Change log zorunludur.
- Public copy guard zorunludur.

## Final policy

INTERNAL_PRICING_TABLE_READY=true  
PRODUCTION_PRICING_PUBLISHED=false  
REAL_CUSTOMER_BILLING_ENABLED=false  
PAYMENT_COLLECTION_ENABLED=false  
PUBLIC_CHECKOUT_ENABLED=false  
ACCOUNTANT_PACKAGE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_1_4_MUHASEBECI_OZEL_PAKETLERI
