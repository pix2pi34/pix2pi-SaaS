/* PIX2PI_326_DOCUMENTS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    listEndpoint: "/api/panel/documents",
    draftEndpoint: "/api/panel/documents/draft",
    actionEndpoint: "/api/panel/documents/action",
    exportEndpoint: "/api/panel/documents/export",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    draftStorageKey: "pix2pi.panel.documents.draft",
    documentTypes: ["E_INVOICE", "E_ARCHIVE", "E_ADISYON", "SALES_INVOICE", "PURCHASE_INVOICE"],
    documentStatuses: ["DRAFT", "READY_FOR_REVIEW", "APPROVED", "EXPORT_READY", "PROVIDER_CLOSED", "CANCELLED"],
    providerLiveGate: {
      gibLiveEnabled: false,
      privateIntegratorLiveEnabled: false,
      realSendEnabled: false
    },
    fallbackDocuments: [
      {
        id: "doc_demo_001",
        document_no: "INV-DEMO-001",
        document_type: "SALES_INVOICE",
        customer_name: "Demo Market Müşterisi",
        tax_number: "1111111111",
        status: "DRAFT",
        gross_total: 100,
        vat_total: 20,
        grand_total: 120,
        currency: "TRY"
      },
      {
        id: "doc_demo_002",
        document_no: "EARSIV-DEMO-001",
        document_type: "E_ARCHIVE",
        customer_name: "Demo Cari",
        tax_number: "2222222222",
        status: "PROVIDER_CLOSED",
        gross_total: 250,
        vat_total: 50,
        grand_total: 300,
        currency: "TRY"
      }
    ]
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
      "X-Pix2pi-Step": "326"
    };
  }

  function readForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });
    return data;
  }

  function toNumber(value) {
    const n = Number(value);
    return Number.isFinite(n) ? n : 0;
  }

  function validateDocumentType(value) {
    return CONFIG.documentTypes.indexOf(value) >= 0;
  }

  function validateVatRate(value) {
    const rate = toNumber(value);
    return [0, 1, 8, 10, 18, 20].indexOf(rate) >= 0;
  }

  function calculateLineTotals(payload) {
    const quantity = toNumber(payload.line_quantity || 1);
    const unitPrice = toNumber(payload.line_unit_price || 0);
    const vatRate = toNumber(payload.line_vat_rate || 20);
    const grossTotal = quantity * unitPrice;
    const vatTotal = grossTotal * vatRate / 100;
    const grandTotal = grossTotal + vatTotal;

    return {
      gross_total: grossTotal,
      vat_total: vatTotal,
      grand_total: grandTotal,
      currency: payload.currency || "TRY"
    };
  }

  function validateDocumentPayload(payload) {
    const errors = [];

    ["document_type", "customer_name", "tax_number", "line_product_name", "line_quantity", "line_unit_price", "line_vat_rate"].forEach(function (field) {
      if (!payload[field]) {
        errors.push({ field: field, code: "REQUIRED", message: field + " zorunludur" });
      }
    });

    if (payload.document_type && !validateDocumentType(payload.document_type)) {
      errors.push({ field: "document_type", code: "INVALID_DOCUMENT_TYPE", message: "Belge tipi geçersiz" });
    }

    if (payload.tax_number) {
      const normalized = String(payload.tax_number).replace(/\D/g, "");
      if (!(normalized.length === 10 || normalized.length === 11)) {
        errors.push({ field: "tax_number", code: "INVALID_TAX_NUMBER", message: "Vergi/TCKN numarası 10 veya 11 haneli olmalıdır" });
      }
    }

    if (payload.line_quantity && toNumber(payload.line_quantity) <= 0) {
      errors.push({ field: "line_quantity", code: "INVALID_QUANTITY", message: "Miktar sıfırdan büyük olmalıdır" });
    }

    if (payload.line_unit_price && toNumber(payload.line_unit_price) < 0) {
      errors.push({ field: "line_unit_price", code: "INVALID_PRICE", message: "Fiyat negatif olamaz" });
    }

    if (payload.line_vat_rate && !validateVatRate(payload.line_vat_rate)) {
      errors.push({ field: "line_vat_rate", code: "INVALID_VAT_RATE", message: "KDV oranı geçersiz" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  function buildDocumentPayload(payload) {
    const totals = calculateLineTotals(payload);

    return {
      tenant_id: getSelectedTenantId(),
      document: {
        document_type: payload.document_type,
        document_no: payload.document_no || "DRAFT-AUTO",
        status: "DRAFT",
        currency: payload.currency || "TRY"
      },
      customer: {
        name: payload.customer_name,
        tax_number: payload.tax_number,
        tax_office: payload.tax_office || "",
        address_line: payload.address_line || ""
      },
      lines: [
        {
          product_name: payload.line_product_name,
          quantity: toNumber(payload.line_quantity),
          unit_price: toNumber(payload.line_unit_price),
          vat_rate: toNumber(payload.line_vat_rate),
          gross_total: totals.gross_total,
          vat_total: totals.vat_total,
          grand_total: totals.grand_total
        }
      ],
      totals: totals,
      provider_gate: CONFIG.providerLiveGate,
      source: {
        surface: "panel_documents",
        phase: "FAZ_7R",
        step: "326"
      }
    };
  }

  function buildLifecycleActionPayload(documentId, action, reason) {
    return {
      tenant_id: getSelectedTenantId(),
      document_id: documentId,
      action: action,
      reason: reason || "",
      provider_live_gate: CONFIG.providerLiveGate,
      real_send_enabled: false,
      source: "panel_documents",
      step: "326"
    };
  }

  function buildExportPayload(documentId, format) {
    return {
      tenant_id: getSelectedTenantId(),
      document_id: documentId,
      format: format || "PDF",
      allowed_formats: ["PDF", "XML", "JSON", "ACCOUNTING_EXPORT"],
      source: "panel_documents",
      step: "326"
    };
  }

  function saveDraft(payload) {
    const documentPayload = buildDocumentPayload(payload);
    window.localStorage.setItem(CONFIG.draftStorageKey, JSON.stringify(documentPayload));
    return documentPayload;
  }

  function loadDraft() {
    const raw = window.localStorage.getItem(CONFIG.draftStorageKey);
    if (!raw) return null;

    try {
      return JSON.parse(raw);
    } catch (_error) {
      return null;
    }
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("DOCUMENTS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchDocuments() {
    try {
      return await apiJson(CONFIG.listEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        documents: CONFIG.fallbackDocuments,
        summary: buildDocumentSummary(CONFIG.fallbackDocuments)
      };
    }
  }

  async function saveDocumentDraft(payload) {
    const validation = validateDocumentPayload(payload);
    if (!validation.valid) {
      return { saved: false, validation: validation };
    }

    const documentPayload = saveDraft(payload);

    try {
      const response = await apiJson(CONFIG.draftEndpoint, {
        method: "POST",
        body: JSON.stringify(documentPayload)
      });

      return { saved: true, validation: validation, response: response };
    } catch (_error) {
      return { saved: false, validation: validation, fallback_payload: documentPayload };
    }
  }

  async function submitLifecycleAction(documentId, action, reason) {
    const payload = buildLifecycleActionPayload(documentId, action, reason);

    if (action === "SEND_TO_PROVIDER" && !CONFIG.providerLiveGate.realSendEnabled) {
      return {
        submitted: false,
        blocked_by_provider_gate: true,
        payload: payload
      };
    }

    try {
      return await apiJson(CONFIG.actionEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  async function requestDocumentExport(documentId, format) {
    const payload = buildExportPayload(documentId, format);

    try {
      return await apiJson(CONFIG.exportEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  function buildDocumentSummary(documents) {
    const list = documents || [];
    const total = list.reduce(function (sum, doc) {
      return sum + toNumber(doc.grand_total);
    }, 0);

    return {
      document_count: list.length,
      grand_total: total,
      provider_closed_count: list.filter(function (doc) { return doc.status === "PROVIDER_CLOSED"; }).length,
      currency: "TRY"
    };
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

  function renderDocuments(target, documents) {
    if (!target) return;

    target.innerHTML = "";

    (documents || []).forEach(function (doc) {
      const row = document.createElement("article");
      row.className = "document-row";
      row.setAttribute("data-document-id", doc.id);
      row.setAttribute("data-document-type", doc.document_type);
      row.setAttribute("data-document-status", doc.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + doc.document_no + "</strong>",
        "<p>" + doc.document_type + " / " + doc.customer_name + "</p>",
        "<p>" + doc.tax_number + "</p>",
        "</div>",
        "<span class='pill'>" + doc.document_type + "</span>",
        "<span class='pill' data-status='" + doc.status + "'>" + doc.status + "</span>",
        "<strong>" + moneyTRY(doc.grand_total) + "</strong>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderDocumentSummary(target, summary) {
    if (!target) return;
    target.textContent = "Belge sayısı: " + summary.document_count + " / Toplam: " + moneyTRY(summary.grand_total) + " / Provider kapalı: " + summary.provider_closed_count;
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Fatura/belge formu geçerli.";
      target.setAttribute("data-validation-status", "valid");
      target.hidden = false;
      return;
    }

    target.textContent = validation.errors.map(function (err) {
      return err.message;
    }).join(" / ");
    target.setAttribute("data-validation-status", "invalid");
    target.hidden = false;
  }

  function renderTotalsFromForm(form, target) {
    if (!form || !target) return;

    const payload = {};
    new FormData(form).forEach(function (value, key) {
      payload[key] = String(value || "").trim();
    });

    const totals = calculateLineTotals(payload);
    target.textContent = "Ara toplam: " + moneyTRY(totals.gross_total) + " / KDV: " + moneyTRY(totals.vat_total) + " / Genel toplam: " + moneyTRY(totals.grand_total);
  }

  async function bootDocumentsScreen() {
    const result = await fetchDocuments();
    const documents = result.documents || [];
    renderDocuments(document.getElementById("documents-list"), documents);
    renderDocumentSummary(document.getElementById("documents-summary"), result.summary || buildDocumentSummary(documents));
    document.body.setAttribute("data-documents-rendered", "true");
    return result;
  }

  window.Pix2piDocuments = {
    CONFIG: CONFIG,
    getSelectedTenantId: getSelectedTenantId,
    getJwt: getJwt,
    tenantScopedHeaders: tenantScopedHeaders,
    readForm: readForm,
    validateDocumentType: validateDocumentType,
    validateVatRate: validateVatRate,
    calculateLineTotals: calculateLineTotals,
    validateDocumentPayload: validateDocumentPayload,
    buildDocumentPayload: buildDocumentPayload,
    buildLifecycleActionPayload: buildLifecycleActionPayload,
    buildExportPayload: buildExportPayload,
    saveDraft: saveDraft,
    loadDraft: loadDraft,
    fetchDocuments: fetchDocuments,
    saveDocumentDraft: saveDocumentDraft,
    submitLifecycleAction: submitLifecycleAction,
    requestDocumentExport: requestDocumentExport,
    buildDocumentSummary: buildDocumentSummary,
    renderDocuments: renderDocuments,
    renderDocumentSummary: renderDocumentSummary,
    renderValidation: renderValidation,
    renderTotalsFromForm: renderTotalsFromForm,
    bootDocumentsScreen: bootDocumentsScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_326_DOCUMENTS_RUNTIME_END */
