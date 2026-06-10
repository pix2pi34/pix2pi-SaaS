===== 6-FIX-V1 BACKUP START =====
backup copied: internal/erp/core/alis/service/erp_alis_fatura_service.go / OK ✅
backup copied: internal/erp/core/satis/service/erp_satis_fatura_service.go / OK ✅
backup copied: internal/erp/core/tahsilat/service/erp_tahsilat_service.go / OK ✅
backup copied: internal/erp/core/cari/service/erp_cari_hesap_service.go / OK ✅
backup copied: internal/erp/runtime/e2eflow/e2e_flow_db_integration_test.go / OK ✅
backup copied: internal/platform/journal/journal_builder_test.go / OK ✅
===== 6-FIX-V1 PATCH START =====
patch script executed / OK ✅
===== 6-FIX-V1 GOFMT =====
gofmt completed / OK ✅
===== 6-FIX-V1 TARGETED TESTS =====
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
internal/erp/core/cari/service/erp_cari_hesap_service.go:220:49: undefined: domain
internal/erp/core/cari/service/erp_cari_hesap_service.go:226:51: undefined: domain
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
internal/erp/core/cari/service/erp_cari_hesap_service.go:220:49: undefined: domain
internal/erp/core/cari/service/erp_cari_hesap_service.go:226:51: undefined: domain
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
internal/erp/core/cari/service/erp_cari_hesap_service.go:220:49: undefined: domain
internal/erp/core/cari/service/erp_cari_hesap_service.go:226:51: undefined: domain
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
internal/erp/core/cari/service/erp_cari_hesap_service.go:220:49: undefined: domain
internal/erp/core/cari/service/erp_cari_hesap_service.go:226:51: undefined: domain
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service [build failed]
FAIL
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
internal/erp/core/cari/service/erp_cari_hesap_service.go:220:49: undefined: domain
internal/erp/core/cari/service/erp_cari_hesap_service.go:226:51: undefined: domain
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service [build failed]
FAIL
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow	0.006s
ok  	github.com/divrigili/pix2pi-SaaS/internal/platform/journal	0.004s
===== 6-FIX-V1 TARGETED TEST STATUS =====
STATUS_CARI=1
STATUS_ALIS=1
STATUS_SATIS=1
STATUS_TAHSILAT=1
STATUS_RAPOR=1
STATUS_E2E=0
STATUS_JOURNAL=0
cari service test / FAIL ❌
alis service test / FAIL ❌
satis service test / FAIL ❌
tahsilat service test / FAIL ❌
rapor service test / FAIL ❌
e2eflow test / OK ✅
platform journal test / OK ✅
===== 6-FIX-V1 FINAL STATUS =====
PASS_COUNT=10
FAIL_COUNT=5
EVIDENCE_FILE=docs/faz6/evidence/FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FIX_V1_EVIDENCE_20260506_193307.md
FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FIX_V1_STATUS=FAIL
READY_TO_RERUN_FAZ_6_FINAL_AUDIT=NO
