# Pix2pi FAZ 5 Master Plan

## Faz kimliği

FAZ_NO=5
FAZ_NAME=Commercial Operations / Business Readiness
FAZ_TITLE=Ticari operasyon ve dış dünya yüzü
FAZ_PREVIOUS=FAZ 4D
FAZ_PREVIOUS_STATUS=PASS
FAZ_PREVIOUS_SEAL_STATUS=SEALED
FAZ_5_MASTER_PLAN_STATUS=PASS
FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED
FAZ_5_1_READY=YES

---

## FAZ 5 amacı

FAZ 5'in amacı Pix2pi'yi teknik olarak çalışan pilot üründen, ticari olarak satılabilir, paketlenebilir, faturalandırılabilir, desteklenebilir ve yönetilebilir SaaS ürüne çevirmektir.

Bu fazda ürünün ana ticari omurgası dondurulur:

- Paketler ve fiyatlama
- Modül / hak matrisi
- Abonelik ve tahsilat operasyonu
- Tenant ticari yaşam döngüsü
- Hukuki / uyum seti
- Destek / SLA / incident operasyonu
- Satış / demo / CRM süreci
- Gelir metrikleri
- Public ürün yüzeyi
- Developer / API yüzeyi
- Ticari readiness testleri
- Final commercial closure

---

## FAZ 5 uygulama kuralı

Her adımda şu kurallar zorunludur:

1. Önce mevcut dosya yedeği alınır.
2. Dosya değişikliği cat <<'EOF' ile tam dosya olarak yapılır.
3. Her adımın test scripti yazılır.
4. Test çıktısı OK ✅ veya HATA ❌ üretir.
5. Test geçmeden sonraki adıma geçilmez.
6. Her adım sonunda mühür alanları belgeye yazılır.
7. Kod/alan adlarında Türkçe özel karakter kullanılmaz.
8. Kullanıcıya her kritik adımda Not / Sonuç ve Evet / Hata alanı bırakılır.

---

## FAZ 5 master adım listesi

### 5-0 — FAZ 5 Master Plan / Seal

Amaç:
- FAZ 5 ana kapsamını sabitlemek
- FAZ 5 yürütme kurallarını yazmak
- 5-1 adımına geçiş izni üretmek

Çıkış mührü:
- FAZ_5_MASTER_PLAN_STATUS=PASS
- FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED
- FAZ_5_1_READY=YES

---

### 5-1 — Commercial Master Plan / Scope Freeze

Amaç:
- Ticari kapsamı dondurmak
- FAZ 5 içinde ne yapılacak / ne yapılmayacak ayrımını yapmak
- Paket, fiyatlama, abonelik, tenant lifecycle, destek, hukuk ve public yüzey bağımlılıklarını sabitlemek

Çıkış mührü:
- FAZ_5_1_SCOPE_FREEZE_STATUS=PASS
- FAZ_5_2_READY=YES

---

### 5-2 — Packages / Pricing Architecture

Alt kapsam:
- Starter paket
- Pro paket
- Enterprise paket
- Muhasebeci paketi
- Demo / free kullanım sınırı
- Aylık / yıllık fiyat mantığı
- Kullanıcı / tenant / şube / modül bazlı fiyatlama
- Modül bazlı upsell

Çıkış:
- Paket mimarisi hazır
- Fiyat tablosu ilk versiyon hazır
- Fiyat doğrulama testi hazır

---

### 5-3 — Entitlement Matrix / Module Rights

Alt kapsam:
- Hangi pakette hangi modül açık
- Kullanıcı hakkı
- Tenant hakkı
- Şube hakkı
- API hakkı
- Export hakkı
- Muhasebeci portal hakkı
- Marketplace / entegrasyon hakkı
- Paket değişiminde hak geçiş kuralları

Çıkış:
- Entitlement matrix hazır
- Paket-hak tutarlılık testi hazır

---

### 5-4 — Subscription / Billing / Payment Ops

Alt kapsam:
- Abonelik lifecycle
- Faturalama akışı
- Tahsilat akışı
- Başarısız ödeme akışı
- Askıya alma
- Yeniden açma
- İade / iptal ticari akışı
- Subscription ops testleri

Çıkış:
- Subscription operasyon sözleşmesi hazır
- Tahsilat ve askıya alma kararları hazır

---

### 5-5 — Tenant Lifecycle / Commercial Ops

Alt kapsam:
- Tenant açılışı
- Tenant upgrade
- Tenant downgrade
- Tenant freeze
- Tenant close
- Tenant data export
- Tenant devir akışı
- Tenant lifecycle testleri

