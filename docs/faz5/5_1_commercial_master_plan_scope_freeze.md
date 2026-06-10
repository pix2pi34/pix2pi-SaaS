# FAZ 5-1 — Commercial Master Plan / Scope Freeze

## Adım kimliği

FAZ_NO=5
STEP_NO=5-1
STEP_NAME=Commercial Master Plan / Scope Freeze
STEP_TITLE=Ticari ana plan / kapsam dondurma
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_1_SCOPE_FREEZE_STATUS=PASS
FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED
FAZ_5_2_READY=YES

---

## Giriş şartları

Bu adımın başlayabilmesi için:

- FAZ_4D_FINAL_STATUS=PASS olmalı
- FAZ_4D_FINAL_SEAL_STATUS=SEALED olmalı
- FAZ_5_READY=YES olmalı
- FAZ_5_MASTER_PLAN_STATUS=PASS olmalı
- FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED olmalı
- FAZ_5_1_READY=YES olmalı

Karar:
- Giriş şartları kabul edildi.
- FAZ 5 ticari kapsam dondurma çalışması başlatıldı.

---

## 5-1 amacı

Bu adımın amacı FAZ 5 içinde yapılacak ticari işleri netleştirmek, kapsam dışına atılacak işleri ayırmak ve sonraki 5-2 paket/fiyatlama adımına temiz geçiş sağlamaktır.

---

## FAZ 5 ticari ana kararları

### Karar 1 — FAZ 5 teknik büyütme fazı değildir

FAZ 5'in ana hedefi teknik altyapıyı büyütmek değil, mevcut pilot ürünü satılabilir ve yönetilebilir ticari ürüne çevirmektir.

Bu yüzden HA, multi-region, sharding, DR final drill gibi başlıklar FAZ 6'ya bırakılır.

Durum:
- ACCEPTED

---

### Karar 2 — Paketleme önce gelir

Paket/fiyatlama ve entitlement matrix tamamlanmadan abonelik, tahsilat ve public pricing yüzeyi yazılmaz.

Bağımlılık:
- 5-2 Packages / Pricing Architecture
- 5-3 Entitlement Matrix / Module Rights

Durum:
- ACCEPTED

---

### Karar 3 — Abonelik operasyonu entitlement üstüne kurulacak

Abonelik lifecycle, paket haklarını doğrudan takip edecek.

Örnek:
- Paket değişirse entitlement değişir.
- Ödeme başarısız olursa tenant durumu etkilenir.
- Tenant askıya alınırsa bazı modüller kapanır.
- Export / data handoff hakları ayrı yönetilir.

Durum:
- ACCEPTED

---

### Karar 4 — Muhasebeci paketi ayrı ticari ürün kabul edilir

Muhasebeci portalı klasik ERP kullanıcı paketinden ayrı düşünülür.

Muhasebeci paketi şunları içerebilir:
- Firma başı ücret
- Atanmış firma limiti
- Export hakkı
- Excel / PDF / TDHP çıktı hakkı
- Muhasebeci workspace hakkı

Durum:
- ACCEPTED

---

### Karar 5 — Demo tenant kontrollü olacak

Demo tenant sınırsız ürün kullanımı sağlamaz.

Demo tenant sınırları:
- Süre sınırı
- Kullanıcı sınırı
- Test veri sınırı
- Export sınırı
- API sınırı
- Canlı finansal işlem kapalı veya kontrollü

Durum:
- ACCEPTED

---

### Karar 6 — Hukuki belgeler teknik yayın öncesi checklist olarak tutulacak

Bu fazda profesyonel hukuk onayı yerine teknik / ticari checklist hazırlanır.

Hukuk uzmanı incelemesi ayrı açık iş olarak işaretlenir.

Durum:
- ACCEPTED

---

### Karar 7 — Support / SLA ticari pakete bağlı olacak

Her paket aynı destek seviyesine sahip olmayacak.

Örnek sınıflar:
- Starter: standart destek
- Pro: öncelikli destek
- Enterprise: SLA ve özel destek
- Muhasebeci: firma bazlı operasyon desteği

Durum:
- ACCEPTED

---

### Karar 8 — Public yüzey commercial kararlar bitmeden yazılmaz

Landing, fiyatlama sayfası ve developer yüzeyi 5-2, 5-3, 5-4 kararlarından sonra yazılır.

Durum:
- ACCEPTED

---

## FAZ 5 kapsam içi işler

### 1. Paketler

Kapsam:
- Starter
- Pro
- Enterprise
- Muhasebeci
- Demo / free kullanım

Durum:
- IN_SCOPE

---

### 2. Fiyatlama

Kapsam:
- Aylık fiyat
- Yıllık fiyat
- Kullanıcı bazlı fiyat
- Tenant / firma bazlı fiyat
- Şube bazlı fiyat
- Modül bazlı upsell
- Export / API / muhasebeci portal hakkı

Durum:
- IN_SCOPE

---

### 3. Entitlement matrix

