# FAZ 5-3 — Entitlement Matrix / Module Rights

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-3
STEP_NAME=Entitlement Matrix / Module Rights
STEP_TITLE=Paket hak matrisi ve modül yetkileri
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_3_ENTITLEMENT_MATRIX_STATUS=PASS
FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED
FAZ_5_4_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_2_TEST_STATUS=PASS ✅
FAZ_5_2_PACKAGES_PRICING_STATUS=PASS ✅
FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED ✅
FAZ_5_3_READY=YES ✅

## 3. Amaç

Bu adımın amacı FAZ 5-2 içinde tanımlanan paketlerin hangi haklara sahip olduğunu netleştirmektir.

Bu adım sonunda:

- demo hakları tanımlanır.
- starter hakları tanımlanır.
- pro hakları tanımlanır.
- enterprise hakları tanımlanır.
- accountant hakları tanımlanır.
- Paket bazlı modül erişimi belirlenir.
- Kullanıcı, tenant, şube, API, export ve reporting limitleri belirlenir.
- 5-4 Subscription / Billing / Payment Ops için temel oluşturulur.

## 4. Entitlement Ana Prensipleri

| No | Prensip | Açıklama | Durum |
|---:|---|---|---|
| 1 | Default deny | Hak açık yazılmadıkça kapalı kabul edilir | ACCEPTED |
| 2 | Paket hakkı merkezi katalogdan okunur | Runtime ileride bu katalog mantığına bağlanır | ACCEPTED |
| 3 | Tenant güvenliği ticari haktan ayrılmaz | Her entitlement tenant-aware olmalıdır | ACCEPTED |
| 4 | Subscription durumu hakları etkiler | active, past_due, suspended, cancelled durumları hakları değiştirebilir | ACCEPTED |
| 5 | Enterprise özel hak alabilir | Enterprise hakları sözleşmeye göre override edilebilir | ACCEPTED |
| 6 | Muhasebeci paketi işletme paketinden ayrıdır | Firma erişimi ve export hakkı ayrı yönetilir | ACCEPTED |
| 7 | Demo canlı finansal işlem yapamaz | Demo sadece kontrollü deneme yüzeyidir | ACCEPTED |
| 8 | Export ve API ayrı gelir kalemidir | Paket veya upsell olarak yönetilir | ACCEPTED |

## 5. Ortak Modül Kataloğu

FAZ 5-3 içinde kullanılan ortak modül anahtarları:

| Modül Kodu | Açıklama |
|---|---|
| identity_core | Kimlik ve kullanıcı temel erişimi |
| tenant_core | Tenant temel erişimi |
| erp_core | ERP çekirdek |
| pos_core | POS çekirdek |
| inventory_basic | Temel stok |
| inventory_advanced | Gelişmiş stok |
| customer_account_basic | Müşteri / cari temel |
| reporting_basic | Temel raporlar |
| reporting_advanced | Gelişmiş raporlar |
| export_basic | Temel export |
| export_advanced | Gelişmiş export |
| accounting_export | Muhasebe exportları |
| api_access | API erişimi |
| marketplace_discovery | Marketplace discovery |
| parasut_discovery | Paraşüt discovery |
| accountant_portal | Muhasebeci portalı |
| developer_sandbox | Developer sandbox |
| auto_parts_compatibility | Oto yedek parça uyumluluk |
| audit_compliance | Gelişmiş audit / compliance |
| mobile_pwa | Mobile-ready PWA yüzeyi |
| premium_support | Premium destek |

## 6. Paket Hakları — Demo

Paket kodu:

- demo

Limitler:

- tenant_limit: 1
- branch_limit: 1
- user_limit: 2
- trial_days: 14
- test_product_limit: 100
- test_sales_limit: 50

Açık haklar:

- identity_core
- tenant_core
- erp_core limited
- pos_core sandbox
- inventory_basic demo
- customer_account_basic demo
- reporting_basic demo
- mobile_pwa preview

Kapalı haklar:

- api_access
- export_basic
- export_advanced
- accounting_export
- marketplace_discovery
- parasut_discovery
- accountant_portal
- developer_sandbox
- live_financial_operation

Support:

- demo_support

Karar:

ENTITLEMENT_DEFINED

## 7. Paket Hakları — Starter

Paket kodu:

- starter

Limitler:

- tenant_limit: 1
- branch_limit: 1
- user_limit: 3
- trial_days: 0

Açık haklar:

- identity_core
- tenant_core
- erp_core
- pos_core
- inventory_basic
- customer_account_basic
- reporting_basic
- export_basic limited
- mobile_pwa basic

Kapalı veya sınırlı haklar:

- api_access disabled
- export_advanced disabled
- accounting_export disabled
- marketplace_discovery disabled
- parasut_discovery disabled
- accountant_portal disabled
- developer_sandbox disabled
- audit_compliance disabled

Support:

- standard

Karar:

ENTITLEMENT_DEFINED

## 8. Paket Hakları — Pro

Paket kodu:

- pro

Limitler:

- tenant_limit: 1
- branch_limit: 3
- user_limit: 10
- trial_days: 0

