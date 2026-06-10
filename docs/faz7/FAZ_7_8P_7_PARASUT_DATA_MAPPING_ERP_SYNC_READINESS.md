# FAZ 7-8P.7 Paraşüt Data Mapping / ERP Sync Contract Readiness

## Amaç

FAZ 7-8P.7, Paraşüt connector tarafında alınacak veya gönderilecek müşteri, ürün ve fatura verilerinin Pix2pi ERP modeliyle nasıl eşleneceğini tanımlar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Gerçek ERP write yapmaz. Data mapping, validation, idempotent sync key, duplicate/conflict handling ve ERP write contract dry-run katmanını hazırlar.

## Akış

1. Paraşüt source data gelir.
2. Tenant/provider/app guard çalışır.
3. Customer/product/invoice mapping contract çalışır.
4. Zorunlu alanlar doğrulanır.
5. Idempotent sync key üretilir.
6. Duplicate/conflict kararı verilir.
7. ERP write contract dry-run oluşturulur.
8. Operation audit event üretilir.
9. Real provider API ve real ERP write kapalı kalır.

## Kapsam

### 7-8P.7.1 Source Data Contract

- Paraşüt customer source model
- Paraşüt product source model
- Paraşüt invoice source model
- Tenant ID zorunlu
- Provider key zorunlu
- App key zorunlu
- External object ID zorunlu
- Correlation ID zorunlu

### 7-8P.7.2 Customer Mapping Contract

- Paraşüt customer → Pix2pi ERP customer
- Tax number / VKN-TCKN guard
- Customer name guard
- Email/phone optional normalization
- Provider external ID saklama
- Idempotent sync key

### 7-8P.7.3 Product Mapping Contract

- Paraşüt product → Pix2pi ERP product
- Product code/SKU guard
- Product name guard
- Unit guard
- VAT rate guard
- Provider external ID saklama
- Idempotent sync key

### 7-8P.7.4 Invoice Mapping Contract

- Paraşüt sales invoice → Pix2pi ERP invoice
- Invoice number guard
- Customer external ID guard
- Currency guard
- Amount minor guard
- VAT amount minor guard
- Line item guard
- Provider external ID saklama
- Idempotent sync key

### 7-8P.7.5 Conflict / Duplicate / Idempotency Contract

- Same sync key duplicate safe
- Same provider external ID conflict check
- Cross-tenant mapping rejected
- Object type mismatch rejected
- Conflict decision model
- Retry/no-retry decision marker

### 7-8P.7.6 ERP Write Contract Dry-Run / Final Closure

- ERP write request contract
- Dry-run only
- Real ERP write disabled
- Mapping audit event
- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek Paraşüt datası çekmez
- Gerçek ERP DB write yapmaz
- Gerçek stok/fatura/cari kaydı oluşturmaz
- Production sync job çalıştırmaz

Bu adım canlı sync öncesi veri eşleme ve ERP write contract hazırlığıdır.

## Final kapanış şartı

FAZ 7-8P.7 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Source data contract mevcut
- Customer mapping contract mevcut
- Product mapping contract mevcut
- Invoice mapping contract mevcut
- Idempotent sync key mevcut
- Conflict/duplicate handling mevcut
- ERP write dry-run contract mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
- Real ERP write gate kapalı
