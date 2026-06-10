# 157 — FAZ 3-11.8 — e-Belge Operasyon Ekranı

## Amaç

e-Fatura, e-Arşiv ve e-Adisyon operasyonlarını tek ekranda izlemek ve yönetmek için ERP web yüzeyi sağlar.

## Kapsam

- e-Fatura operasyon kuyruğu
- e-Arşiv operasyon kuyruğu
- e-Adisyon operasyon kuyruğu
- Callback / poll durum görünümü
- Retry / resend aksiyon yüzeyi
- Cancel aksiyon yüzeyi
- DLQ görünümü
- Manuel inceleme görünümü
- Provider hata görünümü
- UBL / PDF artifact görünümü
- Tenant / correlation / request / idempotency izleri
- Audit timeline
- Real provider gate closed politikası

## Canlı Politika

Bu ekran gerçek GİB veya özel entegratör çağrısı yapmaz.

Real provider gate CLOSED kalır. Production approved FALSE kalır. Gerçek provider entegrasyonu provider-live modülü ve ticari/onay süreçleri tamamlandıktan sonra açılacaktır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- e-Fatura / e-Arşiv / e-Adisyon görünür
- Status / callback / poll / retry / cancel / resend / DLQ / manual review yüzeyleri var
- Tenant / correlation / idempotency / provider / artifact / audit hash izleri var
- Real provider gate CLOSED
- Production approved FALSE
- Real external provider calls allowed FALSE
- Audit PASS
