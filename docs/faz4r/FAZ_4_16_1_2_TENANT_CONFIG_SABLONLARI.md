# 196 — FAZ 4-16.1.2 Tenant Config Şablonları

## Amaç

Pilot tenant için kullanılacak kontrollü tenant config şablonlarını standartlaştırır.

Bu adım 195 — Pilot tenant açılış akışı PASS olduktan sonra gelir.

## Şablon Kapsamı

Tenant config şablonu aşağıdaki alanları kapsar:

- Tenant identity
- Pilot mode
- Locale / timezone / currency
- Tenant isolation strategy
- Module flags
- Import limits
- UAT limits
- User / role limits
- Readmodel / reporting flags
- Support / issue flags
- Rollback / cutover guard
- Audit policy
- Security baseline
- Live external provider / GIB / banka / POS kapalı policy gate

## Ana Kural

Config şablonu canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Tenant config template PASS sayılırsa:

- template_status = READY olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- pilot_mode = CONTROLLED_PILOT olmalıdır.
- default_currency = TRY olmalıdır.
- timezone = Europe/Istanbul olmalıdır.
- language = tr-TR olmalıdır.
- tenant isolation config hazır olmalıdır.
- Tüm canlı dış entegrasyon flagleri CLOSED / false olmalıdır.
- Required modules kontrollü şekilde enabled/disabled olmalıdır.
- Kritik issue limit 0 olmalıdır.
- Import / UAT / support limitleri 192 pilot veri sınırları ile uyumlu olmalıdır.
- Audit evidence policy açık olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Tenant config şablonu dokümanı vardır.
- Master config artifact vardır.
- Tenant config template artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
