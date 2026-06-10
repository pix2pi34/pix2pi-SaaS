# FAZ 5-18.3.1 — Sözleşme Seti

## Faz Bilgisi

- Faz: FAZ 5-R — Commercial / Public Launch Final Closure
- İş No: 242
- İş: Sözleşme seti
- Durum: FIX uygulanmış taslak içerik hazır
- Core ürün kullanımı: Ayrı onaylı temel sözleşmeyle açılabilir
- Veri destekli ticari fayda modeli: Hukuk/KVKK onayına bağlı
- Hukukçu Onayı: Bekliyor
- KVKK Danışmanı Onayı: Bekliyor
- Public Publish Allowed: false

## Kritik Ayrım

Bu iş, Pix2pi Ticaret Operasyon Sistemi için public launch sözleşme ailesini kurar.

Bu belgeler şu anda DRAFT statüsündedir. Gerçek müşteriye resmi sözleşme/KVKK metni olarak sunulmadan önce hukukçu ve KVKK danışmanı kontrolünden geçmelidir.

Bu kapı core ERP/POS kullanımını değil, taslak metinlerin resmi müşteri onay akışına bağlanmasını ve veri destekli ticari fayda modelinin canlıya açılmasını kontrol eder.

## Pix2pi Ticaret Operasyon Sistemi Tanımı

Pix2pi Ticaret Operasyon Sistemi, işletmelerin satış, stok, POS, ERP, muhasebe, tedarik, fiyat karşılaştırma, ticari öneri, toplu satın alma, sponsorlu teklif, raporlama, entegrasyon ve veri tabanlı ticari fayda süreçlerini tek merkezden yönetmesini sağlayan dijital ticaret operasyon sistemidir.

Pix2pi yalnızca yazılım, ERP veya POS hizmeti sunan bir sistem değildir. Pix2pi aynı zamanda işletmelere veri tabanlı ticari fayda, tedarik optimizasyonu, toplu satın alma, fiyat karşılaştırma, sponsorlu teklif, pazar içgörüsü ve ticari fırsat sağlayan bir ticaret operasyon sistemidir.

## Müşteri / İşletme Tanımı

Müşteri veya İşletme; Pix2pi hizmetlerinden yararlanan gerçek veya tüzel kişi işletme, esnaf, tacir, şirket, şube, bayi, franchise, restoran, kafe, market, oto yedek parça işletmesi, hizmet işletmesi, e-ticaret işletmesi, muhasebeci ofisi, tedarikçi veya ticari kullanıcıyı ifade eder.

## Sözleşme Seti

1. Abonelik ve Hizmet Sözleşmesi
2. Kullanım Şartları
3. Gizlilik Politikası
4. KVKK Aydınlatma Metni
5. Açık Rıza Metni
6. Çerez Politikası
7. Veri İşleme Ek Protokolü
8. SLA / Destek Politikası
9. İptal / İade / Fesih Politikası
10. Muhasebeci Portalı Ek Şartları
11. Paket / Fiyat / Entitlement Ek Şartları
12. Ticari Fayda Programı Ek Şartları

## Veri Destekli Plan Kararı

Pix2pi’nin ücretsiz, indirimli veya avantajlı planları veri destekli hizmet modeliyle çalışabilir.

Veri destekli modeli kabul eden işletmeler:
- tedarik önerisi alabilir,
- fiyat karşılaştırma kullanabilir,
- toplu satın alma havuzuna katılabilir,
- sponsorlu teklifleri görebilir,
- anonim/toplulaştırılmış pazar içgörüsü modeline dahil olabilir,
- Pix2pi ticari fayda programından yararlanabilir.

Veri destekli modeli kabul etmeyen işletmeler:
- ücretsiz/indirimli modelden yararlanamayabilir,
- veri kullanımı kısıtlı ücretli plana geçebilir,
- modül bazlı ücretli kullanım seçebilir,
- enterprise gizlilik kontrollü plana geçebilir,
- tedarik/reklam/veri destekli özellikleri sınırlandırılmış şekilde kullanabilir.

## Core Product / Data Monetization Gate

Core ürün ile veri monetizasyonu ayrı kapılardır.

- PUBLIC_CORE_PRODUCT_ALLOWED: true
- PUBLIC_CONTRACT_DRAFT_ALLOWED: false
- DATA_MONETIZATION_PUBLIC_ALLOWED: false
- LEGAL_KVKK_APPROVAL_REQUIRED_FOR_DATA_MODEL: true

## Yazılımın Otomatik Görmesi Gereken Kararlar

Sistem, tenant bazında şu kararları runtime olarak tutmalıdır:

- DATA_SUPPORTED_PLAN_ACCEPTED
- COMMERCIAL_BENEFIT_PROGRAM_ACCEPTED
- RESTRICTED_PAID_PLAN_SELECTED
- EXPLICIT_CONSENT_VERSION
- CONTRACT_VERSION
- ACCEPTED_AT
- ACCEPTED_BY
- IP_ADDRESS
- TENANT_ID
- FEATURE_GATE_STATUS

Bu kararlar Entitlement Runtime, Plan/Pricing Engine, Feature Gate Middleware, Data Pipeline Guard, Sponsored Offer Guard ve Procurement Recommendation Guard tarafından okunmalıdır.

## Yayın Kuralı

Aşağıdaki statüler APPROVED olmadan bu metinler public production müşteri onay akışına bağlanmaz:

- LEGAL_APPROVAL_STATUS
- KVKK_APPROVAL_STATUS

## Final Hedef

Bu işin amacı sözleşme setini enterprise seviyede sürümlü, audit edilebilir, onay kapılı, veri destekli gelir modelini koruyan ve modül bazlı ücretli alternatifleri destekleyen hale getirmektir.
