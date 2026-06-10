# 115 — FAZ 3-10.3.6 — e-Belge canlı entegrasyon testleri

## Amaç

Bu adım, e-Fatura / e-Arşiv / e-Adisyon provider ailesinin canlı entegrasyona hazır olup olmadığını test eder.

## Önemli Politika

Bu faz gerçek GİB veya özel entegratör çağrısı yapmaz.

Canlı entegrasyon için:

- real provider gate kapalı
- production approved false
- credential ref only
- raw secret yasak
- simulation/live-gate readiness testleri yapılır

## Kapsam

- e-Fatura send/status/cancel/download UBL readiness
- e-Arşiv send/status/cancel/download PDF/UBL readiness
- e-Adisyon send/status/cancel/download PDF/UBL readiness
- Callback signature guard
- Poll readiness
- Retry readiness
- DLQ readiness
- Manual review readiness
- Live provider gate guard
- Credential ref only guard
- Raw secret policy guard

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- e-Fatura / e-Arşiv / e-Adisyon readiness testleri PASS
- Callback / poll / retry / DLQ / manual review testleri PASS
- Live provider gate kapalı kalır
