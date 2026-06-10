# FAZ 4C — 4C-6C UAT Acceptance Criteria

## Amaç

uzmanparcaci gerçek UAT testlerinde PASS / CONDITIONAL_PASS / FAIL kararını standartlaştırmak.

Bu dosya DB'ye yazmaz.

---

## 1. UAT sonucu karar tipleri

| Sonuç | Anlam |
|------|-------|
| PASS | Kritik blocker yok, işletme kabulü var |
| CONDITIONAL_PASS | Kritik blocker yok, küçük eksikler not edildi |
| FAIL | Kritik blocker var veya işletme kabulü yok |

---

## 2. Critical blocker sayılacak durumlar

Aşağıdaki durumlardan biri varsa UAT FAIL olur:

- Tenant erişimi yok
- Kullanıcı/rol tenant ile eşleşmiyor
- Pilot kullanıcı yanlış tenant verisi görüyor
- Staging ürün verisi görünmüyor
- Sample ürün sayısı 5 değil
- Duplicate SKU var
- Tenant mismatch var
- OEM kodları görünmüyor
- Eşdeğer kodlar görünmüyor
- Araç uyum notları görünmüyor
- Sistem UAT sırasında çalışmıyor
- İşletme “kabul etmiyorum” diyor

---

## 3. Blocker olmayan bilinçli uyarılar

Aşağıdaki durumlar UAT blocker değildir:

- Barkod alanlarının boş olması
- ERP core product apply yapılmamış olması
- Pazaryeri canlı entegrasyon olmaması
- Paraşüt canlı senkron olmaması
- Şifre reset/davet kapısının canlı giriş öncesi beklemesi
- TECDOC benzeri tam araç-parça motorunun bu fazda olmaması

---

## 4. Minimum PASS kriterleri

UAT PASS için:

- UAT-01 Tenant erişimi PASS
- UAT-02 Kullanıcı/rol erişimi PASS
- UAT-03 Staging tablo PASS
- UAT-04 Sample ürün sayısı PASS
- UAT-05 Duplicate SKU PASS
- UAT-06 Tenant mismatch PASS
- UAT-07 OEM kod PASS
- UAT-08 Eşdeğer kod PASS
- UAT-09 Araç uyum notu PASS
- UAT-10 Barkod kararı PASS veya WARNING
- UAT-11 Pazaryeri scope guard PASS
- UAT-12 Kullanıcı kabulü PASS veya CONDITIONAL_PASS
- UAT-13 Bug/blocker kaydı PASS
- UAT-14 Go/No-Go hazırlığı PASS veya CONDITIONAL_PASS

---

## 5. Final status

4C_6C_ACCEPTANCE_CRITERIA_STATUS=PASS
4C_6C_CRITICAL_BLOCKER_RULES_DEFINED=YES
4C_6C_NON_BLOCKING_WARNINGS_DEFINED=YES
4C_6C_PASS_RULE_DEFINED=YES
