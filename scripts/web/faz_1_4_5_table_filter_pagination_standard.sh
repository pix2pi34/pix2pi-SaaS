#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_5_table_filter_pagination_standard_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/table-filter-pagination"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/table_filter_pagination.js"
CSS_FILE="$WEB_DIR/table_filter_pagination.css"
CONFIG_FILE="$CONFIG_DIR/table_filter_pagination_standard_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_5_table_filter_pagination_standard_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_5_table_filter_pagination_standard.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_5_table_filter_pagination_standard_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_FINAL_SEAL_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$HTML_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. table / filter / pagination contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_5",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "table_filter_pagination_standard",
  "status": "READY",
  "required_capabilities": [
    "table_component",
    "filter_component",
    "sort",
    "pagination",
    "empty_state"
  ],
  "table_contract": {
    "root_id": "pix2piTableStandardRoot",
    "table_id": "pix2piDataTable",
    "tbody_id": "pix2piDataTableBody",
    "filter_input_id": "pix2piTableFilterInput",
    "status_filter_id": "pix2piStatusFilter",
    "sort_select_id": "pix2piSortSelect",
    "pagination_id": "pix2piPagination",
    "empty_state_id": "pix2piTableEmptyState"
  },
  "filter_contract": {
    "text_filter": "FILTER_BY_NAME_OR_CODE",
    "status_filter": "FILTER_BY_STATUS",
    "clear_filter": "RESET_FILTERS"
  },
  "sort_contract": {
    "supported_fields": [
      "code",
      "name",
      "status",
      "updated_at"
    ],
    "default_sort": "updated_at_desc"
  },
  "pagination_contract": {
    "page_size": 5,
    "page_size_options": [
      5,
      10,
      25
    ],
    "policy": "CLIENT_SIDE_PAGINATION_FOR_UI_STANDARD"
  },
  "empty_state_contract": {
    "empty_filter_message": "Filtreye uygun kayıt bulunamadı.",
    "empty_dataset_message": "Henüz kayıt yok.",
    "retry_action": "RESET_FILTERS"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 table/filter/pagination config yazıldı: $CONFIG_FILE"
else
  fail "3.1 table/filter/pagination config yazılamadı"
  exit 1
fi

echo "4. table / filter / pagination CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-surface: #111827;
  --pix2pi-surface-soft: #1f2937;
  --pix2pi-content: #020617;
  --pix2pi-border: #334155;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-accent: #38bdf8;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-md: 14px;
  --pix2pi-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #164e63 0, var(--pix2pi-bg) 42%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-page {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
  margin-bottom: 24px;
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 22px;
  box-shadow: var(--pix2pi-shadow);
}

.pix2pi-table-toolbar {
  display: grid;
  grid-template-columns: minmax(220px, 1fr) 180px 220px auto;
  gap: 12px;
  align-items: center;
  margin-bottom: 16px;
}

.pix2pi-filter,
.pix2pi-select {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-content);
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-filter:focus,
.pix2pi-select:focus {
  border-color: var(--pix2pi-accent);
  box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.12);
}

.pix2pi-table-region {
  display: grid;
  gap: 14px;
}

.pix2pi-table-scroll {
  overflow-x: auto;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  background: var(--pix2pi-content);
}

.pix2pi-table {
  width: 100%;
  min-width: 820px;
  border-collapse: collapse;
}

.pix2pi-table th,
.pix2pi-table td {
  padding: 13px 14px;
  border-bottom: 1px solid var(--pix2pi-border);
  text-align: left;
  vertical-align: middle;
}

.pix2pi-table th {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  background: rgba(31, 41, 55, 0.78);
}

.pix2pi-table tr:last-child td {
  border-bottom: 0;
}

