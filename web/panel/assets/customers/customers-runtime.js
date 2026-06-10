/* PIX2PI_323_CUSTOMERS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    listEndpoint: "/api/panel/customers",
    saveEndpoint: "/api/panel/customers/save",
    statusEndpoint: "/api/panel/customers/status",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    draftStorageKey: "pix2pi.panel.customers.draft",
    customerTypes: ["CUSTOMER", "SUPPLIER", "BOTH"],
    statuses: ["ACTIVE", "PASSIVE"],
    requiredFields: [
      "customer_name",
      "customer_type",
      "tax_number",
      "tax_office",
      "city",
      "district",
      "address_line"
    ],
    fallbackCustomers: [
      {
        id: "cari_demo_001",
        name: "Demo Market Müşterisi",
        type: "CUSTOMER",
        tax_number: "1111111111",
        tax_office: "Pilot Vergi Dairesi",
        phone: "+90",
        email: "cari@pix2pi.test",
        city: "İstanbul",
        district: "Kadıköy",
        address_line: "Pilot adres",
        balance: 0,
        status: "ACTIVE"
      },
      {
        id: "cari_demo_002",
        name: "Demo Tedarikçi",
        type: "SUPPLIER",
        tax_number: "2222222222",
        tax_office: "Pilot Vergi Dairesi",
        phone: "",
        email: "",
        city: "İstanbul",
        district: "Üsküdar",
        address_line: "Pilot tedarikçi adresi",
        balance: 0,
        status: "ACTIVE"
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
      "X-Pix2pi-Step": "323"
    };
  }

  function readForm(form) {
    const data = {};
    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });
    return data;
  }

  function validateTaxNumber(value) {
    const normalized = String(value || "").replace(/\D/g, "");
    return normalized.length === 10 || normalized.length === 11;
  }

  function validateEmail(value) {
    if (!value) return true;
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || ""));
  }

  function validateCustomerPayload(payload) {
    const errors = [];

    CONFIG.requiredFields.forEach(function (field) {
      if (!payload[field]) {
        errors.push({ field, code: "REQUIRED", message: field + " zorunludur" });
      }
    });

    if (payload.customer_type && CONFIG.customerTypes.indexOf(payload.customer_type) === -1) {
      errors.push({ field: "customer_type", code: "INVALID_CUSTOMER_TYPE", message: "Cari tipi geçersiz" });
    }

    if (payload.tax_number && !validateTaxNumber(payload.tax_number)) {
      errors.push({ field: "tax_number", code: "INVALID_TAX_NUMBER", message: "Vergi/TCKN numarası 10 veya 11 haneli olmalıdır" });
    }

    if (payload.email && !validateEmail(payload.email)) {
      errors.push({ field: "email", code: "INVALID_EMAIL", message: "E-posta formatı hatalı" });
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  function buildCustomerPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      customer: {
        name: payload.customer_name,
        type: payload.customer_type,
        tax_number: payload.tax_number,
        tax_office: payload.tax_office,
        mersis_no: payload.mersis_no || "",
        phone: payload.phone || "",
        email: payload.email || "",
        city: payload.city,
        district: payload.district,
        address_line: payload.address_line,
        status: payload.status || "ACTIVE"
      },
      accounting: {
        opening_balance: Number(payload.opening_balance || 0),
        currency: payload.currency || "TRY"
      },
      source: {
        surface: "panel_customers",
        phase: "FAZ_7R",
        step: "323"
      }
    };
  }

  function buildStatusPayload(customerId, status) {
    return {
      tenant_id: getSelectedTenantId(),
      customer_id: customerId,
      status,
      source: "panel_customers",
      step: "323"
    };
  }

  function saveDraft(payload) {
    const customerPayload = buildCustomerPayload(payload);
    window.localStorage.setItem(CONFIG.draftStorageKey, JSON.stringify(customerPayload));
    return customerPayload;
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
      throw new Error("CUSTOMERS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchCustomers() {
    try {
      return await apiJson(CONFIG.listEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        customers: CONFIG.fallbackCustomers,
        summary: buildBalanceSummary(CONFIG.fallbackCustomers)
      };
    }
  }

  async function saveCustomer(payload) {
    const validation = validateCustomerPayload(payload);
    if (!validation.valid) {
      return { saved: false, validation };
    }

    const customerPayload = saveDraft(payload);

    try {
      const response = await apiJson(CONFIG.saveEndpoint, {
        method: "POST",
        body: JSON.stringify(customerPayload)
      });

      return { saved: true, validation, response };
    } catch (_error) {
      return { saved: false, validation, fallback_payload: customerPayload };
    }
  }

  async function updateCustomerStatus(customerId, status) {
    const payload = buildStatusPayload(customerId, status);

    try {
      return await apiJson(CONFIG.statusEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  function buildBalanceSummary(customers) {
    const total = (customers || []).reduce(function (sum, customer) {
      return sum + Number(customer.balance || 0);
    }, 0);

    return {
      customer_count: (customers || []).length,
      total_balance: total,
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

  function renderCustomers(target, customers) {
    if (!target) return;

    target.innerHTML = "";

    (customers || []).forEach(function (customer) {
      const row = document.createElement("article");
      row.className = "customer-row";
      row.setAttribute("data-customer-id", customer.id);
      row.setAttribute("data-customer-type", customer.type);
      row.setAttribute("data-customer-status", customer.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + customer.name + "</strong>",
        "<p>" + customer.tax_number + " / " + customer.tax_office + "</p>",
        "<p>" + customer.city + " / " + customer.district + "</p>",
        "</div>",
        "<span class='pill'>" + customer.type + "</span>",
        "<span class='pill' data-status='" + customer.status + "'>" + customer.status + "</span>",
        "<strong>" + moneyTRY(customer.balance) + "</strong>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderBalanceSummary(target, summary) {
    if (!target) return;
    target.textContent = "Cari sayısı: " + summary.customer_count + " / Toplam bakiye: " + moneyTRY(summary.total_balance);
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Cari formu geçerli.";
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

  async function bootCustomersScreen() {
    const result = await fetchCustomers();
    const customers = result.customers || [];
    renderCustomers(document.getElementById("customers-list"), customers);
    renderBalanceSummary(document.getElementById("customers-balance-summary"), result.summary || buildBalanceSummary(customers));
    document.body.setAttribute("data-customers-rendered", "true");
    return result;
  }

  window.Pix2piCustomers = {
    CONFIG,
    getSelectedTenantId,
    getJwt,
    tenantScopedHeaders,
    readForm,
    validateTaxNumber,
    validateEmail,
    validateCustomerPayload,
    buildCustomerPayload,
    buildStatusPayload,
    saveDraft,
    loadDraft,
    fetchCustomers,
    saveCustomer,
    updateCustomerStatus,
    buildBalanceSummary,
    renderCustomers,
    renderBalanceSummary,
    renderValidation,
    bootCustomersScreen
  };
})();
/* PIX2PI_323_CUSTOMERS_RUNTIME_END */
