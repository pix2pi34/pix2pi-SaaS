===== FAZ 6 ERP EVENT / JOURNAL / LEDGER REAL IMPLEMENTATION AUDIT START =====
6.1 ERP/finance-related source/config/doc file count actual=494 IMPLEMENTED_OR_PRESENT / OK ✅
6.2 ERP/finance-related Go test file count actual=137 IMPLEMENTED_OR_PRESENT / OK ✅
6.3 ERP event intake trace actual=43 IMPLEMENTED_OR_PRESENT / OK ✅
6.4 event to accounting rule mapping trace actual=300 IMPLEMENTED_OR_PRESENT / OK ✅
6.5 accounting rule versioning trace actual=32 IMPLEMENTED_OR_PRESENT / OK ✅
6.6 journal builder trace actual=60 IMPLEMENTED_OR_PRESENT / OK ✅
6.7 TDHP / account plan mapping trace actual=327 IMPLEMENTED_OR_PRESENT / OK ✅
6.8 ledger posting pipeline trace actual=91 IMPLEMENTED_OR_PRESENT / OK ✅
6.9 double posting guard trace actual=144 IMPLEMENTED_OR_PRESENT / OK ✅
6.10 failed posting isolation trace actual=434 IMPLEMENTED_OR_PRESENT / OK ✅
6.11 replay-safe accounting trace actual=275 IMPLEMENTED_OR_PRESENT / OK ✅
6.12 financial audit trace actual=253 IMPLEMENTED_OR_PRESENT / OK ✅
6.13 reconciliation / debit-credit balance trace actual=168 IMPLEMENTED_OR_PRESENT / OK ✅
6.14 tenant-aware financial trace actual=1472 IMPLEMENTED_OR_PRESENT / OK ✅
6.15 financial concurrency / transaction safety trace actual=831 IMPLEMENTED_OR_PRESENT / OK ✅
===== FAZ 6 ERP FINANCIAL GO TEST PACKAGES =====
github.com/divrigili/pix2pi-SaaS/cmd/accounting-service
github.com/divrigili/pix2pi-SaaS/cmd/erp/core/ufk
github.com/divrigili/pix2pi-SaaS/cmd/plugin-erp
github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/audit/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/closing/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/engine
github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/engine
github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/reconciliation/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/tax/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service
github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/domain
github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/engine
github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/service
github.com/divrigili/pix2pi-SaaS/internal/erp/operations/reporting/service
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/cashbank
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/chartofaccounts
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/fiscal
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/inventory
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/journal
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/ledger
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/masterparty
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/procurement
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/productcatalog
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/sales
github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/tax
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/cashbankpay
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/docnumber
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/fiscalguard
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/journalpost
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/kernel
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/ledgerpost
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/purchaseinvoice
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/salesinvoice
github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/taxcalc
github.com/divrigili/pix2pi-SaaS/internal/finance/domain
github.com/divrigili/pix2pi-SaaS/internal/platform/journal
github.com/divrigili/pix2pi-SaaS/internal/plugins/erp/handler
github.com/divrigili/pix2pi-SaaS/internal/ufk/domain
github.com/divrigili/pix2pi-SaaS/internal/ufk/service
github.com/divrigili/pix2pi-SaaS/pkg/erpcore
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/accounting
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/accounting/domain
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/audit
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/compliance
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/event
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/ledger
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/posting
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/reporting
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/rule
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/tax
github.com/divrigili/pix2pi-SaaS/pkg/erpcore/validation
github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/accounts
github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/ledger
github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/migrations
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service
internal/erp/core/rapor/service/erp_mizan_service.go:33:43: s.cariHesapService.HesaplariListele undefined (type *"github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service".CariHesapService has no field or method HesaplariListele)
internal/erp/core/rapor/service/erp_mizan_service.go:34:36: s.cariHesapService.HareketleriListele undefined (type *"github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service".CariHesapService has no field or method HareketleriListele)
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service
internal/erp/core/alis/service/erp_alis_fatura_service.go:54:46: not enough arguments in call to s.cariHesapService.CariHesapGetir
	have (string)
	want (string, string)
internal/erp/core/alis/service/erp_alis_fatura_service.go:129:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
?   	github.com/divrigili/pix2pi-SaaS/cmd/accounting-service	[no test files]
FAIL	github.com/divrigili/pix2pi-SaaS/cmd/erp/core/ufk [build failed]
?   	github.com/divrigili/pix2pi-SaaS/cmd/plugin-erp	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/domain	[no test files]
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/alis/service [build failed]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/audit/service	0.003s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/banka/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/closing/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/service	(cached)
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/engine	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/service	0.003s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/kasa/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/engine	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/service	0.007s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/payments/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/domain	[no test files]
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rapor/service [build failed]
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service
internal/erp/core/satis/service/erp_satis_fatura_service.go:49:46: not enough arguments in call to s.cariHesapService.CariHesapGetir
	have (string)
	want (string, string)
internal/erp/core/satis/service/erp_satis_fatura_service.go:111:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/reconciliation/service	0.003s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain	[no test files]
# github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:63:50: not enough arguments in call to s.cariHesapService.CariHesapGetir
	have (string)
	want (string, string)
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:72:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:154:50: not enough arguments in call to s.cariHesapService.CariHesapGetir
	have (string)
	want (string, string)
internal/erp/core/tahsilat/service/erp_tahsilat_service.go:163:3: not enough arguments in call to s.cariHesapService.CariHareketEkle
	have ("github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
	want (string, "github.com/divrigili/pix2pi-SaaS/internal/erp/core/cari/domain".CariHareket)
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/service	0.005s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/domain	[no test files]
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/satis/service [build failed]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/stok/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/domain	[no test files]
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/core/tahsilat/service [build failed]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/tax/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/domain	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/core/ufk/service	0.003s
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/engine	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/core/vergi/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/erp/operations/reporting/service	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/cashbank	1.182s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/chartofaccounts	1.019s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/fiscal	1.385s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/inventory	0.680s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/journal	0.973s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/ledger	1.408s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/masterparty	0.647s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/procurement	0.743s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/productcatalog	0.737s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/sales	0.796s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/persistence/tax	1.289s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface	0.125s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/cashbankpay	0.083s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/docnumber	0.108s
--- FAIL: TestE2EFlowDBSchemaAndRLS (0.03s)
    e2e_flow_db_integration_test.go:83: expected 2 tenant policies, got 6
FAIL
FAIL	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow	0.324s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/fiscalguard	0.095s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/journalpost	0.078s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/kernel	0.044s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/ledgerpost	0.089s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/purchaseinvoice	0.172s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/salesinvoice	0.149s
ok  	github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/taxcalc	0.086s
?   	github.com/divrigili/pix2pi-SaaS/internal/finance/domain	[no test files]
--- FAIL: TestBuildSaleJournal_LineCount (0.00s)
    journal_builder_test.go:39: 2 satir bekleniyordu, gelen 3
FAIL
FAIL	github.com/divrigili/pix2pi-SaaS/internal/platform/journal	0.007s
?   	github.com/divrigili/pix2pi-SaaS/internal/plugins/erp/handler	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/ufk/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/internal/ufk/service	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/accounting	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/accounting/domain	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/audit	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/compliance	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/event	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/ledger	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/posting	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/reporting	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/rule	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/tax	[no test files]
?   	github.com/divrigili/pix2pi-SaaS/pkg/erpcore/validation	[no test files]
ok  	github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/accounts	0.003s
ok  	github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/ledger	0.003s
ok  	github.com/divrigili/pix2pi-SaaS/test/internal/finance/test/migrations	0.003s
FAIL
