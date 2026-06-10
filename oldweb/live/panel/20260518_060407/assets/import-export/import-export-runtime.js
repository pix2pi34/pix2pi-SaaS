/* PIX2PI_328_IMPORT_EXPORT_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    templateEndpoint: "/api/panel/import-export/template",
    validateEndpoint: "/api/panel/import-export/validate",
    importEndpoint: "/api/panel/import-export/import",
    exportEndpoint: "/api/panel/import-export/export",
    jobsEndpoint: "/api/panel/import-export/jobs",
    historyEndpoint: "/api/panel/import-export/history",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    domains: ["CUSTOMERS", "PRODUCTS", "DOCUMENTS", "ACCOUNTING"],
    importFormats: ["CSV", "XLSX", "JSON"],
    exportFormats: ["CSV", "XLSX", "PDF", "JSON", "LOGO", "MIKRO", "ZIRVE", "ETA"],
    accountingExportFormats: ["LOGO", "MIKRO", "ZIRVE", "ETA"],
    runtimeContract: {
      realFileProcessingEnabled: false,
      productionAccountingExportEnabled: false,
      stagingPreviewEnabled: true,
      fallbackSnapshotEnabled: true
    },
    fallbackSnapshot: {
      jobs: [
        {
          id: "imp-demo-001",
          domain: "CUSTOMERS",
          format: "XLSX",
          status: "STAGING_READY",
          row_count: 0,
          valid_count: 0,
          error_count: 0
        },
        {
          id: "imp-demo-002",
          domain: "PRODUCTS",
          format: "CSV",
          status: "VALIDATION_REQUIRED",
          row_count: 0,
          valid_count: 0,
          error_count: 0
        }
      ],
      history: [
        {
          id: "exp-demo-001",
          domain: "ACCOUNTING",
          format: "LOGO",
          status: "PLACEHOLDER_READY",
          created_at: "2026-01-01"
        },
        {
          id: "exp-demo-002",
          domain: "DOCUMENTS",
          format: "PDF",
          status: "PLACEHOLDER_READY",
          created_at: "2026-01-01"
        }
      ],
      mappingPreview: {
        CUSTOMERS: ["customer_name", "tax_number", "tax_office", "city", "district", "address_line", "phone", "email"],
        PRODUCTS: ["product_name", "sku", "barcode", "unit", "vat_rate", "sale_price", "stock_quantity"],
        DOCUMENTS: ["document_type", "customer_name", "tax_number", "line_product_name", "line_quantity", "line_unit_price", "line_vat_rate"],
        ACCOUNTING: ["account_code", "debit", "credit", "description", "document_no"]
      }
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
      "X-Pix2pi-Step": "328"
    };
  }

  function readForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });

    data.tenant_id = getSelectedTenantId();
    data.source = "panel_import_export";
    data.phase = "FAZ_7R";
    data.step = "328";
    return data;
  }

  function validateDomain(domain) {
    return CONFIG.domains.indexOf(domain) >= 0;
  }

  function validateImportFormat(format) {
    return CONFIG.importFormats.indexOf(format) >= 0;
  }

  function validateExportFormat(format) {
    return CONFIG.exportFormats.indexOf(format) >= 0;
  }

  function validateImportPayload(payload) {
    const errors = [];

    if (!payload.domain || !validateDomain(payload.domain)) {
      errors.push({ field: "domain", code: "INVALID_DOMAIN" });
    }

    if (!payload.import_format || !validateImportFormat(payload.import_format)) {
      errors.push({ field: "import_format", code: "INVALID_IMPORT_FORMAT" });
    }

    if (!payload.mapping_policy) {
      errors.push({ field: "mapping_policy", code: "REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function validateExportPayload(payload) {
    const errors = [];

    if (!payload.domain || !validateDomain(payload.domain)) {
      errors.push({ field: "domain", code: "INVALID_DOMAIN" });
    }

    if (!payload.export_format || !validateExportFormat(payload.export_format)) {
      errors.push({ field: "export_format", code: "INVALID_EXPORT_FORMAT" });
    }

    if (CONFIG.accountingExportFormats.indexOf(payload.export_format) >= 0 && payload.domain !== "ACCOUNTING") {
      errors.push({ field: "domain", code: "ACCOUNTING_FORMAT_REQUIRES_ACCOUNTING_DOMAIN" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function buildTemplateRequestPayload(domain, format) {
    return {
      tenant_id: getSelectedTenantId(),
      domain: domain,
      format: format || "XLSX",
      source: "panel_import_export",
      phase: "FAZ_7R",
      step: "328"
    };
  }

  function buildImportValidationPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      domain: payload.domain,
      import_format: payload.import_format,
      mapping_policy: payload.mapping_policy,
      staging_preview_enabled: CONFIG.runtimeContract.stagingPreviewEnabled,
      real_file_processing_enabled: CONFIG.runtimeContract.realFileProcessingEnabled,
      source: "panel_import_export",
      phase: "FAZ_7R",
      step: "328"
    };
  }

  function buildImportStartPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      domain: payload.domain,
      import_format: payload.import_format,
      mapping_policy: payload.mapping_policy,
      dry_run_required: true,
      real_file_processing_enabled: false,
      source: "panel_import_export",
      phase: "FAZ_7R",
      step: "328"
    };
  }

  function buildExportPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      domain: payload.domain,
      export_format: payload.export_format,
      production_accounting_export_enabled: CONFIG.runtimeContract.productionAccountingExportEnabled,
      source: "panel_import_export",
      phase: "FAZ_7R",
      step: "328"
    };
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("IMPORT_EXPORT_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchJobs() {
    try {
      return await apiJson(CONFIG.jobsEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        jobs: CONFIG.fallbackSnapshot.jobs
      };
    }
  }

  async function fetchHistory() {
    try {
      return await apiJson(CONFIG.historyEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        history: CONFIG.fallbackSnapshot.history
      };
    }
  }

  async function requestTemplate(domain, format) {
    const payload = buildTemplateRequestPayload(domain, format);

    try {
      return await apiJson(CONFIG.templateEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  async function validateImport(payload) {
    const validation = validateImportPayload(payload);
    const requestPayload = buildImportValidationPayload(payload);

    if (!validation.valid) {
      return {
        validated: false,
        validation: validation,
        payload: requestPayload
      };
    }

    try {
      const response = await apiJson(CONFIG.validateEndpoint, {
        method: "POST",
        body: JSON.stringify(requestPayload)
      });

      return {
        validated: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        validated: false,
        validation: validation,
        fallback_payload: requestPayload
      };
    }
  }

  async function startImport(payload) {
    const validation = validateImportPayload(payload);
    const requestPayload = buildImportStartPayload(payload);

    if (!validation.valid) {
      return {
        started: false,
        validation: validation,
        payload: requestPayload
      };
    }

    try {
      const response = await apiJson(CONFIG.importEndpoint, {
        method: "POST",
        body: JSON.stringify(requestPayload)
      });

      return {
        started: true,
        validation: validation,
        response: response
      };
    } catch (_error) {
      return {
        started: false,
        validation: validation,
        fallback_payload: requestPayload
      };
    }
  }

  async function startExport(payload) {
    const validation = validateExportPayload(payload);
    const requestPayload = buildExportPayload(payload);

    if (!validation.valid) {
      return {
        exported: false,
        validation: validation,
        payload: requestPayload
      };
    }

    try {
      const response = await apiJson(CONFIG.exportEndpoint, {
        method: "POST",
        body: JSON.stringify(requestPayload)
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
        fallback_payload: requestPayload
      };
    }
  }

  function renderRows(target, rows, type) {
    if (!target) return;

    target.innerHTML = "";

    (rows || []).forEach(function (row) {
      const item = document.createElement("article");
      item.className = "ie-row";
      item.setAttribute("data-ie-row-type", type);
      item.setAttribute("data-ie-row-id", row.id);
      item.innerHTML = [
        "<div>",
        "<strong>" + row.id + "</strong>",
        "<p>" + row.domain + " / " + row.format + "</p>",
        "</div>",
        "<span class='pill'>" + row.status + "</span>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderMappingPreview(target, domain) {
    if (!target) return;

    const fields = CONFIG.fallbackSnapshot.mappingPreview[domain] || [];
    target.textContent = fields.join(", ");
    target.setAttribute("data-mapping-domain", domain);
  }

  async function bootImportExportScreen() {
    const jobs = await fetchJobs();
    const history = await fetchHistory();

    renderRows(document.getElementById("import-job-list"), jobs.jobs || [], "job");
    renderRows(document.getElementById("export-history-list"), history.history || [], "history");
    renderMappingPreview(document.getElementById("mapping-preview"), "CUSTOMERS");

    document.body.setAttribute("data-import-export-rendered", "true");
    return {
      jobs: jobs,
      history: history
    };
  }

  window.Pix2piImportExport = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getJwt: getJwt,
    tenantScopedHeaders: tenantScopedHeaders,
    readForm: readForm,
    validateDomain: validateDomain,
    validateImportFormat: validateImportFormat,
    validateExportFormat: validateExportFormat,
    validateImportPayload: validateImportPayload,
    validateExportPayload: validateExportPayload,
    buildTemplateRequestPayload: buildTemplateRequestPayload,
    buildImportValidationPayload: buildImportValidationPayload,
    buildImportStartPayload: buildImportStartPayload,
    buildExportPayload: buildExportPayload,
    fetchJobs: fetchJobs,
    fetchHistory: fetchHistory,
    requestTemplate: requestTemplate,
    validateImport: validateImport,
    startImport: startImport,
    startExport: startExport,
    renderRows: renderRows,
    renderMappingPreview: renderMappingPreview,
    bootImportExportScreen: bootImportExportScreen
  };
})();
/* PIX2PI_328_IMPORT_EXPORT_RUNTIME_END */
