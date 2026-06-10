/* PIX2PI_324_PRODUCTS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    listEndpoint: "/api/panel/products",
    saveEndpoint: "/api/panel/products/save",
    stockEndpoint: "/api/panel/products/stock",
    statusEndpoint: "/api/panel/products/status",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    draftStorageKey: "pix2pi.panel.products.draft",
    statuses: ["ACTIVE", "PASSIVE"],
    requiredFields: [
      "product_name",
      "sku",
      "unit",
      "vat_rate",
      "sale_price",
      "stock_quantity",
      "warehouse"
    ],
    fallbackProducts: [
      {
        id: "prd_demo_001",
        name: "Demo Ürün",
        sku: "SKU-DEMO-001",
        barcode: "869000000001",
        product_code: "P-001",
        category: "Genel",
        brand: "Pix2pi",
        unit: "ADET",
        vat_rate: 20,
        sale_price: 100,
        purchase_price: 70,
        stock_quantity: 12,
        critical_stock: 5,
        warehouse: "Ana Depo",
        status: "ACTIVE"
      },
      {
        id: "prd_demo_002",
        name: "Oto Yedek Parça Demo",
        sku: "SKU-PART-001",
        barcode: "",
        product_code: "OEM-DEMO-001",
        category: "Oto Yedek Parça",
        brand: "Demo",
        unit: "ADET",
        vat_rate: 20,
        sale_price: 450,
        purchase_price: 300,
        stock_quantity: 3,
        critical_stock: 2,
        warehouse: "Ana Depo",
        status: "ACTIVE",
        vehicle_compatibility_note: "Megane / Clio uyumluluk placeholder"
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
      "X-Pix2pi-Step": "324"
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

  function validateVatRate(value) {
    const rate = toNumber(value);
    return [0, 1, 8, 10, 18, 20].indexOf(rate) >= 0;
  }

  function validatePositiveOrZero(value) {
    return toNumber(value) >= 0;
  }

  function validateProductPayload(payload) {
    const errors = [];

    CONFIG.requiredFields.forEach(function (field) {
      if (!payload[field]) {
        errors.push({ field, code: "REQUIRED", message: field + " zorunludur" });
      }
    });

    if (payload.vat_rate && !validateVatRate(payload.vat_rate)) {
      errors.push({ field: "vat_rate", code: "INVALID_VAT_RATE", message: "KDV oranı geçersiz" });
    }

    if (payload.sale_price && !validatePositiveOrZero(payload.sale_price)) {
      errors.push({ field: "sale_price", code: "INVALID_SALE_PRICE", message: "Satış fiyatı negatif olamaz" });
    }

    if (payload.purchase_price && !validatePositiveOrZero(payload.purchase_price)) {
      errors.push({ field: "purchase_price", code: "INVALID_PURCHASE_PRICE", message: "Alış fiyatı negatif olamaz" });
    }

    if (payload.stock_quantity && !validatePositiveOrZero(payload.stock_quantity)) {
      errors.push({ field: "stock_quantity", code: "INVALID_STOCK_QUANTITY", message: "Stok miktarı negatif olamaz" });
    }

    if (payload.critical_stock && !validatePositiveOrZero(payload.critical_stock)) {
      errors.push({ field: "critical_stock", code: "INVALID_CRITICAL_STOCK", message: "Kritik stok negatif olamaz" });
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  function buildProductPayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      product: {
        name: payload.product_name,
        sku: payload.sku,
        barcode: payload.barcode || "",
        product_code: payload.product_code || "",
        category: payload.category || "",
        brand: payload.brand || "",
        unit: payload.unit,
        status: payload.status || "ACTIVE"
      },
      pricing: {
        vat_rate: toNumber(payload.vat_rate),
        sale_price: toNumber(payload.sale_price),
        purchase_price: toNumber(payload.purchase_price || 0),
        currency: payload.currency || "TRY"
      },
      stock: {
        stock_quantity: toNumber(payload.stock_quantity),
        critical_stock: toNumber(payload.critical_stock || 0),
        warehouse: payload.warehouse
      },
      compatibility: {
        vehicle_compatibility_note: payload.vehicle_compatibility_note || "",
        auto_spare_part_placeholder: true
      },
      source: {
        surface: "panel_products",
        phase: "FAZ_7R",
        step: "324"
      }
    };
  }

  function buildStockPayload(productId, quantity, warehouse) {
    return {
      tenant_id: getSelectedTenantId(),
      product_id: productId,
      quantity: toNumber(quantity),
      warehouse: warehouse || "Ana Depo",
      source: "panel_products",
      step: "324"
    };
  }

  function buildStatusPayload(productId, status) {
    return {
      tenant_id: getSelectedTenantId(),
      product_id: productId,
      status,
      source: "panel_products",
      step: "324"
    };
  }

  function saveDraft(payload) {
    const productPayload = buildProductPayload(payload);
    window.localStorage.setItem(CONFIG.draftStorageKey, JSON.stringify(productPayload));
    return productPayload;
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
      throw new Error("PRODUCTS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchProducts() {
    try {
      return await apiJson(CONFIG.listEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        products: CONFIG.fallbackProducts,
        summary: buildStockSummary(CONFIG.fallbackProducts)
      };
    }
  }

  async function saveProduct(payload) {
    const validation = validateProductPayload(payload);
    if (!validation.valid) {
      return { saved: false, validation };
    }

    const productPayload = saveDraft(payload);

    try {
      const response = await apiJson(CONFIG.saveEndpoint, {
        method: "POST",
        body: JSON.stringify(productPayload)
      });

      return { saved: true, validation, response };
    } catch (_error) {
      return { saved: false, validation, fallback_payload: productPayload };
    }
  }

  async function updateStock(productId, quantity, warehouse) {
    const payload = buildStockPayload(productId, quantity, warehouse);

    try {
      return await apiJson(CONFIG.stockEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  async function updateProductStatus(productId, status) {
    const payload = buildStatusPayload(productId, status);

    try {
      return await apiJson(CONFIG.statusEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  function buildStockSummary(products) {
    const list = products || [];
    const totalStock = list.reduce(function (sum, product) {
      return sum + toNumber(product.stock_quantity);
    }, 0);

    const criticalCount = list.filter(function (product) {
      return toNumber(product.stock_quantity) <= toNumber(product.critical_stock);
    }).length;

    return {
      product_count: list.length,
      total_stock: totalStock,
      critical_stock_count: criticalCount
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

  function renderProducts(target, products) {
    if (!target) return;

    target.innerHTML = "";

    (products || []).forEach(function (product) {
      const row = document.createElement("article");
      row.className = "product-row";
      row.setAttribute("data-product-id", product.id);
      row.setAttribute("data-product-sku", product.sku);
      row.setAttribute("data-product-status", product.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + product.name + "</strong>",
        "<p>SKU: " + product.sku + " / Barkod: " + (product.barcode || "-") + "</p>",
        "<p>" + (product.category || "-") + " / " + (product.brand || "-") + " / " + product.unit + "</p>",
        "</div>",
        "<span class='pill'>" + product.warehouse + "</span>",
        "<span class='pill' data-status='" + product.status + "'>" + product.status + "</span>",
        "<strong>" + product.stock_quantity + " " + product.unit + "</strong>",
        "<strong>" + moneyTRY(product.sale_price) + "</strong>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderStockSummary(target, summary) {
    if (!target) return;
    target.textContent = "Ürün sayısı: " + summary.product_count + " / Toplam stok: " + summary.total_stock + " / Kritik stok: " + summary.critical_stock_count;
  }

  function renderValidation(target, validation) {
    if (!target) return;

    if (validation.valid) {
      target.textContent = "Ürün/stok formu geçerli.";
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

  async function bootProductsScreen() {
    const result = await fetchProducts();
    const products = result.products || [];
    renderProducts(document.getElementById("products-list"), products);
    renderStockSummary(document.getElementById("products-stock-summary"), result.summary || buildStockSummary(products));
    document.body.setAttribute("data-products-rendered", "true");
    return result;
  }

  window.Pix2piProducts = {
    CONFIG,
    getSelectedTenantId,
    getJwt,
    tenantScopedHeaders,
    readForm,
    validateVatRate,
    validatePositiveOrZero,
    validateProductPayload,
    buildProductPayload,
    buildStockPayload,
    buildStatusPayload,
    saveDraft,
    loadDraft,
    fetchProducts,
    saveProduct,
    updateStock,
    updateProductStatus,
    buildStockSummary,
    renderProducts,
    renderStockSummary,
    renderValidation,
    bootProductsScreen
  };
})();
/* PIX2PI_324_PRODUCTS_RUNTIME_END */
