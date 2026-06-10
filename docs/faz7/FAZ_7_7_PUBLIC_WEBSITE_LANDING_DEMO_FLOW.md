# 7-7 — Public Website / Landing / Demo Flow

## Adim Amaci

Bu adim Pix2pi icin public website, landing page ve demo/trial talep akisini hazirlar.

7-7 sonunda:

- Public landing page modeli hazirlanir.
- Paket/fiyat gosterimi hazirlanir.
- Demo talep formu modellenir.
- Trial baslatma CTA modeli hazirlanir.
- SEO / schema hazirligi yapilir.
- Demo lead runtime olusturulur.
- Static public demo HTML checkpoint olusturulur.
- 7-8 Marketplace / Integration Catalog Foundation icin temel hazirlanir.

## 7-7.1 Public Yuzey

### 7-7.1.1 Public landing page
Durum: IMPLEMENTED_OR_PRESENT

Public landing page, Pix2pi'nin ticari urun yuzudur.

Sayfa temel mesajlari:

- SaaS ERP
- POS hazirligi
- Stok / cari / rapor
- Muhasebeci portal hazirligi
- Marketplace / entegrasyon hazirligi
- Demo talep akisi

### 7-7.1.2 Paket/fiyat gosterimi
Durum: IMPLEMENTED_OR_PRESENT

Landing yuzeyi 7-2 plan catalog ile uyumlu paketleri gosterir:

- Starter
- Pro
- Enterprise
- Muhasebeci
- Marketplace Integration

Fiyatlar 7-5 billing readiness plan fiyatlari ile uyumlu hazirlanir.

### 7-7.1.3 Demo talep formu
Durum: IMPLEMENTED_OR_PRESENT

Demo talep formu asagidaki alanlari toplar:

- business_name
- contact_name
- email
- phone
- company_size
- requested_plan
- message
- consent_accepted

### 7-7.1.4 Trial baslatma yuzeyi
Durum: IMPLEMENTED_OR_PRESENT

Trial baslatma CTA modeli 7-6 tenant onboarding akisi ile uyumludur.

Trial akisi dogrudan public production acmaz.
Demo/trial lead olusturur ve onboarding gate'e hazirlar.

### 7-7.1.5 SEO / schema hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Landing sayfasi SEO ve schema hazirligi tasir:

- title
- description
- canonical placeholder
- SoftwareApplication JSON-LD
- organization bilgisi
- product offering izi

## 7-7.2 Demo Lead Runtime

### 7-7.2.1 Demo request validation
Durum: IMPLEMENTED_OR_PRESENT

Demo talebi zorunlu alanlar olmadan kabul edilmez.

### 7-7.2.2 Consent gate
Durum: IMPLEMENTED_OR_PRESENT

KVKK/ticari iletisim hazirligi icin consent_accepted true olmadan demo talebi kabul edilmez.

### 7-7.2.3 Requested plan validation
Durum: IMPLEMENTED_OR_PRESENT

requested_plan 7-2 plan catalog icinde mevcut olmalidir.

### 7-7.2.4 Lead status model
Durum: IMPLEMENTED_OR_PRESENT

Lead status degerleri:

- NEW
- QUALIFIED
- READY_FOR_ONBOARDING
- REJECTED

### 7-7.2.5 Onboarding readiness
Durum: IMPLEMENTED_OR_PRESENT

Demo lead, uygun durumda 7-6 tenant onboarding icin hazir hale getirilebilir.

## 7-7.3 Static Public Checkpoint

Durum: IMPLEMENTED_OR_PRESENT

Static HTML checkpoint:

- web/faz7/public-demo/index.html

Bu dosya gercek production public launch degildir.
Public website UI checkpoint olarak kullanilir.

## 7-7.4 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Public demo runtime Go modeli:

- internal/platform/commercial/publicdemo/publicdemo.go
- internal/platform/commercial/publicdemo/publicdemo_test.go

## 7-7.5 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Public demo flow config dosyasi:

- configs/faz7/public_demo_flow.v1.json

## 7-7.6 7-8 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-7 tamamlandiginda 7-8 icin asagidaki temeller hazirdir:

- public entegrasyon mesajlari
- marketplace discovery CTA
- integration catalog CTA
- webhook/public API CTA
- demo lead uzerinden entegrasyon ilgisi toplama

## 7-7 Final Karari

- FAZ_7_7_DOC_STATUS=READY
- FAZ_7_7_CONFIG_STATUS=READY
- FAZ_7_7_CODE_STATUS=READY
- FAZ_7_7_WEB_STATUS=READY
- FAZ_7_7_TEST_REQUIRED=YES
- FAZ_7_7_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_8_READY_CONDITION=FAZ_7_7_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
