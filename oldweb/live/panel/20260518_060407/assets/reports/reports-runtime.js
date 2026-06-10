/* PIX2PI_327_REPORTS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    snapshotEndpoint: "/api/panel/reports/snapshot",
    salesEndpoint: "/api/panel/reports/sales",
    stockEndpoint: "/api/panel/reports/stock",
    customersEndpoint: "/api/panel/reports/customers",
    documentsEndpoint: "/api/panel/reports/documents",
    exportEndpoint: "/api/panel/reports/export",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    reportTypes: ["SALES", "STOCK", "CUSTOMERS", "DOCUMENTS"],
    exportFormats: ["PDF", "XLSX", "CSV", "JSON"],
    readModelContract: {
      source: "reporting_store",
      productionQueryEnabled: false,
      fallbackSnapshotEnabled: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      period: {
        from: "2026-01-01",
        to: "2026-12-31"
      },
      kpis: {
        total_sales: 0,
        receipt_count: 0,
        product_count: 0,
        customer_count: 0,
        document_count: 0,
        stock_total: 0
      },
      sales: [
        { label: "Bugün", amount: 0, receipt_count: 0 },
        { label: "Bu hafta", amount: 0, receipt_count: 0 },
        { label: "Bu ay", amount: 0, receipt_count: 0 }
      ],
      stock: [
        { label: "Toplam stok", value: 0 },
        { label: "Kritik stok", value: 0 },
        { label: "Depo sayısı", value: 1 }
      ],
      customers: [
        { label: "Aktif cari", value: 0 },
        { label: "Tedarikçi", value: 0 },
        { label: "Borç/alacak toplam", value: 0 }
      ],
      documents: [
        { label: "Taslak belge", value: 0 },
        { label: "Export hazır", value: 0 },
        { label: "Provider kapalı", value: 0 }
      ]
    }
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getJwt() {
    return window.localStorage.getItem(CONFIG.jwtKey) || "";
  }

  function tenantScopedHeaders() {
    const token = getJwt();
    return {
      "Content-Type": "application/json",
      "Authorization": token ? "Bearer " + token : "",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-Pix2pi-Surface": "panel",
      "X-Pix2pi-Step": "327"
    };
  }

  function readFilters(form) {
    const filters = {};
    new FormData(form).forEach(function (value, key) {
      filters[key] = String(value || "").trim();
    });

    filters.tenant_id = getSelectedTenantId();
    filters.source = "panel_reports";
    filters.phase = "FAZ_7R";
    filters.step = "327";
    return filters;
  }

  function validateReportFilters(filters) {
    const errors = [];

    if (!filters.report_type || CONFIG.reportTypes.indexOf(filters.report_type) === -1) {
      errors.push({ field: "report_type", code: "INVALID_REPORT_TYPE" });
    }

    if (!filters.date_from) {
      errors.push({ field: "date_from", code: "REQUIRED" });
    }

    if (!filters.date_to) {
      errors.push({ field: "date_to", code: "REQUIRED" });
    }

    if (filters.date_from && filters.date_to && filters.date_from > filters.date_to) {
      errors.push({ field: "date_range", code: "INVALID_RANGE" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("REPORTS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchReportsSnapshot(filters) {
    try {
      const query = filters ? "?report_type=" + encodeURIComponent(filters.report_type || "SALES") : "";
      return await apiJson(CONFIG.snapshotEndpoint + query, { method: "GET" });
    } catch (_error) {
      return CONFIG.fallbackSnapshot;
    }
  }

  function endpointForReportType(reportType) {
    const map = {
      SALES: CONFIG.salesEndpoint,
      STOCK: CONFIG.stockEndpoint,
      CUSTOMERS: CONFIG.customersEndpoint,
      DOCUMENTS: CONFIG.documentsEndpoint
    };
    return map[reportType] || CONFIG.snapshotEndpoint;
  }

  async function fetchReport(filters) {
    const validation = validateReportFilters(filters);

    if (!validation.valid) {
      return {
        fetched: false,
        validation: validation,
        fallback_snapshot: CONFIG.fallbackSnapshot
      };
    }

    try {
      const endpoint = endpointForReportType(filters.report_type);
      return await apiJson(endpoint, {
        method: "POST",
        body: JSON.stringify(filters)
      });
    } catch (_error) {
      return {
        fetched: false,
        validation: validation,
        fallback_snapshot: CONFIG.fallbackSnapshot
      };
    }
  }

  function buildExportPayload(filters, format) {
    return {
      tenant_id: getSelectedTenantId(),
      report_type: filters.report_type,
      date_from: filters.date_from,
      date_to: filters.date_to,
      format: format || "PDF",
      allowed_formats: CONFIG.exportFormats,
      source: "panel_reports",
      phase: "FAZ_7R",
      step: "327"
    };
  }

  async function requestReportExport(filters, format) {
    const validation = validateReportFilters(filters);
    const payload = buildExportPayload(filters, format);

    if (!validation.valid) {
      return {
        exported: false,
        validation: validation,
        payload: payload
      };
    }

    try {
      const response = await apiJson(CONFIG.exportEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });

      return {
        exported: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        exported: false,
        validation: validation,
        fallback_payload: payload
      };
    }
  }

  function moneyTRY(value) {
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY"
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function renderRows(target, rows, type) {
    if (!target) return;

    target.innerHTML = "";

    (rows || []).forEach(function (row) {
      const item = document.createElement("article");
      item.className = "report-row";
      item.setAttribute("data-report-row-type", type);
      item.innerHTML = "<strong>" + row.label + "</strong><span>" + (row.amount !== undefined ? moneyTRY(row.amount) : String(row.value || row.receipt_count || 0)) + "</span>";
      target.appendChild(item);
    });
  }

  function renderReportsSnapshot(snapshot) {
    setText("report-kpi-total-sales", moneyTRY(snapshot.kpis.total_sales));
    setText("report-kpi-receipt-count", String(snapshot.kpis.receipt_count));
    setText("report-kpi-product-count", String(snapshot.kpis.product_count));
    setText("report-kpi-customer-count", String(snapshot.kpis.customer_count));
    setText("report-kpi-document-count", String(snapshot.kpis.document_count));
    setText("report-kpi-stock-total", String(snapshot.kpis.stock_total));

    renderRows(document.getElementById("sales-report-list"), snapshot.sales, "sales");
    renderRows(document.getElementById("stock-report-list"), snapshot.stock, "stock");
    renderRows(document.getElementById("customers-report-list"), snapshot.customers, "customers");
    renderRows(document.getElementById("documents-report-list"), snapshot.documents, "documents");

    document.body.setAttribute("data-reports-rendered", "true");
    return snapshot;
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Rapor filtresi geçerli.";
      target.setAttribute("data-validation-status", "valid");
      target.hidden = false;
      return;
    }

    target.textContent = validation.errors.map(function (err) {
      return err.field + ":" + err.code;
    }).join(" / ");
    target.setAttribute("data-validation-status", "invalid");
    target.hidden = false;
  }

  async function bootReportsScreen() {
    const snapshot = await fetchReportsSnapshot();
    return renderReportsSnapshot(snapshot);
  }

  window.Pix2piReports = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getJwt: getJwt,
    tenantScopedHeaders: tenantScopedHeaders,
    readFilters: readFilters,
    validateReportFilters: validateReportFilters,
    fetchReportsSnapshot: fetchReportsSnapshot,
    endpointForReportType: endpointForReportType,
    fetchReport: fetchReport,
    buildExportPayload: buildExportPayload,
    requestReportExport: requestReportExport,
    renderRows: renderRows,
    renderReportsSnapshot: renderReportsSnapshot,
    renderValidation: renderValidation,
    bootReportsScreen: bootReportsScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_327_REPORTS_RUNTIME_END */
