# 198 — FAZ 4-16.2.1 Cari Import

## Amaç

Pilot tenant için cari import akışını controlled pilot seviyesinde standartlaştırır.

Bu adım müşteri / tedarikçi cari kartlarının import edilmeden önce dry-run doğrulamasını yapar.

## Kapsam

Cari import aşağıdaki alanları kapsar:

- Tenant guard
- Import batch guard
- Dry-run zorunluluğu
- Cari kodu
- Cari unvanı / adı
- Cari tipi
- Cari yönü: CUSTOMER / SUPPLIER / BOTH
- Şirket cari alanları
- Şahıs cari alanları
- Vergi no
- Vergi dairesi
- MERSIS no opsiyonel alanı
- Adres
- Telefon
- E-posta
- Duplicate cari kodu guard
- Duplicate vergi no guard
- Import limit guard
- External provider closed policy gate

## Şirket Cari Zorunlu Alanları

Şirket tipi cari kartlarda zorunlu alanlar:

- customer_code
- customer_name
- customer_type = COMPANY
- tax_no
- tax_office
- address.full_address
- address.city

MERSIS no opsiyoneldir.

## Şahıs Cari Zorunlu Alanları

Şahıs tipi cari kartlarda zorunlu alanlar:

- customer_code
- customer_name
- customer_type = INDIVIDUAL
- address.full_address
- address.city

national_id veya tax_no alanlarından en az biri dolu olmalıdır.

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek DB commit yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Cari import PASS sayılırsa:

- import_mode = DRY_RUN olmalıdır.
- commit_requested = false olmalıdır.
- tenant_id dolu olmalıdır.
- batch_id dolu olmalıdır.
- total_rows gerçek satır sayısıyla eşleşmelidir.
- total_rows pilot sınırları içinde kalmalıdır.
- Her satırda customer_code ve customer_name dolu olmalıdır.
- Şirket carilerde tax_no, tax_office ve adres alanları dolu olmalıdır.
- Duplicate customer_code olmamalıdır.
- Duplicate tax_no olmamalıdır.
- E-posta varsa format doğru olmalıdır.
- Telefon varsa format kontrolünden geçmelidir.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Cari import dokümanı vardır.
- Master config artifact vardır.
- Mapping artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Duplicate guard doğrulanır.
- Şirket zorunlu alan guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
