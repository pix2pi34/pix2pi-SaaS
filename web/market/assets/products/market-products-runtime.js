/* PIX2PI_336_MARKET_PRODUCTS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_products",
    phase: "FAZ_7R",
    step: "336",
    productListingEndpoint: "/api/market/products/list",
    productFilterEndpoint: "/api/market/products/filter",
    productPreviewEndpoint: "/api/market/products/preview",
    selectedTenantKey: "pix2pi.market.tenant.preference",
    storeSlugKey: "pix2pi.market.store.slug",
    runtimeContract: {
      realBasketEnabled: false,
      realOrderEnabled: false,
      realPaymentEnabled: false,
      realStockReservationEnabled: false,
      productListingSnapshotEnabled: true,
      fallbackCatalogEnabled: true,
      readyForStep337: true
    },
    fallbackCatalog: {
      tenant_id: "controlled-pilot",
      store_slug: "demo-market",
      categories: [
        { id: "all", name: "Tümü" },
        { id: "food", name: "Temel gıda" },
        { id: "drink", name: "İçecek" },
        { id: "breakfast", name: "Kahvaltılık" },
        { id: "cleaning", name: "Temizlik" }
      ],
      brands: ["PixDemo", "Mahalle", "Taze", "Günlük"],
      products: [
        {
          id: "mkt-prd-001",
          name: "Demo Süt 1L",
          sku: "MKT-SUT-001",
          barcode: "869100000001",
          category_id: "breakfast",
          category_name: "Kahvaltılık",
          brand: "Taze",
          price: 35,
          vat_rate: 10,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          store_slug: "demo-market",
          image_placeholder: "🥛"
        },
        {
          id: "mkt-prd-002",
          name: "Demo Ekmek",
          sku: "MKT-EKMEK-001",
          barcode: "869100000002",
          category_id: "food",
          category_name: "Temel gıda",
          brand: "Günlük",
          price: 10,
          vat_rate: 1,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          store_slug: "demo-market",
          image_placeholder: "🥖"
        },
        {
          id: "mkt-prd-003",
          name: "Demo Peynir",
          sku: "MKT-PEYNIR-001",
          barcode: "869100000003",
          category_id: "breakfast",
          category_name: "Kahvaltılık",
          brand: "Mahalle",
          price: 95,
          vat_rate: 10,
          currency: "TRY",
          unit: "ADET",
          stock_status: "LIMITED",
          store_slug: "demo-market",
          image_placeholder: "🧀"
        },
        {
          id: "mkt-prd-004",
          name: "Demo Su 1.5L",
          sku: "MKT-SU-001",
          barcode: "869100000004",
          category_id: "drink",
          category_name: "İçecek",
          brand: "PixDemo",
          price: 12,
          vat_rate: 10,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          store_slug: "demo-market",
          image_placeholder: "💧"
        },
        {
          id: "mkt-prd-005",
          name: "Demo Deterjan",
          sku: "MKT-TEMIZLIK-001",
          barcode: "869100000005",
          category_id: "cleaning",
          category_name: "Temizlik",
          brand: "PixDemo",
          price: 125,
          vat_rate: 20,
          currency: "TRY",
          unit: "ADET",
          stock_status: "OUT_OF_STOCK",
          store_slug: "demo-market",
          image_placeholder: "🧴"
        }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackCatalog.tenant_id;
  }

  function getStoreSlug() {
    const params = new URLSearchParams(window.location.search);
    return params.get("store") || window.localStorage.getItem(CONFIG.storeSlugKey) || CONFIG.fallbackCatalog.store_slug;
  }

  function tenantStoreHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Store-Slug": getStoreSlug(),
      "X-Pix2pi-Surface": "marketplace",
      "X-Pix2pi-Step": "336"
    };
  }

  function normalizeTerm(value) {
    return String(value || "").trim().toLowerCase();
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

  function validateProductScope(product) {
    const errors = [];

    if (!product || !product.id) {
      errors.push({ field: "product.id", code: "PRODUCT_ID_REQUIRED" });
    }

    if (!product || !product.store_slug) {
      errors.push({ field: "store_slug", code: "STORE_SLUG_REQUIRED" });
    }

    if (!product || !product.sku) {
      errors.push({ field: "sku", code: "SKU_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: tenantStoreHeaders()
    });

    if (!response.ok) {
      throw new Error("MARKET_PRODUCT_LISTING_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchProductListingSnapshot() {
    const slug = getStoreSlug();

    try {
      return await apiJson(CONFIG.productListingEndpoint + "?store=" + encodeURIComponent(slug));
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackCatalog));
      snapshot.tenant_id = getTenantId();
      snapshot.store_slug = slug;
      snapshot.products = snapshot.products.map(function (product) {
        product.store_slug = slug;
        return product;
      });
      return snapshot;
    }
  }

  function readFilters(form) {
    const data = {};
    if (!form) return {
      search: "",
      category_id: "all",
      brand: "all",
      stock_status: "all",
      min_price: "",
      max_price: "",
      sort_by: "recommended"
    };

    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });

    return Object.assign({
      search: "",
      category_id: "all",
      brand: "all",
      stock_status: "all",
      min_price: "",
      max_price: "",
      sort_by: "recommended"
    }, data);
  }

  function applyProductFilters(products, filters) {
    const f = filters || {};
    const search = normalizeTerm(f.search);
    const minPrice = f.min_price === "" ? null : Number(f.min_price);
    const maxPrice = f.max_price === "" ? null : Number(f.max_price);

    let list = (products || []).filter(function (product) {
      const matchesSearch = !search ||
        normalizeTerm(product.name).indexOf(search) >= 0 ||
        normalizeTerm(product.sku).indexOf(search) >= 0 ||
        normalizeTerm(product.barcode).indexOf(search) >= 0;

      const matchesCategory = !f.category_id || f.category_id === "all" || product.category_id === f.category_id;
      const matchesBrand = !f.brand || f.brand === "all" || product.brand === f.brand;
      const matchesStock = !f.stock_status || f.stock_status === "all" || product.stock_status === f.stock_status;
      const matchesMin = minPrice === null || Number(product.price || 0) >= minPrice;
      const matchesMax = maxPrice === null || Number(product.price || 0) <= maxPrice;

      return matchesSearch && matchesCategory && matchesBrand && matchesStock && matchesMin && matchesMax;
    });

    list = sortProducts(list, f.sort_by || "recommended");

    return list;
  }

  function sortProducts(products, sortBy) {
    const list = (products || []).slice();

    switch (sortBy) {
      case "price_asc":
        return list.sort(function (a, b) { return Number(a.price || 0) - Number(b.price || 0); });
      case "price_desc":
        return list.sort(function (a, b) { return Number(b.price || 0) - Number(a.price || 0); });
      case "name_asc":
        return list.sort(function (a, b) { return String(a.name).localeCompare(String(b.name), "tr"); });
      case "stock_first":
        return list.sort(function (a, b) {
          const weight = { AVAILABLE: 0, LIMITED: 1, OUT_OF_STOCK: 2 };
          return (weight[a.stock_status] || 9) - (weight[b.stock_status] || 9);
        });
      default:
        return list;
    }
  }

  function buildProductListingContract(snapshot, filters, filteredProducts) {
    return {
      tenant_id: getTenantId(),
      store_slug: getStoreSlug(),
      total_product_count: Array.isArray(snapshot.products) ? snapshot.products.length : 0,
      visible_product_count: Array.isArray(filteredProducts) ? filteredProducts.length : 0,
      filters: filters,
      runtime_contract: CONFIG.runtimeContract,
      product_scope_valid: (filteredProducts || []).every(function (product) {
        return validateProductScope(product).valid;
      }),
      source: {
        surface: "market_products",
        phase: "FAZ_7R",
        step: "336"
      }
    };
  }

  function buildQuickPreviewPayload(product) {
    return {
      product_id: product.id,
      sku: product.sku,
      barcode: product.barcode,
      name: product.name,
      category_name: product.category_name,
      brand: product.brand,
      price_label: moneyTRY(product.price),
      vat_rate: product.vat_rate,
      stock_status: product.stock_status,
      real_basket_enabled: CONFIG.runtimeContract.realBasketEnabled,
      real_stock_reservation_enabled: CONFIG.runtimeContract.realStockReservationEnabled
    };
  }

  function renderStoreContext() {
    const tenant = document.getElementById("products-tenant");
    const store = document.getElementById("products-store-slug");

    if (tenant) tenant.textContent = getTenantId();
    if (store) store.textContent = getStoreSlug();
  }

  function renderCategoryOptions(snapshot) {
    const target = document.getElementById("product-category-filter");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.categories || []).forEach(function (category) {
      const option = document.createElement("option");
      option.value = category.id;
      option.textContent = category.name;
      target.appendChild(option);
    });
  }

  function renderBrandOptions(snapshot) {
    const target = document.getElementById("product-brand-filter");
    if (!target) return;

    target.innerHTML = "<option value='all'>Tüm markalar</option>";

    (snapshot.brands || []).forEach(function (brand) {
      const option = document.createElement("option");
      option.value = brand;
      option.textContent = brand;
      target.appendChild(option);
    });
  }

  function renderProductGrid(products) {
    const target = document.getElementById("market-product-grid");
    if (!target) return;

    target.innerHTML = "";

    (products || []).forEach(function (product) {
      const preview = buildQuickPreviewPayload(product);
      const card = document.createElement("article");
      card.className = "product-card";
      card.setAttribute("data-product-id", product.id);
      card.setAttribute("data-stock-status", product.stock_status);
      card.innerHTML = [
        "<span class='emoji'>" + product.image_placeholder + "</span>",
        "<span class='stock " + product.stock_status.toLowerCase() + "'>" + product.stock_status + "</span>",
        "<strong>" + product.name + "</strong>",
        "<p>" + product.category_name + " / " + product.brand + " / " + product.unit + "</p>",
        "<em>" + moneyTRY(product.price) + "</em>",
        "<small>KDV %" + product.vat_rate + " / SKU " + product.sku + "</small>",
        "<button type='button' data-preview-id='" + product.id + "'>Quick preview</button>",
        "<button type='button' disabled>Sepete ekleme 340 sonrası</button>"
      ].join("");

      card.querySelector("[data-preview-id]").addEventListener("click", function () {
        renderQuickPreview(preview);
      });

      target.appendChild(card);
    });
  }

  function renderQuickPreview(preview) {
    const target = document.getElementById("product-quick-preview");
    if (!target) return;

    target.innerHTML = [
      "<strong>" + preview.name + "</strong>",
      "<p>SKU: " + preview.sku + " / Barkod: " + preview.barcode + "</p>",
      "<p>Kategori: " + preview.category_name + " / Marka: " + preview.brand + "</p>",
      "<p>Fiyat: " + preview.price_label + " / KDV %" + preview.vat_rate + "</p>",
      "<p>Sepete ekle: disabled / Stok rezervasyon: disabled</p>"
    ].join("");
    target.setAttribute("data-preview-product-id", preview.product_id);
  }

  function renderListingSummary(contract) {
    const total = document.getElementById("products-total-count");
    const visible = document.getElementById("products-visible-count");
    const scope = document.getElementById("products-scope-validation");

    if (total) total.textContent = String(contract.total_product_count);
    if (visible) visible.textContent = String(contract.visible_product_count);
    if (scope) {
      scope.textContent = contract.product_scope_valid ? "VALID" : "INVALID";
      scope.setAttribute("data-validation-status", contract.product_scope_valid ? "valid" : "invalid");
    }
  }

  async function applyFiltersFromForm(form) {
    const snapshot = await fetchProductListingSnapshot();
    const filters = readFilters(form);
    const filtered = applyProductFilters(snapshot.products, filters);
    const contract = buildProductListingContract(snapshot, filters, filtered);

    renderProductGrid(filtered);
    renderListingSummary(contract);

    document.body.setAttribute("data-market-products-filtered", "true");
    return contract;
  }

  async function bootProductListingScreen() {
    const snapshot = await fetchProductListingSnapshot();
    const filters = readFilters(document.getElementById("product-filter-form"));
    const filtered = applyProductFilters(snapshot.products, filters);
    const contract = buildProductListingContract(snapshot, filters, filtered);

    renderStoreContext();
    renderCategoryOptions(snapshot);
    renderBrandOptions(snapshot);
    renderProductGrid(filtered);
    renderListingSummary(contract);

    document.body.setAttribute("data-market-products-rendered", "true");
    return contract;
  }

  window.Pix2piMarketProducts = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getStoreSlug: getStoreSlug,
    tenantStoreHeaders: tenantStoreHeaders,
    validateProductScope: validateProductScope,
    fetchProductListingSnapshot: fetchProductListingSnapshot,
    readFilters: readFilters,
    applyProductFilters: applyProductFilters,
    sortProducts: sortProducts,
    buildProductListingContract: buildProductListingContract,
    buildQuickPreviewPayload: buildQuickPreviewPayload,
    renderStoreContext: renderStoreContext,
    renderCategoryOptions: renderCategoryOptions,
    renderBrandOptions: renderBrandOptions,
    renderProductGrid: renderProductGrid,
    renderQuickPreview: renderQuickPreview,
    renderListingSummary: renderListingSummary,
    applyFiltersFromForm: applyFiltersFromForm,
    bootProductListingScreen: bootProductListingScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_336_MARKET_PRODUCTS_RUNTIME_END */