Çıkış:
- Ticari tenant lifecycle dokümanı hazır
- Paket değişimi ve tenant durumu standardı hazır

---

### 5-6 — Legal / Compliance / KVKK / Terms

Alt kapsam:
- Kullanım şartları
- Gizlilik / KVKK metinleri
- Veri saklama / imha politikası
- Ticari sözleşme seti
- Muhasebeci portal sözleşme notları
- Public site yasal link haritası
- Uyum doküman kontrolü

Çıkış:
- Hukuki / uyum checklist hazır
- Eksik profesyonel hukuk incelemesi işaretli

---

### 5-7 — Support / SLA / Incident / Escalation

Alt kapsam:
- Destek kanalları
- SLA seviyeleri
- Incident sınıflandırma
- Escalation matrisi
- Müşteri iletişim şablonları
- İlk destek triage akışı
- Support ops testleri

Çıkış:
- Destek operasyon planı hazır
- SLA / incident sınıfları hazır

---

### 5-8 — Sales / Demo / CRM Operations

Alt kapsam:
- Demo tenant akışı
- CRM stage yönetimi
- Teklif akışı
- Satış kapanış akışı
- Pilot sonrası müşteriye dönüş akışı
- Sales ops raporu

Çıkış:
- Satış operasyon planı hazır
- Demo / teklif akışı hazır

---

### 5-9 — Revenue Metrics / MRR / ARR / Churn

Alt kapsam:
- MRR
- ARR
- Churn
- Expansion
- Paket dağılımı
- Tahsilat başarı oranı
- İç finans dashboard kararları

Çıkış:
- Gelir metrik sözleşmesi hazır
- Raporlama veri ihtiyaçları hazır

---

### 5-10 — Public / Pricing / Developer Surfaces

Alt kapsam:
- Landing / ürün sitesi
- Fiyatlama sayfası
- Paket karşılaştırma sayfası
- Developer docs portalı
- API key yönetim ekranı
- Sandbox kullanım yüzeyi
- Public/developer web testleri

Çıkış:
- Public yüzey scope hazır
- Developer yüzey scope hazır

---

### 5-11 — Commercial Readiness Test Suite

Alt kapsam:
- Paket testi
- Entitlement testi
- Subscription testi
- Tenant lifecycle testi
- Support readiness testi
- Legal checklist testi
- Public/pricing surface testi
- Commercial readiness test runner

Çıkış:
- FAZ 5 ticari test suite hazır

---

### 5-12 — FAZ 5 Final Closure / Seal

Alt kapsam:
- Tüm 5-x mühürlerinin kontrolü
- Commercial blocker kontrolü
- Legal open issue kontrolü
- Pricing readiness kontrolü
- Support readiness kontrolü
- Subscription readiness kontrolü
- Final Go / No-Go
- FAZ 5 final seal

Çıkış mührü:
- FAZ_5_FINAL_STATUS=PASS
- FAZ_5_FINAL_SEAL_STATUS=SEALED
- FAZ_6_READY=YES

---

## FAZ 5 dış kapsam

FAZ 5 içinde aşağıdakiler ana geliştirme olarak yapılmaz; sadece ticari karar veya yüzey hazırlığı yapılır:

- HA / multi-node / SRE final mimarisi
- Sharding / partition final uygulaması
- Multi-region
- DR final drill
- Büyük ölçek performans tuning
- Native mobil uygulama
- Tam marketplace runtime
- Tam ödeme kuruluşu canlı entegrasyonu
- Tam e-Belge provider canlı entegrasyonu

Bu işler FAZ 6 veya sonrası için bırakılır.

---

## FAZ 5 başarı kriterleri

FAZ 5 başarılı sayılması için:

- Paket mimarisi net olmalı
- Fiyatlama ilk ticari versiyon olarak sabitlenmeli
- Entitlement matrix hazır olmalı
- Subscription / tahsilat operasyon akışı yazılmalı
- Tenant lifecycle ticari olarak tanımlanmalı
- Hukuki / uyum checklist hazır olmalı
- Support / SLA / incident akışı hazır olmalı
- Satış / demo / CRM akışı hazır olmalı
- MRR / ARR / churn metrikleri tanımlanmalı
- Public / pricing / developer yüzey kapsamı hazır olmalı
- Commercial readiness test suite geçmeli
- Final closure PASS olmalı

---

## 5-0 mühür

FAZ_5_MASTER_PLAN_TEST_STATUS=PASS
FAZ_5_MASTER_PLAN_STATUS=PASS
FAZ_5_MASTER_PLAN_SEAL_STATUS=SEALED
FAZ_5_1_READY=YES
