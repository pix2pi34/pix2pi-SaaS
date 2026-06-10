# FAZ 4D — Channel / Marketplace Integrations

## Faz karari

FAZ 4D, FAZ 4C gercek pilot runtime completion tamamlandiktan sonra ele alinacak pazaryeri ve satis kanali entegrasyon fazidir.

Bu faz FAZ 5 degildir.
FAZ 5 ayri ana faz olarak korunur.

---

## 1. Faz amaci

FAZ 4D'nin amaci Pix2pi sistemini dis satis kanallarina hazir hale getirmektir.

Bu fazda pazaryeri siparisleri, stok senkronu, fiyat senkronu, iade akislari ve tenant bazli entegrasyon izolasyonu tasarlanir ve uygulanir.

---

## 2. Kapsam

FAZ 4D kapsaminda ele alinacak ana basliklar:

1. External sales channel model
2. Marketplace credential vault
3. Tenant bazli entegrasyon izolasyonu
4. Product listing mapping
5. Stock sync
6. Price sync
7. Order import
8. Return / cancellation flow
9. Cargo status flow
10. Marketplace commission accounting
11. Marketplace webhook engine
12. Marketplace error queue
13. Marketplace retry / replay
14. Marketplace monitoring
15. Channel-based reporting

---

## 3. Ilk hedef pazaryerleri

Ilk degerlendirme listesi:

1. Trendyol
2. Hepsiburada
3. N11
4. Amazon
5. Kendi web sitesi / ozel kanal

Not:
Ilk entegrasyon sirasi FAZ 4D basinda pilot isletmenin gercek kullanimina gore belirlenecek.

---

## 4. FAZ 4C ile iliski

FAZ 4C icinde pazaryeri canli entegrasyonu yapilmayacak.

FAZ 4C sadece su bilgileri toplar:

1. Pilot isletme pazaryeri kullaniyor mu?
2. Hangi pazaryerlerini kullaniyor?
3. Stok/fiyat/siparis manuel mi takip ediliyor?
4. Pazaryeri siparisleri muhasebeye nasil isleniyor?
5. Iade ve kargo surecleri nasil takip ediliyor?

---

## 5. Baslama kosulu

FAZ 4D baslamadan once asagidakiler tamamlanmis olmalidir:

- FAZ_4C_FINAL_CLOSURE_STATUS=PASS
- Pilot tenant calisiyor olmali
- Gercek urun/stok/cari/satis akisi dogrulanmis olmali
- UAT sonucu alinmis olmali
- Bug/blocker kritik liste kapanmis olmali
- Tenant isolation final pilot check gecmis olmali

---

## 6. Status

FUTURE_MARKETPLACE_PHASE=FAZ_4D_CHANNEL_MARKETPLACE_INTEGRATIONS
FAZ_4D_MARKETPLACE_STATUS=PLANNED
FAZ_4D_START_CONDITION=AFTER_4C_FINAL_CLOSURE
FAZ_4D_CAN_START_NOW=NO
