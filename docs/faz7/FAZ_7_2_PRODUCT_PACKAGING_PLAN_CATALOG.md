# 7-2 — Product Packaging / Plan Catalog

## Adim Amaci

Bu adim Pix2pi icin urun paketlerini, plan katalogunu, feature matrix yapisini ve limit kurallarini sabitler.

7-2 sonunda:

- Starter paket tanimlanir.
- Pro paket tanimlanir.
- Enterprise paket tanimlanir.
- Muhasebeci paketi tanimlanir.
- Marketplace / entegrasyon paketi tanimlanir.
- Feature matrix olusturulur.
- Kullanici, tenant, API ve export limitleri tanimlanir.
- 7-3 Entitlement Runtime / Feature Gate icin hazirlik yapilir.

## 7-2.1 Paket Mimarisi

### 7-2.1.1 Starter Paket
Durum: IMPLEMENTED_OR_PRESENT

Starter paket, kucuk isletmeler ve ilk pilot/demo kullanimlar icin temel SaaS paketidir.

Ana haklar:

- Temel ERP yuzeyi
- Temel stok takibi
- Temel cari yonetimi
- Temel rapor goruntuleme
- Sinirli kullanici hakki
- Sinirli export hakki
- API erisimi kapali veya sinirli

### 7-2.1.2 Pro Paket
Durum: IMPLEMENTED_OR_PRESENT

Pro paket, aktif isletmelerin gunluk operasyonlari icin ana ticari pakettir.

Ana haklar:

- ERP core
- POS hazirligi
- Gelismis stok
- Gelismis rapor
- API temel erisim
- Marketplace discovery erisimi
- Daha yuksek kullanici limiti

### 7-2.1.3 Enterprise Paket
Durum: IMPLEMENTED_OR_PRESENT

Enterprise paket, cok subeli, yuksek hacimli ve ozel ihtiyaclari olan firmalar icin kurumsal pakettir.

Ana haklar:

- Tum Pro haklari
- Yuksek kullanici limiti
- Yuksek API limiti
- Ozel entegrasyon hazirligi
- SLA / support hazirligi
- Gelismis audit ve ops gorunumu

### 7-2.1.4 Muhasebeci Paketi
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci paketi, bir muhasebecinin birden fazla firmaya erisim saglayabilmesi icin ticari modeldir.

Ana haklar:

- Cok firmali erisim
- Firma basi yetkilendirme
- Excel/PDF/TDHP export hazirligi
- Firma basi aylik hak modeli
- Muhasebeci portal entitlement hazirligi

### 7-2.1.5 Marketplace / Entegrasyon Paketi
Durum: IMPLEMENTED_OR_PRESENT

Marketplace / entegrasyon paketi, pazaryeri, Paraşut benzeri entegrasyonlar, webhook ve public API kullanimlari icin hazirlik paketidir.

Ana haklar:

- Entegrasyon katalogu
- Webhook hazirligi
- Public API hazirligi
- Pazaryeri entegrasyon hazirligi
- Entegrasyon bazli upsell modeli

## 7-2.2 Feature Matrix

### 7-2.2.1 Modul Bazli Yetki
Durum: IMPLEMENTED_OR_PRESENT

Her paket hangi modulun acik veya kapali oldugunu acik sekilde tasir.

Modul ornekleri:

- erp_core
- pos_ready
- reporting_basic
- reporting_advanced
- api_access
- marketplace_discovery
- accountant_portal
- integration_catalog
- webhook_access
- commercial_ops

### 7-2.2.2 Kullanici Limiti
Durum: IMPLEMENTED_OR_PRESENT

Her paketin kullanici sayisi limiti ayridir.

Baslangic modeli:

- Starter: 3 kullanici
- Pro: 15 kullanici
- Enterprise: 250 kullanici
- Accountant: 20 kullanici
- Marketplace: 10 kullanici

### 7-2.2.3 Tenant Limiti
Durum: IMPLEMENTED_OR_PRESENT

Her paket kac tenant/firma yonetebilecegini belirtir.

Baslangic modeli:

- Starter: 1 tenant
- Pro: 1 tenant
- Enterprise: 50 tenant veya sube/firma kapsami
- Accountant: 100 firma baglantisi
- Marketplace: 5 entegrasyon tenant kapsami

### 7-2.2.4 API Hakki
Durum: IMPLEMENTED_OR_PRESENT

API hakki paket bazli belirlenir.

Baslangic modeli:

- Starter: 0 veya cok sinirli
- Pro: temel API
- Enterprise: yuksek API
- Accountant: export odakli API
- Marketplace: entegrasyon odakli API

### 7-2.2.5 Export Hakki
Durum: IMPLEMENTED_OR_PRESENT

Export hakki paket bazli belirlenir.

Baslangic modeli:

- Starter: sinirli export
- Pro: standart export
- Enterprise: gelismis export
- Accountant: cok firmali export
- Marketplace: entegrasyon veri cikisi

### 7-2.2.6 Muhasebeci Erisim Hakki
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci erisimi sadece ilgili paket veya entitlement ile acilir.

## 7-2.3 Plan Catalog Config

Durum: IMPLEMENTED_OR_PRESENT

Plan catalog config dosyasi:

- configs/faz7/product_plan_catalog.v1.json

Bu dosya 7-3 entitlement runtime icin kaynak olarak kullanilacaktir.

## 7-2.4 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Plan catalog Go modeli:

- internal/platform/commercial/catalog/catalog.go
- internal/platform/commercial/catalog/catalog_test.go

Bu model paketlerin ve feature matrix kurallarinin kod karsiligidir.

## 7-2.5 7-3 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-2 tamamlandiginda 7-3 icin asagidaki bilgiler hazirdir:

- Plan kodlari
- Feature kodlari
- Limit kodlari
- Plan-feature iliskisi
- Plan-limit iliskisi
- Entitlement runtime icin temel source of truth

## 7-2 Final Karari

- FAZ_7_2_DOC_STATUS=READY
- FAZ_7_2_CONFIG_STATUS=READY
- FAZ_7_2_CODE_STATUS=READY
- FAZ_7_2_TEST_REQUIRED=YES
- FAZ_7_2_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_3_READY_CONDITION=FAZ_7_2_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