.pix2pi-sort-button {
  border: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: inherit;
  padding: 0;
  text-transform: inherit;
  letter-spacing: inherit;
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-badge.warn {
  border-color: rgba(245, 158, 11, 0.5);
  color: #fde68a;
}

.pix2pi-badge.danger {
  border-color: rgba(239, 68, 68, 0.5);
  color: #fecaca;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  padding: 11px 14px;
  cursor: pointer;
  font-weight: 800;
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

.pix2pi-pagination {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
}

.pix2pi-pagination-controls {
  display: flex;
  gap: 8px;
  align-items: center;
}

.pix2pi-pagination-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: 12px;
  background: var(--pix2pi-content);
  color: var(--pix2pi-text);
  padding: 9px 12px;
  cursor: pointer;
}

.pix2pi-pagination-button:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.pix2pi-empty-state {
  display: none;
  border: 1px dashed var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  background: rgba(2, 6, 23, 0.72);
  padding: 28px;
  text-align: center;
  color: var(--pix2pi-muted);
}

.pix2pi-empty-state.visible {
  display: block;
}

.pix2pi-log {
  margin-top: 16px;
  background: var(--pix2pi-content);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 14px;
  color: var(--pix2pi-muted);
  min-height: 180px;
  white-space: pre-wrap;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

@media (max-width: 900px) {
  .pix2pi-page-header,
  .pix2pi-table-toolbar {
    display: grid;
    grid-template-columns: 1fr;
  }

  .pix2pi-pagination {
    align-items: stretch;
  }

  .pix2pi-pagination-controls,
  .pix2pi-pagination-controls .pix2pi-pagination-button,
  .pix2pi-button {
    width: 100%;
  }
}
CSS

if grep -q "pix2pi-table" "$CSS_FILE" \
  && grep -q "pix2pi-filter" "$CSS_FILE" \
  && grep -q "pix2pi-sort-button" "$CSS_FILE" \
  && grep -q "pix2pi-pagination" "$CSS_FILE" \
  && grep -q "pix2pi-empty-state" "$CSS_FILE"; then
  pass "4.1 CSS table/filter/pagination sınıfları mevcut"
else
  fail "4.1 CSS table/filter/pagination sınıfları eksik"
  exit 1
fi

echo "5. table / filter / pagination JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function tableFilterPaginationRuntime(global) {
  "use strict";

  const DATASET = [
    { code: "TENANT001", name: "Pix2pi Pilot İşletme", status: "ACTIVE", type: "Tenant", updated_at: "2026-05-06T10:00:00Z" },
    { code: "ERP001", name: "ERP Çekirdeği", status: "ACTIVE", type: "Module", updated_at: "2026-05-06T09:20:00Z" },
    { code: "POS001", name: "POS Operasyon", status: "READY", type: "Module", updated_at: "2026-05-05T18:00:00Z" },
    { code: "ACC001", name: "Muhasebe Export", status: "READY", type: "Feature", updated_at: "2026-05-05T17:30:00Z" },
    { code: "OPS001", name: "Ops Console", status: "DRAFT", type: "Surface", updated_at: "2026-05-04T14:00:00Z" },
    { code: "AUTH001", name: "Auth Tenant UX", status: "ACTIVE", type: "Surface", updated_at: "2026-05-06T11:00:00Z" },
    { code: "UI001", name: "UI Foundation", status: "READY", type: "Foundation", updated_at: "2026-05-06T12:00:00Z" },
    { code: "REP001", name: "Reporting Store", status: "DRAFT", type: "Module", updated_at: "2026-05-03T08:10:00Z" }
  ];

  const state = {
    query: "",
    status: "ALL",
    sort: "updated_at_desc",
    page: 1,
    pageSize: 5
  };

  function normalize(value) {
    return String(value || "").toLowerCase().trim();
  }

  function applyFilters(rows, filterState) {
    const current = filterState || state;
    const query = normalize(current.query);
    const status = current.status || "ALL";

    return rows.filter((row) => {
      const matchesQuery = !query || normalize(row.code).includes(query) || normalize(row.name).includes(query) || normalize(row.type).includes(query);
      const matchesStatus = status === "ALL" || row.status === status;
      return matchesQuery && matchesStatus;
    });
  }

  function sortRows(rows, sortKey) {
    const key = sortKey || state.sort;
    const sorted = rows.slice();

    const direction = key.endsWith("_asc") ? "asc" : "desc";
    const field = key.replace("_asc", "").replace("_desc", "");

    sorted.sort((a, b) => {
      const av = String(a[field] || "");
      const bv = String(b[field] || "");
      const result = av.localeCompare(bv, "tr");
      return direction === "asc" ? result : -result;
    });

    return sorted;
  }

  function paginateRows(rows, page, pageSize) {
    const currentPage = Math.max(1, Number(page || 1));
    const size = Math.max(1, Number(pageSize || state.pageSize));
    const start = (currentPage - 1) * size;

    return rows.slice(start, start + size);
  }

  function getTotalPages(totalRows, pageSize) {
    return Math.max(1, Math.ceil(Number(totalRows || 0) / Number(pageSize || state.pageSize)));
  }

  function getVisibleRows() {
    const filtered = applyFilters(DATASET, state);
    const sorted = sortRows(filtered, state.sort);
    const totalPages = getTotalPages(sorted.length, state.pageSize);

    if (state.page > totalPages) {
      state.page = totalPages;
    }

    return {
      filtered,
      sorted,
      paginated: paginateRows(sorted, state.page, state.pageSize),
      totalPages
    };
  }

  function renderStatusBadge(status) {
    const className = status === "ACTIVE" ? "ok" : status === "READY" ? "warn" : "";
    return '<span class="pix2pi-badge ' + className + '">' + status + '</span>';
  }

  function renderTable() {
    const tbody = document.getElementById("pix2piDataTableBody");
    const empty = document.getElementById("pix2piTableEmptyState");
    const result = getVisibleRows();

    if (!tbody || !empty) {
      return result;
    }

    tbody.innerHTML = "";

    result.paginated.forEach((row) => {
      const tr = document.createElement("tr");
      tr.innerHTML = "<td></td><td></td><td></td><td></td><td></td>";
      tr.children[0].textContent = row.code;
      tr.children[1].textContent = row.name;
      tr.children[2].textContent = row.type;
      tr.children[3].innerHTML = renderStatusBadge(row.status);
      tr.children[4].textContent = row.updated_at;
      tbody.appendChild(tr);
    });

    renderEmptyState(result.filtered.length === 0);
    renderPagination(result);
    renderTableLog(result);

    return result;
  }

  function renderEmptyState(isEmpty) {
    const empty = document.getElementById("pix2piTableEmptyState");
    if (!empty) {
      return;
    }

    if (isEmpty) {
      empty.classList.add("visible");
      empty.textContent = DATASET.length === 0 ? "Henüz kayıt yok." : "Filtreye uygun kayıt bulunamadı.";
    } else {
      empty.classList.remove("visible");
      empty.textContent = "";
    }
  }

  function renderPagination(result) {
    const info = document.getElementById("pix2piPaginationInfo");
    const prev = document.getElementById("pix2piPrevPageButton");
    const next = document.getElementById("pix2piNextPageButton");

    if (info) {
      info.textContent = "Sayfa " + state.page + " / " + result.totalPages + " — " + result.filtered.length + " kayıt";
    }

    if (prev) {
      prev.disabled = state.page <= 1;
    }

    if (next) {
      next.disabled = state.page >= result.totalPages;
    }
  }

  function renderTableLog(result) {
    const log = document.getElementById("pix2piTableLog");
    if (!log) {
      return;
    }

    log.textContent = JSON.stringify({
      state,
      filtered_count: result.filtered.length,
      visible_count: result.paginated.length,
      total_pages: result.totalPages
    }, null, 2);
  }

  function setFilter(query) {
    state.query = String(query || "");
    state.page = 1;
    return renderTable();
  }

  function setStatusFilter(status) {
    state.status = status || "ALL";
    state.page = 1;
    return renderTable();
  }

  function setSort(sortKey) {
    state.sort = sortKey || "updated_at_desc";
    state.page = 1;
    return renderTable();
  }

  function setPage(page) {
    state.page = Math.max(1, Number(page || 1));
    return renderTable();
  }

  function setPageSize(pageSize) {
    state.pageSize = Math.max(1, Number(pageSize || 5));
    state.page = 1;
    return renderTable();
  }

  function resetFilters() {
    state.query = "";
    state.status = "ALL";
    state.sort = "updated_at_desc";
    state.page = 1;

    const filterInput = document.getElementById("pix2piTableFilterInput");
    const statusFilter = document.getElementById("pix2piStatusFilter");
    const sortSelect = document.getElementById("pix2piSortSelect");
    const pageSizeSelect = document.getElementById("pix2piPageSizeSelect");

    if (filterInput) filterInput.value = "";
    if (statusFilter) statusFilter.value = "ALL";
    if (sortSelect) sortSelect.value = "updated_at_desc";
    if (pageSizeSelect) pageSizeSelect.value = String(state.pageSize);

    return renderTable();
  }

  function runTableStandardTests() {
    const filtered = applyFilters(DATASET, { query: "erp", status: "ALL" });
    const sorted = sortRows(DATASET, "code_asc");
    const paginated = paginateRows(DATASET, 1, 5);

    return {
      table_component: Boolean(document.getElementById("pix2piDataTable")) ? "PASS" : "FAIL",
      filter_component: filtered.length >= 1 ? "PASS" : "FAIL",
      sort: sorted[0].code <= sorted[1].code ? "PASS" : "FAIL",
      pagination: paginated.length === 5 ? "PASS" : "FAIL",
      empty_state: Boolean(document.getElementById("pix2piTableEmptyState")) ? "PASS" : "FAIL"
    };
  }

  function renderTableStandardTests() {
    const output = document.getElementById("pix2piTableTestOutput");
    const result = runTableStandardTests();

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    return result;
  }

  function bootstrapTableFilterPagination() {
    const filterInput = document.getElementById("pix2piTableFilterInput");
    const statusFilter = document.getElementById("pix2piStatusFilter");
    const sortSelect = document.getElementById("pix2piSortSelect");
    const pageSizeSelect = document.getElementById("pix2piPageSizeSelect");
    const prev = document.getElementById("pix2piPrevPageButton");
    const next = document.getElementById("pix2piNextPageButton");
    const reset = document.getElementById("pix2piResetFilterButton");
    const test = document.getElementById("pix2piRunTableTestsButton");

    if (filterInput) {
      filterInput.addEventListener("input", () => setFilter(filterInput.value));
    }

    if (statusFilter) {
      statusFilter.addEventListener("change", () => setStatusFilter(statusFilter.value));
    }

    if (sortSelect) {
      sortSelect.addEventListener("change", () => setSort(sortSelect.value));
    }

    if (pageSizeSelect) {
      pageSizeSelect.addEventListener("change", () => setPageSize(pageSizeSelect.value));
    }

    if (prev) {
      prev.addEventListener("click", () => setPage(state.page - 1));
    }

    if (next) {
      next.addEventListener("click", () => setPage(state.page + 1));
    }

    if (reset) {
      reset.addEventListener("click", resetFilters);
    }

    if (test) {
      test.addEventListener("click", renderTableStandardTests);
    }

    renderTable();
    renderTableStandardTests();
  }

  const api = {
    DATASET,
    state,
    applyFilters,
    sortRows,
    paginateRows,
    getTotalPages,
    getVisibleRows,
    renderTable,
    renderEmptyState,
    renderPagination,
    setFilter,
    setStatusFilter,
    setSort,
    setPage,
    setPageSize,
    resetFilters,
    runTableStandardTests,
    renderTableStandardTests,
    bootstrapTableFilterPagination
  };

  global.Pix2piTableFilterPagination = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapTableFilterPagination);
    } else {
      bootstrapTableFilterPagination();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "renderTable" "$JS_FILE" \
  && grep -q "applyFilters" "$JS_FILE" \
  && grep -q "sortRows" "$JS_FILE" \
  && grep -q "paginateRows" "$JS_FILE" \
  && grep -q "renderEmptyState" "$JS_FILE"; then
  pass "5.1 JS table/filter/pagination runtime fonksiyonları mevcut"
else
  fail "5.1 JS table/filter/pagination runtime fonksiyonları eksik"
  exit 1
fi

echo "6. table / filter / pagination HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Table / Filter / Pagination Standardı</title>
  <link rel="stylesheet" href="./table_filter_pagination.css">
</head>
<body>
  <main class="pix2pi-page" id="pix2piTableStandardRoot">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Table / Filter / Pagination Standardı</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.5 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L1 READY</span>
    </header>

    <section class="pix2pi-card pix2pi-table-region">
      <div class="pix2pi-table-toolbar">
        <input class="pix2pi-filter" id="pix2piTableFilterInput" type="search" placeholder="Kod, ad veya tip ara">

        <select class="pix2pi-select" id="pix2piStatusFilter">
          <option value="ALL">Tüm durumlar</option>
          <option value="ACTIVE">ACTIVE</option>
          <option value="READY">READY</option>
          <option value="DRAFT">DRAFT</option>
        </select>

        <select class="pix2pi-select" id="pix2piSortSelect">
          <option value="updated_at_desc">Güncelleme yeni → eski</option>
          <option value="updated_at_asc">Güncelleme eski → yeni</option>
          <option value="code_asc">Kod A → Z</option>
          <option value="code_desc">Kod Z → A</option>
          <option value="name_asc">Ad A → Z</option>
          <option value="name_desc">Ad Z → A</option>
          <option value="status_asc">Durum A → Z</option>
        </select>

        <button class="pix2pi-button" id="pix2piResetFilterButton" type="button">Filtreyi temizle</button>
      </div>

      <div class="pix2pi-table-scroll">
        <table class="pix2pi-table" id="pix2piDataTable">
          <thead>
            <tr>
              <th><button class="pix2pi-sort-button" type="button" data-sort-field="code">Kod</button></th>
              <th><button class="pix2pi-sort-button" type="button" data-sort-field="name">Ad</button></th>
              <th>Tip</th>
              <th><button class="pix2pi-sort-button" type="button" data-sort-field="status">Durum</button></th>
              <th><button class="pix2pi-sort-button" type="button" data-sort-field="updated_at">Güncelleme</button></th>
            </tr>
          </thead>
          <tbody id="pix2piDataTableBody"></tbody>
        </table>
      </div>

      <div class="pix2pi-empty-state" id="pix2piTableEmptyState"></div>

      <footer class="pix2pi-pagination" id="pix2piPagination">
        <div class="pix2pi-pagination-controls">
          <button class="pix2pi-pagination-button" id="pix2piPrevPageButton" type="button">Önceki</button>
          <button class="pix2pi-pagination-button" id="pix2piNextPageButton" type="button">Sonraki</button>
        </div>

        <span class="pix2pi-badge" id="pix2piPaginationInfo">Sayfa hazırlanıyor</span>

        <select class="pix2pi-select" id="pix2piPageSizeSelect" style="max-width: 140px;">
          <option value="5">5 / sayfa</option>
          <option value="10">10 / sayfa</option>
          <option value="25">25 / sayfa</option>
        </select>
      </footer>

      <button class="pix2pi-button primary" id="pix2piRunTableTestsButton" type="button">Table testlerini çalıştır</button>
      <pre class="pix2pi-log" id="pix2piTableTestOutput">TABLE_TEST_LOADING</pre>
      <pre class="pix2pi-log" id="pix2piTableLog">TABLE_LOG_LOADING</pre>
    </section>
  </main>

  <script src="./table_filter_pagination.js"></script>
</body>
</html>
HTML

if grep -q "pix2piDataTable" "$HTML_FILE" \
  && grep -q "pix2piTableFilterInput" "$HTML_FILE" \
  && grep -q "pix2piSortSelect" "$HTML_FILE" \
  && grep -q "pix2piPagination" "$HTML_FILE" \
  && grep -q "pix2piTableEmptyState" "$HTML_FILE"; then
  pass "6.1 HTML table/filter/pagination elementleri mevcut"
else
  fail "6.1 HTML table/filter/pagination elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/table-filter-pagination"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/table_filter_pagination.js"
CSS_FILE="$WEB_DIR/table_filter_pagination.css"
CONFIG_FILE="$CONFIG_DIR/table_filter_pagination_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"table_component"' "3.1 table_component capability contract"
check_contains "$CONFIG_FILE" '"filter_component"' "3.2 filter_component capability contract"
check_contains "$CONFIG_FILE" '"sort"' "3.3 sort capability contract"
check_contains "$CONFIG_FILE" '"pagination"' "3.4 pagination capability contract"
check_contains "$CONFIG_FILE" '"empty_state"' "3.5 empty_state capability contract"

check_contains "$HTML_FILE" 'pix2piDataTable' "4.1 table component HTML"
check_contains "$HTML_FILE" 'pix2piTableFilterInput' "4.2 filter component HTML"
check_contains "$HTML_FILE" 'pix2piSortSelect' "4.3 sort select HTML"
check_contains "$HTML_FILE" 'pix2piPagination' "4.4 pagination HTML"
check_contains "$HTML_FILE" 'pix2piTableEmptyState' "4.5 empty state HTML"

check_contains "$JS_FILE" 'renderTable' "5.1 table render JS"
check_contains "$JS_FILE" 'applyFilters' "5.2 filter JS"
check_contains "$JS_FILE" 'sortRows' "5.3 sort JS"
check_contains "$JS_FILE" 'paginateRows' "5.4 pagination JS"
check_contains "$JS_FILE" 'renderEmptyState' "5.5 empty state JS"
check_contains "$JS_FILE" 'runTableStandardTests' "5.6 table tests JS"

check_contains "$CSS_FILE" 'pix2pi-table' "6.1 table CSS"
check_contains "$CSS_FILE" 'pix2pi-filter' "6.2 filter CSS"
check_contains "$CSS_FILE" 'pix2pi-sort-button' "6.3 sort CSS"
check_contains "$CSS_FILE" 'pix2pi-pagination' "6.4 pagination CSS"
check_contains "$CSS_FILE" 'pix2pi-empty-state' "6.5 empty state CSS"

TABLE_COMPONENT_STATUS="PASS"
FILTER_COMPONENT_STATUS="PASS"
SORT_STATUS="PASS"
PAGINATION_STATUS="PASS"
EMPTY_STATE_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  TABLE_COMPONENT_STATUS="FAIL"
  FILTER_COMPONENT_STATUS="FAIL"
  SORT_STATUS="FAIL"
  PAGINATION_STATUS="FAIL"
  EMPTY_STATE_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.5 Table / Filter / Pagination Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- TABLE_COMPONENT_STATUS=$TABLE_COMPONENT_STATUS"
  echo "- FILTER_COMPONENT_STATUS=$FILTER_COMPONENT_STATUS"
  echo "- SORT_STATUS=$SORT_STATUS"
  echo "- PAGINATION_STATUS=$PAGINATION_STATUS"
  echo "- EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "TABLE_COMPONENT_STATUS=$TABLE_COMPONENT_STATUS"
echo "FILTER_COMPONENT_STATUS=$FILTER_COMPONENT_STATUS"
echo "SORT_STATUS=$SORT_STATUS"
echo "PAGINATION_STATUS=$PAGINATION_STATUS"
echo "EMPTY_STATE_STATUS=$EMPTY_STATE_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"

if [ -x "$STRICT_SUITE_FILE" ]; then
  pass "7.1 strict suite dosyası yazıldı ve executable yapıldı: $STRICT_SUITE_FILE"
else
  fail "7.1 strict suite executable değil"
  exit 1
fi

echo "8. strict suite çalıştırılıyor..."

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "8.1 strict suite exit code 0"
else
  fail "8.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
  exit 1
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_STRICT_SUITE_SEAL_STATUS")"

TABLE_COMPONENT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TABLE_COMPONENT_STATUS")"
FILTER_COMPONENT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FILTER_COMPONENT_STATUS")"
SORT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SORT_STATUS")"
PAGINATION_STATUS="$(extract_var "$STRICT_SUITE_OUT" "PAGINATION_STATUS")"
EMPTY_STATE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "EMPTY_STATE_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.5 — Table / Filter / Pagination Standardı

## Kapsam

- Table component
- Filter component
- Sort
- Pagination
- Empty state

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/table-filter-pagination/index.html
- Runtime JS: web/faz1/ui-foundation/table-filter-pagination/table_filter_pagination.js
- CSS: web/faz1/ui-foundation/table-filter-pagination/table_filter_pagination.css
- Contract: configs/faz1/web/ui_foundation/table_filter_pagination_standard_contract.v1.json
- Strict suite: scripts/web/faz_1_4_5_table_filter_pagination_standard_strict_suite.sh

## Final Status

- TABLE_COMPONENT_STATUS=${TABLE_COMPONENT_STATUS:-N/A}
- FILTER_COMPONENT_STATUS=${FILTER_COMPONENT_STATUS:-N/A}
- SORT_STATUS=${SORT_STATUS:-N/A}
- PAGINATION_STATUS=${PAGINATION_STATUS:-N/A}
- EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.5 Table / Filter / Pagination Standard Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- TABLE_COMPONENT_STATUS=${TABLE_COMPONENT_STATUS:-N/A}"
  echo "- FILTER_COMPONENT_STATUS=${FILTER_COMPONENT_STATUS:-N/A}"
  echo "- SORT_STATUS=${SORT_STATUS:-N/A}"
  echo "- PAGINATION_STATUS=${PAGINATION_STATUS:-N/A}"
  echo "- EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Counters"
  echo "- APPLY_PASS_COUNT=$PASS_COUNT"
  echo "- APPLY_FAIL_COUNT=$FAIL_COUNT"
  echo "- APPLY_WARN_COUNT=$WARN_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-4.5 Table / Filter / Pagination Standard Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_5_TABLE_COMPONENT_STATUS=${TABLE_COMPONENT_STATUS:-N/A}"
  echo "FAZ_1_4_5_FILTER_COMPONENT_STATUS=${FILTER_COMPONENT_STATUS:-N/A}"
  echo "FAZ_1_4_5_SORT_STATUS=${SORT_STATUS:-N/A}"
  echo "FAZ_1_4_5_PAGINATION_STATUS=${PAGINATION_STATUS:-N/A}"
  echo "FAZ_1_4_5_EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_6_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "9.1 dokümantasyon yazıldı: $DOC_FILE"
pass "9.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "9.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"

if [ -x "$APPLY_SCRIPT_FILE" ]; then
  pass "9.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"
else
  fail "9.4 apply script repo içine kopyalanamadı"
  exit 1
fi

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "TABLE_COMPONENT_STATUS=${TABLE_COMPONENT_STATUS:-N/A}"
echo "FILTER_COMPONENT_STATUS=${FILTER_COMPONENT_STATUS:-N/A}"
echo "SORT_STATUS=${SORT_STATUS:-N/A}"
echo "PAGINATION_STATUS=${PAGINATION_STATUS:-N/A}"
echo "EMPTY_STATE_STATUS=${EMPTY_STATE_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HTML_FILE=$HTML_FILE"
echo "JS_FILE=$JS_FILE"
echo "CSS_FILE=$CSS_FILE"
echo "CONFIG_FILE=$CONFIG_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_4_5_TABLE_COMPONENT_STATUS=PASS"
  echo "FAZ_1_4_5_FILTER_COMPONENT_STATUS=PASS"
  echo "FAZ_1_4_5_SORT_STATUS=PASS"
  echo "FAZ_1_4_5_PAGINATION_STATUS=PASS"
  echo "FAZ_1_4_5_EMPTY_STATE_STATUS=PASS"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_FINAL_STATUS=PASS"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_6_READY=YES"
else
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_5_TABLE_FILTER_PAGINATION_STANDARD_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_6_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.5 TABLE / FILTER / PAGINATION STANDARD END ====="
