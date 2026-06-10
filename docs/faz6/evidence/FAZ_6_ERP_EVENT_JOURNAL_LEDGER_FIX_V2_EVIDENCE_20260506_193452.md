===== 6-FIX-V2 BACKUP START =====
backup copied: internal/erp/core/cari/service/erp_cari_hesap_service.go / OK ✅
backup copied: internal/erp/core/alis/service/erp_alis_fatura_service.go / OK ✅
backup copied: internal/erp/core/satis/service/erp_satis_fatura_service.go / OK ✅
backup copied: internal/erp/core/tahsilat/service/erp_tahsilat_service.go / OK ✅
backup copied: internal/erp/core/rapor/service/erp_mizan_service.go / OK ✅
backup copied: internal/erp/runtime/e2eflow/e2e_flow_db_integration_test.go / OK ✅
backup copied: internal/platform/journal/journal_builder_test.go / OK ✅
===== 6-FIX-V2 PATCH START =====
cari service domain import and compatibility wrappers patched / OK ✅
===== 6-FIX-V2 GOFMT =====
gofmt completed / OK ✅
[H[2J[3J===== 6-FIX-V2 TARGETED TESTS =====
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service	[no test files]
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service
internal/erp/core/alis/service/erp_alis_fatura_service.go:129:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service
internal/erp/core/satis/service/erp_satis_fatura_service.go:111:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:72:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:163:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service
internal/erp/core/rapor/service/erp_mizan_service.go:34:55: too many arguments in call to s.cariHesapService.HareketleriListele
	have (string)
	want ()
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service [build failed]
FAIL
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow	(cached)
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/journal	(cached)
===== 6-FIX-V2 TARGETED TEST STATUS =====
STATUS_CARI=0
STATUS_ALIS=1
STATUS_SATIS=1
STATUS_TAHSILAT=1
STATUS_RAPOR=1
STATUS_E2E=0
STATUS_JOURNAL=0
cari service test / OK ✅
alis service test / FAIL ❌
satis service test / FAIL ❌
tahsilat service test / FAIL ❌
rapor service test / FAIL ❌
e2eflow test / OK ✅
platform journal test / OK ✅
===== 6-FIX-V2 TARGETED FINAL STATUS =====
PASS_COUNT=12
FAIL_COUNT=4
EVIDENCE_FILE=docs/faz6/evidence/FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FIX_V2_EVIDENCE_20260506_193452.md
FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FIX_V2_STATUS=FAIL
READY_TO_RERUN_FAZ_6_FINAL_AUDIT=NO
