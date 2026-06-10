# 193 — FAZ 4-16.1.5 Tenant Acceptance Checklist

## Amaç

Pilot tenant açılmadan / UAT akışına alınmadan önce tenant kabul kriterlerini checklist olarak netleştirir.

Bu adım 192 — Pilot veri sınırları tanımından sonra gelir ve tenant'ın kontrollü pilot için kabul edilebilir durumda olup olmadığını doğrular.

## Checklist Kapsamı

Tenant acceptance checklist aşağıdaki kapıları kontrol eder:

- Tenant kimliği hazır
- Tenant izolasyon stratejisi seçili
- Tenant config hazır
- Tenant admin kullanıcı hazır
- Kullanıcı / rol ilk kurulumuna hazır
- Pilot veri sınırları PASS
- Import sınırları PASS
- UAT kapsamı tanımlı
- Support / issue kanalı tanımlı
- Rollback / cutover guard hazır
- Readmodel / reporting altyapısı hazır
- Kritik issue sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate korunuyor

## Kabul Kuralı

Tenant acceptance PASS sayılırsa:

- Bütün required checklist item'ları PASS olmalıdır.
- critical_issue_count = 0 olmalıdır.
- pilot_data_boundary_status = PASS olmalıdır.
- readmodel_reporting_status = PASS olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.
- Her required item için evidence_ref dolu olmalıdır.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Tenant acceptance checklist dokümanı vardır.
- Config artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Required evidence guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
