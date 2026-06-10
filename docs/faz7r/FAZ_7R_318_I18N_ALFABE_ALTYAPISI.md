# FAZ 7-R / 318 — Dil Modülü / i18n / Alfabe Altyapısı

## FIX V2 — Ahmed Hüsrev Altınbaşak hattı referans standardı

Bu adım 318'i Osmanlıca ve Arapça yazı karakteri kararıyla günceller.

## Ana referans

- Hat referansı: Ahmed Hüsrev Altınbaşak hattı
- Direkt referans kaynağı: https://oku.risale.online/osm
- Kapsam: Osmanlıca Türkçesi / Arap harfli Türkçe (`ota`), Arapça (`ar`), gerektiğinde Farsça (`fa`)
- Kural: Osmanlıca ve Arapça yazı/hattı için başka stil referansı kullanılmaz; bu kaynak esas alınır.

## Kapsam

318.1 Dil modülü kurulumu  
318.2 Translation key standardı  
318.3 Her dil için ayrı dosya yapısı  
318.4 Varsayılan ana dil: Latin Türkçe / tr-TR  
318.5 Dil sırası  
318.5.1 Latin Türkçe — tr-TR  
318.5.2 Osmanlıca Türkçesi / Arap harfli Türkçe — ota  
318.5.3 Arapça — ar  
318.5.4 Farsça — fa  
318.5.5 İngilizce — en  
318.6 Dil dosya registry  
318.7 Tenant default language ayarı  
318.8 Kullanıcı dil tercihi  
318.9 Panel dil değiştirme butonu  
318.10 POS dil desteği  
318.11 Marketplace dil desteği  
318.12 Bildirim / e-posta / hata mesajı çeviri dosyaları  
318.13 Tarih / saat / sayı / para formatı  
318.14 RTL / LTR layout engine  
318.15 Font fallback standardı  
318.16 Dil fallback mekanizması  
318.17 Hardcoded UI text yasağı  
318.18 Translation completeness audit  
318.19 Localization smoke test  
318.20 RTL layout regression test  
318.21 Ahmed Hüsrev Altınbaşak hat referansı  
318.22 Osmanlıca/Arapça hat referans registry binding  
318.23 Hat referansı smoke/audit gate  

## Teknik karar

- `ota`, `ar`, `fa` için `calligraphy_reference` alanı registry'ye eklenir.
- Runtime içinde RTL font/hattı için `calligraphyReferenceOf(language)` fonksiyonu bulunur.
- Demo yüzeyinde hat referans marker'ı bulunur.
- Gerçek font dosyası sisteme gömülmez; yalnızca stil referans kontratı ve fallback standardı uygulanır.
