# 180 — FAZ 3-R Öncelik 3 Final Recheck / Seal

## Kapsam

Bu final recheck, FAZ 3-R Öncelik 3 kapsamındaki ERP web surface, muhasebeci portal ve belge/entegrasyon UI ekranlarının mühür durumunu toplu doğrular.

## Kontrol Edilen İşler

- 157 — FAZ 3-11.8 — e-Belge operasyon ekranı
- 158 — FAZ 3-11.6 — Reconciliation ekranı
- 159 — FAZ 3-11.5 — Vergi / KDV rule ekranı
- 160 — FAZ 3-11.3 — Journal / ledger ekranı
- 161 — FAZ 3-11.4 — TDHP mapping görüntüleme ve kontrol ekranı
- 162 — FAZ 3-11.9 — Ödeme / mutabakat ekranı
- 163 — FAZ 3-11.7 — Export center ekranı
- 164 — FAZ 3-11.2 — Finans özet ekranı
- 165 — FAZ 3-11.1 — Ana yönetim dashboard’u
- 166 — FAZ 3-11.10 — ERP UI testleri
- 167 — FAZ 3-12.4 — Excel / PDF / TDHP export workspace
- 168 — FAZ 3-12.1 — Çok firmalı workspace
- 169 — FAZ 3-12.2 — Firma değiştirici
- 170 — FAZ 3-12.3 — Firma bazlı yetki ekranı
- 171 — FAZ 3-12.5 — Abonelik / durum görünümü
- 172 — FAZ 3-12.6 — Portal audit / işlem geçmişi
- 173 — FAZ 3-12.7 — Muhasebeci portal testleri
- 174 — FAZ 3-13.1 — e-Belge durum merkezi
- 175 — FAZ 3-13.4 — OCR / belge okuma review ekranı
- 176 — FAZ 3-13.6 — Belge / entegrasyon UI testleri
- 177 — FAZ 3-13.2 — Retry / cancel / resend aksiyon yüzeyi
- 178 — FAZ 3-13.3 — Provider hata görünümü
- 179 — FAZ 3-13.5 — Manuel düzeltme kuyruğu

## Final Kapanış Kuralı

Öncelik 3 şu durumda PASS olur:

- 157–179 arası tüm evidence dosyaları bulunur
- Her evidence dosyasında PASS / SEALED izi bulunur
- Ana HTML ekran dosyaları bulunur
- Ana config dosyaları bulunur
- Canlı risk kapıları kapalıdır
- Final audit sayaçlarından `FAIL_COUNT=0` ve `REQUIRED_FAIL=0` türemiştir
