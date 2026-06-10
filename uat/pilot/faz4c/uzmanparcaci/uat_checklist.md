# uzmanparcaci — FAZ 4C UAT Checklist

## UAT bilgisi

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN
UAT_MODE=REAL_PILOT_UAT

---

## Checklist

| Test | Açıklama | Beklenen | Durum | Not |
|------|----------|----------|-------|-----|
| UAT-01 | Tenant erişimi | Tenant uzmanparcaci | PENDING | |
| UAT-02 | Kullanıcı/rol erişimi | PILOT_ADMIN | PENDING | |
| UAT-03 | Staging tablo | pilot_product_import_staging var | PENDING | |
| UAT-04 | Sample ürün sayısı | 5 ürün | PENDING | |
| UAT-05 | Duplicate SKU | 0 | PENDING | |
| UAT-06 | Tenant mismatch | 0 | PENDING | |
| UAT-07 | OEM kod | Görünür/doğru | PENDING | |
| UAT-08 | Eşdeğer kod | Görünür/doğru | PENDING | |
| UAT-09 | Araç uyum notu | Görünür/doğru | PENDING | |
| UAT-10 | Barkod boşluğu | Blocker değil | PENDING | |
| UAT-11 | Pazaryeri scope guard | FAZ 4D | PENDING | |
| UAT-12 | Kullanıcı kabulü | PASS/CONDITIONAL_PASS | PENDING | |
| UAT-13 | Bug/blocker kaydı | Varsa sınıflandırılır | PENDING | |
| UAT-14 | Go/No-Go hazırlığı | UAT sonucuna göre | PENDING | |

---

## UAT sonucu

UAT_RESULT=PENDING
CRITICAL_BLOCKER_COUNT=PENDING
BUSINESS_ACCEPTANCE_STATUS=PENDING
GO_NO_GO_READY=PENDING