Açık haklar:

- identity_core
- tenant_core
- erp_core
- pos_core
- inventory_basic
- inventory_advanced
- customer_account_basic
- reporting_basic
- reporting_advanced
- export_basic
- export_advanced
- marketplace_discovery
- parasut_discovery
- mobile_pwa
- accountant_sharing optional

Sınırlı haklar:

- api_access limited
- accounting_export limited
- developer_sandbox limited

Kapalı haklar:

- audit_compliance advanced disabled
- enterprise_sla disabled

Support:

- priority

Karar:

ENTITLEMENT_DEFINED

## 9. Paket Hakları — Enterprise

Paket kodu:

- enterprise

Limitler:

- tenant_limit: custom
- branch_limit: custom
- user_limit: custom
- trial_days: 0

Açık haklar:

- identity_core
- tenant_core
- erp_core
- pos_core
- inventory_basic
- inventory_advanced
- customer_account_basic
- reporting_basic
- reporting_advanced
- export_basic
- export_advanced
- accounting_export
- api_access
- marketplace_discovery
- parasut_discovery
- accountant_portal optional
- developer_sandbox
- auto_parts_compatibility
- audit_compliance
- mobile_pwa
- premium_support
- custom_onboarding
- enterprise_sla

Support:

- sla

Karar:

ENTITLEMENT_DEFINED

## 10. Paket Hakları — Accountant

Paket kodu:

- accountant

Limitler:

- workspace_limit: 1
- included_company_limit: 10
- per_company_monthly_try: 149
- user_limit: custom
- branch_limit: company_based
- tenant_limit: company_based

Açık haklar:

- identity_core
- tenant_core
- accountant_portal
- customer_company_view
- reporting_basic
- reporting_advanced
- export_basic
- export_advanced
- accounting_export
- excel_export
- pdf_export
- tdhp_export
- mobile_pwa

Sınırlı haklar:

- api_access limited
- logo_export future_optional
- mikro_export future_optional
- zirve_export future_optional
- eta_export future_optional

Kapalı haklar:

- pos_core direct_operation disabled
- live_pos_operation disabled
- marketplace_discovery disabled
- parasut_discovery limited_or_future

Support:

- accountant_support

Karar:

ENTITLEMENT_DEFINED

## 11. Subscription Durumuna Göre Hak Davranışı

| Subscription Durumu | Davranış |
|---|---|
| active | Paket hakları normal çalışır |
| trialing | Demo / trial limitleri uygulanır |
| past_due | Yazma işlemleri kademeli kısıtlanabilir |
| suspended | Login sınırlı, export/data handoff politikası ayrıca uygulanır |
| cancelled | Ticari erişim kapatılır, veri saklama politikası uygulanır |
| enterprise_hold | Enterprise sözleşme kararına göre özel durum uygulanır |

## 12. Freeze Policy

Tenant ödeme veya sözleşme nedeniyle askıya alınırsa:

- Kritik veri silinmez.
- Login tamamen kapatılmadan önce uyarı süreci işletilir.
- Export hakkı paket ve sözleşmeye göre değerlendirilir.
- API erişimi kapatılabilir.
- POS / ERP yazma işlemleri durdurulabilir.
- Read-only moda geçiş ileride uygulanabilir.

Karar:

FREEZE_POLICY_DEFINED

## 13. 5-4 İçin Aktarılacak Kararlar

5-4 Subscription / Billing / Payment Ops şu kararları baz alacak:

- Paket hakları entitlement_matrix_v1.json dosyasından türetilecek.
- active subscription normal hak verir.
- past_due subscription kısıtlı moda geçebilir.
- suspended subscription ticari erişimi durdurabilir.
- cancelled subscription veri saklama ve kapanış politikasına bağlanır.
- enterprise custom override desteklenir.
- accountant company-based billing ayrı ele alınır.

## 14. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Runtime entitlement middleware yazılmaz.
- Gerçek ödeme entegrasyonu yapılmaz.
- Abonelik lifecycle kodu yazılmaz.
- Tenant freeze runtime uygulanmaz.
- Public pricing sayfası yayınlanmaz.
- Enterprise sözleşme özel kuralları detaylandırılmaz.

Bu başlıklar sonraki FAZ 5 adımlarında ele alınacaktır.

## 15. Çıkış Kriterleri

Bu adım PASS sayılmak için:

- 5 paket için entitlement tanımlanmış olmalı
- Ortak modül kataloğu yazılmış olmalı
- Demo hakları kısıtlı olmalı
- Starter hakları temel olmalı
- Pro hakları büyüme paketi olmalı
- Enterprise özel / geniş hak olmalı
- Accountant ayrı firma bazlı ürün olmalı
- Subscription durum davranışı yazılmış olmalı
- Freeze policy yazılmış olmalı
- JSON entitlement matrix oluşturulmuş olmalı
- 5-4 geçiş izni verilmiş olmalı

## 16. 5-3 Mühür

FAZ_5_3_TEST_STATUS=PASS
FAZ_5_3_ENTITLEMENT_MATRIX_STATUS=PASS
FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED
FAZ_5_4_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
