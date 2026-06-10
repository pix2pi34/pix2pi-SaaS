# FAZ 4C — 4C-3 Real Pilot Tenant Setup

## Blok

4C-3 — Real Pilot Tenant Setup

## Amaç

Bu blokta uzmanparcaci için gerçek pilot tenant kurulumu hazırlanacak ve kontrollü şekilde uygulanacak.

Bu adımın ilk parçası olan 4C-3A, tenant kimliğini dondurur.

Bu adımda DB apply yapılmaz.
Bu adımda servis restart yapılmaz.
Bu adımda sadece tenant setup planı hazırlanır.

---

## 1. Ön koşul

4C-2 Real Runtime Gap Completion kapanmış olmalıdır.

Beklenen önceki durum:

4C_2_FINAL_STATUS=PASS
4C_2_CRITICAL_BLOCKER_COUNT=0
4C_3_READY=YES

---

## 2. Seçilen pilot işletme

Pilot işletme:

- İşletme: uzmanparcaci
- Sektör: OTO YEDEK PARCA
- Yetkili: mert ömür
- İl: istanbul
- İlçe: bahçelievler
- Kullanıcı sayısı: 1
- Şube sayısı: 1
- Tahmini stok kalemi: 1000

---

## 3. Tenant kimlik kararı

Kod ve teknik alanlarda Türkçe özel karakter kullanılmayacaktır.

Tenant identity:

TENANT_DISPLAY_NAME=uzmanparcaci
TENANT_CODE=uzmanparcaci
TENANT_SLUG=uzmanparcaci
TENANT_SCHEMA=tenant_uzmanparcaci
TENANT_SECTOR=OTO_YEDEK_PARCA

---

## 4. Tenant kurulum stratejisi

İlk pilot için önerilen tenant stratejisi:

- Tenant gerçek pilot olarak işaretlenecek
- Test tenant olarak işaretlenmeyecek
- Canlı pazaryeri entegrasyonu açılmayacak
- e-Fatura/e-Arşiv zorunlu olmayacak
- Banka/sanal POS canlı entegrasyonu açılmayacak
- Önce tenant metadata hazırlanacak
- Sonra DB precheck yapılacak
- Sonra gerekiyorsa tenant kaydı ve schema apply adımı ayrı yapılacak

---

## 5. FAZ 4C tenant kapsamı

4C-3 içinde yapılacaklar:

1. Tenant identity freeze
2. DB tenant precheck
3. Mevcut tenant tablolarını bulma
4. Tenant kayıt stratejisini belirleme
5. Tenant schema var mı kontrol etme
6. Eksikse apply script hazırlama
7. Apply guard ile güvenli tenant kurulumu
8. Final tenant setup closure

---

## 6. 4C-3A status

4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS
4C_3A_TENANT_CODE=uzmanparcaci
4C_3A_TENANT_SCHEMA=tenant_uzmanparcaci
4C_3A_TENANT_SETUP_APPLY_STATUS=NOT_APPLIED
4C_3A_NEXT_STEP_READY=YES
4C_3B_READY=YES

---

## 7. Sonraki adım

Sonraki adım:

4C-3B — DB Tenant Precheck / Existing Tenant Discovery

Bu adımda DB'de tenant tablosu, tenant schema ve mevcut tenant kayıtları kontrol edilecek.