Kapsam:
- Modül erişimi
- Kullanıcı limiti
- Tenant limiti
- Şube limiti
- API limiti
- Export limiti
- Raporlama limiti
- Marketplace / entegrasyon hakkı
- Muhasebeci portal hakkı

Durum:
- IN_SCOPE

---

### 4. Subscription / billing ops

Kapsam:
- Abonelik başlatma
- Plan değiştirme
- Yenileme
- Başarısız ödeme
- Askıya alma
- Yeniden açma
- İptal / iade iş akışı

Durum:
- IN_SCOPE

---

### 5. Tenant commercial lifecycle

Kapsam:
- Tenant açılışı
- Tenant upgrade
- Tenant downgrade
- Tenant freeze
- Tenant close
- Data export
- Data handoff

Durum:
- IN_SCOPE

---

### 6. Hukuki / uyum checklist

Kapsam:
- Kullanım şartları
- Gizlilik / KVKK
- Veri saklama
- Veri imha
- Ticari sözleşme notları
- Public legal link map

Durum:
- IN_SCOPE

---

### 7. Support / SLA / incident

Kapsam:
- Destek kanalı
- SLA seviye ayrımı
- Incident sınıfları
- Escalation matrisi
- Müşteri mesaj şablonları
- Support readiness testi

Durum:
- IN_SCOPE

---

### 8. Sales / demo / CRM

Kapsam:
- Demo tenant akışı
- Lead stage
- Teklif akışı
- Satış kapanışı
- Pilot sonrası dönüşüm
- Sales ops raporu

Durum:
- IN_SCOPE

---

### 9. Gelir metrikleri

Kapsam:
- MRR
- ARR
- Churn
- Expansion
- Paket dağılımı
- Tahsilat başarı oranı

Durum:
- IN_SCOPE

---

### 10. Public / developer yüzeyleri

Kapsam:
- Landing
- Fiyatlama sayfası
- Paket karşılaştırma
- Developer docs
- API key yönetim yüzeyi
- Sandbox kullanım yüzeyi

Durum:
- IN_SCOPE

---

## FAZ 5 kapsam dışı işler

Aşağıdaki işler FAZ 5 içinde ana uygulama olarak yapılmayacak:

- Multi-node production cluster
- Kubernetes veya orchestrator geçişi
- Multi-region
- DR final drill
- Sharding uygulaması
- Native Android / iOS
- Tam marketplace runtime
- Tam ödeme kuruluşu canlı entegrasyonu
- Tam e-Belge provider canlı entegrasyonu
- Yeni büyük ERP modülü
- Büyük refactor

Durum:
- OUT_OF_SCOPE

---

## FAZ 5 bağımlılık sırası

1. 5-1 Scope Freeze
2. 5-2 Packages / Pricing
3. 5-3 Entitlement Matrix
4. 5-4 Subscription / Billing Ops
5. 5-5 Tenant Lifecycle
6. 5-6 Legal / Compliance
7. 5-7 Support / SLA
8. 5-8 Sales / Demo / CRM
9. 5-9 Revenue Metrics
10. 5-10 Public / Developer Surfaces
11. 5-11 Commercial Readiness Test Suite
12. 5-12 Final Closure / Seal

---

## Riskler

### Risk 1 — Fiyat erken yazılırsa yanlış konumlanma olur

Önlem:
- Önce paket hakları çıkarılacak.
- Sonra fiyat konuşulacak.

Durum:
- CONTROLLED

---

### Risk 2 — Entitlement yoksa abonelik sağlıklı çalışmaz

Önlem:
- 5-3 bitmeden 5-4'e geçilmeyecek.

Durum:
- CONTROLLED

---

### Risk 3 — Hukuki metinler gecikirse public çıkış gecikir

Önlem:
- 5-6 içinde teknik checklist hazırlanacak.
- Profesyonel hukuk incelemesi açık iş olarak işaretlenecek.

Durum:
- CONTROLLED

---

### Risk 4 — Destek operasyonu olmadan satış başlarsa müşteri memnuniyeti düşer

Önlem:
- 5-7 support readiness geçmeden final closure yapılmayacak.

Durum:
- CONTROLLED

---

## 5-1 çıkış kriterleri

Bu adım PASS sayılmak için:

- Ticari kapsam içi işler yazılmış olmalı
- Kapsam dışı işler yazılmış olmalı
- Paketleme önce gelir kararı yazılmış olmalı
- Entitlement bağımlılığı yazılmış olmalı
- Abonelik bağımlılığı yazılmış olmalı
- Muhasebeci paketi ayrı kabul edilmiş olmalı
- Public yüzeylerin sonra yazılacağı belirtilmiş olmalı
- 5-2 geçiş izni verilmiş olmalı

---

## 5-1 mühür

FAZ_5_1_TEST_STATUS=PASS
FAZ_5_1_SCOPE_FREEZE_STATUS=PASS
FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED
FAZ_5_2_READY=YES
