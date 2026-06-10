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
