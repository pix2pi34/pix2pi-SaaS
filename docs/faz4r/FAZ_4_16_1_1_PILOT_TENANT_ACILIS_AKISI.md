# 195 — FAZ 4-16.1.1 Pilot Tenant Açılış Akışı

## Amaç

Pilot tenant açılışının kontrollü, evidence tabanlı ve geri alınabilir şekilde yapılmasını sağlayan akışı tanımlar.

Bu adım 192, 193 ve 194 geçildikten sonra pilot tenant açılış kararını standartlaştırır.

## Açılış Akışı Kapsamı

Pilot tenant açılış akışı aşağıdaki kapıları içerir:

- Pilot veri sınırları PASS
- Tenant acceptance checklist PASS
- Onboarding smoke PASS
- Tenant identity hazırlanmış
- Tenant config hazırlanmış
- Tenant admin hazırlanmış
- Rol baseline hazırlanmış
- Kullanıcı davet hazırlığı tamamlanmış
- Import dry-run hazırlığı tamamlanmış
- Readmodel / reporting hazır
- Operational readmodel hazır
- Support / issue kanalı hazır
- Rollback / cutover guard hazır
- Audit evidence hazır
- Açılış onayı READY
- Kritik issue sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate korunuyor

## Açılış Kuralı

Pilot tenant açılışı PASS sayılırsa:

- opening_status = READY olmalıdır.
- pilot_data_boundary_status = PASS olmalıdır.
- tenant_acceptance_status = PASS olmalıdır.
- onboarding_smoke_status = PASS olmalıdır.
- critical_issue_count = 0 olmalıdır.
- Bütün required opening stage kayıtları PASS olmalıdır.
- Her required opening stage için evidence_ref dolu olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Pilot tenant açılış akışı dokümanı vardır.
- Config artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Required opening stage evidence guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
