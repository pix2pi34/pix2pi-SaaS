# FAZ 7-R / 319 + 347 Onboarding Tenant Opening Real Audit

Generated at: 20260512_192453

## Result

- PASS_COUNT=39
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- GO_TEST_STATUS=PASS
- SMOKE_STATUS=PASS
- FINAL_STATUS=PASS

## Covered items

- 319.1 İşletme adı
- 319.2 Vergi / TCKN bilgisi
- 319.3 Adres
- 319.4 Sektör seçimi
- 319.5 Şube bilgisi
- 319.6 Varsayılan para birimi
- 319.7 Varsayılan dil
- 319.8 İlk kullanıcı rolü
- 319.9 Onboarding tamamlandı işareti
- 347.1 Pilot tenant config
- 347.2 Varsayılan dil tr-TR
- 347.3 Varsayılan paket
- 347.4 Şube / kasa başlangıç setup
- 347.5 Tenant opening smoke test

## Files

- /root/pix2pi/pix2pi-SaaS/configs/faz7r/faz7r_319_347_onboarding_tenant_opening_real.json
- /root/pix2pi/pix2pi-SaaS/db/migrations/20260511_319_347_onboarding_tenant_opening_real.sql
- /root/pix2pi/pix2pi-SaaS/internal/faz7r/onboarding/tenantopening/tenant_opening.go
- /root/pix2pi/pix2pi-SaaS/internal/faz7r/onboarding/tenantopening/tenant_opening_test.go
- /var/www/pix2pi/panel/onboarding/index.html
- /var/www/pix2pi/panel/onboarding/onboarding-runtime.js

## Check log

```
319/347 backup directory prepared IMPLEMENTED_OR_PRESENT / OK ✅
319/347 package directories prepared IMPLEMENTED_OR_PRESENT / OK ✅
319/347 config file written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 migration file written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 runtime files written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 tests written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 live onboarding HTML written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 live onboarding JS written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 standalone audit script written IMPLEMENTED_OR_PRESENT / OK ✅
319/347 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
319 business onboarding table migration exists IMPLEMENTED_OR_PRESENT / OK ✅
347 tenant config table migration exists IMPLEMENTED_OR_PRESENT / OK ✅
319 service complete onboarding function exists IMPLEMENTED_OR_PRESENT / OK ✅
347 service open pilot tenant function exists IMPLEMENTED_OR_PRESENT / OK ✅
319/347 real DB repository constructor exists IMPLEMENTED_OR_PRESENT / OK ✅
319.1-319.9 onboarding test exists IMPLEMENTED_OR_PRESENT / OK ✅
347.1-347.5 tenant opening test exists IMPLEMENTED_OR_PRESENT / OK ✅
319/347 end-to-end flow test exists IMPLEMENTED_OR_PRESENT / OK ✅
319/347 live onboarding screen marker exists IMPLEMENTED_OR_PRESENT / OK ✅
319/347 live onboarding runtime marker exists IMPLEMENTED_OR_PRESENT / OK ✅
319/347 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
319/347 go test tenantopening status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
319/347 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
319/347 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
319/347 panel onboarding smoke status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
319.1 İşletme adı real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.2 Vergi / TCKN real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.3 Adres real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.4 Sektör real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.5 Şube bilgisi real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.6 Varsayılan para birimi real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.7 Varsayılan dil real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.8 İlk kullanıcı rolü real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
319.9 Onboarding tamamlandı işareti real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
347.1 Pilot tenant config real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
347.2 Varsayılan dil tr-TR validation contract IMPLEMENTED_OR_PRESENT / OK ✅
347.3 Varsayılan paket real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
347.4 Şube / kasa başlangıç setup real DB write contract IMPLEMENTED_OR_PRESENT / OK ✅
347.5 Tenant opening smoke test contract IMPLEMENTED_OR_PRESENT / OK ✅
```
