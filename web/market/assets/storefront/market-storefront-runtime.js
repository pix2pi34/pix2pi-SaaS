/* PIX2PI_335_MARKET_STOREFRONT_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_storefront",
    phase: "FAZ_7R",
    step: "335",
    storefrontSnapshotEndpoint: "/api/market/storefront/snapshot",
    storeStatusEndpoint: "/api/market/storefront/status",
    productPreviewEndpoint: "/api/market/products/preview",
    selectedTenantKey: "pix2pi.market.tenant.preference",
    storeSlugKey: "pix2pi.market.store.slug",
    runtimeContract: {
      realOrderEnabled: false,
      realPaymentEnabled: false,
      realStockReservationEnabled: false,
      storefrontSnapshotEnabled: true,
      fallbackSnapshotEnabled: true,
      readyForStep336: true
    },
    fallbackSnapshot: {
      tenant_id: "controlled-pilot",
      store_slug: "demo-market",
      business: {
        name: "Demo Market",
        tagline: "Mahalle marketi vitrini",
        city: "İstanbul",
        district: "Pilot",
        rating: 4.8,
        review_count: 128,
        status: "OPEN",
        working_hours: "09:00 - 22:00"
      },
      fulfillment: {
        delivery_enabled: true,
        pickup_enabled: true,
        minimum_basket_amount: 150,
        estimated_delivery_minutes: 35
      },
      campaigns: [
        {
          id: "cmp-001",
          title: "Pilot açılış kampanyası",
          description: "Seçili ürünlerde vitrinde demo indirim etiketi."
        }
      ],
      categories: [
        { id: "cat-001", name: "Temel gıda", product_count: 42 },
        { id: "cat-002", name: "İçecek", product_count: 28 },
        { id: "cat-003", name: "Kahvaltılık", product_count: 18 },
        { id: "cat-004", name: "Temizlik", product_count: 23 }
      ],
      featured_products: [
        {
          id: "prd-001",
          name: "Demo Süt 1L",
          sku: "MKT-SUT-001",
          price: 35,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          campaign_label: "Vitrin"
        },
        {
          id: "prd-002",
          name: "Demo Ekmek",
          sku: "MKT-EKMEK-001",
          price: 10,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          campaign_label: "Günlük"
        },
        {
          id: "prd-003",
          name: "Demo Peynir",
          sku: "MKT-PEYNIR-001",
          price: 95,
          currency: "TRY",
          unit: "ADET",
          stock_status: "LIMITED",
          campaign_label: "Az kaldı"
        },
        {
          id: "prd-004",
          name: "Demo Su 1.5L",
          sku: "MKT-SU-001",
          price: 12,
          currency: "TRY",
          unit: "ADET",
          stock_status: "AVAILABLE",
          campaign_label: "Hızlı"
        }
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackSnapshot.tenant_id;
  }

  function getStoreSlug() {
    const params = new URLSearchParams(window.location.search);
    return params.get("store") || window.localStorage.getItem(CONFIG.storeSlugKey) || CONFIG.fallbackSnapshot.store_slug;
  }

  function tenantStoreHeaders() {
    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Store-Slug": getStoreSlug(),
      "X-Pix2pi-Surface": "marketplace",
      "X-Pix2pi-Step": "335"
    };
  }

  function validateStorefrontScope(snapshot) {
    const errors = [];

    if (!snapshot || !snapshot.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!snapshot || !snapshot.store_slug) {
      errors.push({ field: "store_slug", code: "STORE_SLUG_REQUIRED" });
    }

    if (!snapshot || !snapshot.business || !snapshot.business.name) {
      errors.push({ field: "business.name", code: "BUSINESS_NAME_REQUIRED" });
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
      throw new Error("MARKET_STOREFRONT_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchStorefrontSnapshot() {
    const slug = getStoreSlug();

    try {
      return await apiJson(CONFIG.storefrontSnapshotEndpoint + "?store=" + encodeURIComponent(slug));
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackSnapshot));
      snapshot.tenant_id = getTenantId();
      snapshot.store_slug = slug;
      return snapshot;
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

  function buildStorefrontSnapshotContract(snapshot) {
    const data = snapshot || CONFIG.fallbackSnapshot;
    return {
      tenant_id: data.tenant_id,
      store_slug: data.store_slug,
      business_name: data.business.name,
      category_count: Array.isArray(data.categories) ? data.categories.length : 0,
      featured_product_count: Array.isArray(data.featured_products) ? data.featured_products.length : 0,
      fulfillment: data.fulfillment,
      runtime_contract: CONFIG.runtimeContract,
      validation: validateStorefrontScope(data),
      source: {
        surface: "market_storefront",
        phase: "FAZ_7R",
        step: "335"
      }
    };
  }

  function buildProductCardData(product) {
    return {
      id: product.id,
      name: product.name,
      sku: product.sku,
      price_label: moneyTRY(product.price),
      unit: product.unit,
      stock_status: product.stock_status,
      campaign_label: product.campaign_label,
      order_enabled: CONFIG.runtimeContract.realOrderEnabled,
      stock_reservation_enabled: CONFIG.runtimeContract.realStockReservationEnabled
    };
  }

  function renderBusinessHero(snapshot) {
    const name = document.getElementById("storefront-business-name");
    const tagline = document.getElementById("storefront-business-tagline");
    const location = document.getElementById("storefront-business-location");
    const rating = document.getElementById("storefront-business-rating");

    if (name) name.textContent = snapshot.business.name;
    if (tagline) tagline.textContent = snapshot.business.tagline;
    if (location) location.textContent = snapshot.business.city + " / " + snapshot.business.district;
    if (rating) rating.textContent = "★ " + snapshot.business.rating + " (" + snapshot.business.review_count + ")";
  }

  function renderStoreStatus(snapshot) {
    const status = document.getElementById("storefront-status");
    const hours = document.getElementById("storefront-working-hours");

    if (status) {
      status.textContent = snapshot.business.status;
      status.setAttribute("data-store-status", snapshot.business.status);
    }

    if (hours) hours.textContent = snapshot.business.working_hours;
  }

  function renderCampaigns(snapshot) {
    const target = document.getElementById("storefront-campaign-banner");
    if (!target) return;

    const campaign = Array.isArray(snapshot.campaigns) && snapshot.campaigns.length > 0 ? snapshot.campaigns[0] : null;

    if (!campaign) {
      target.textContent = "Aktif kampanya yok.";
      return;
    }

    target.innerHTML = "<strong>" + campaign.title + "</strong><p>" + campaign.description + "</p>";
  }

  function renderCategories(snapshot) {
    const target = document.getElementById("storefront-category-list");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.categories || []).forEach(function (category) {
      const item = document.createElement("article");
      item.className = "category-card";
      item.setAttribute("data-category-id", category.id);
      item.innerHTML = [
        "<strong>" + category.name + "</strong>",
        "<span>" + category.product_count + " ürün</span>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderProducts(snapshot) {
    const target = document.getElementById("storefront-featured-products");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.featured_products || []).forEach(function (product) {
      const card = buildProductCardData(product);
      const item = document.createElement("article");
      item.className = "product-card";
      item.setAttribute("data-product-id", card.id);
      item.setAttribute("data-stock-status", card.stock_status);
      item.innerHTML = [
        "<span class='product-badge'>" + card.campaign_label + "</span>",
        "<strong>" + card.name + "</strong>",
        "<p>" + card.sku + " / " + card.unit + "</p>",
        "<em>" + card.price_label + "</em>",
        "<button type='button' disabled>Sepete ekleme 340 sonrası</button>"
      ].join("");
      target.appendChild(item);
    });
  }

  function renderFulfillment(snapshot) {
    const delivery = document.getElementById("storefront-delivery-status");
    const pickup = document.getElementById("storefront-pickup-status");
    const minBasket = document.getElementById("storefront-min-basket");
    const eta = document.getElementById("storefront-delivery-eta");

    if (delivery) delivery.textContent = snapshot.fulfillment.delivery_enabled ? "Teslimat hazır" : "Teslimat kapalı";
    if (pickup) pickup.textContent = snapshot.fulfillment.pickup_enabled ? "Gel-al hazır" : "Gel-al kapalı";
    if (minBasket) minBasket.textContent = moneyTRY(snapshot.fulfillment.minimum_basket_amount);
    if (eta) eta.textContent = snapshot.fulfillment.estimated_delivery_minutes + " dk";
  }

  function renderScope(snapshot) {
    const tenant = document.getElementById("storefront-tenant");
    const slug = document.getElementById("storefront-slug");
    const validation = document.getElementById("storefront-scope-validation");
    const contract = buildStorefrontSnapshotContract(snapshot);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (slug) slug.textContent = contract.store_slug;
    if (validation) {
      validation.textContent = contract.validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.validation.valid ? "valid" : "invalid");
    }
  }

  function renderSEO(snapshot) {
    document.title = snapshot.business.name + " | Pix2pi Market";
    const description = document.querySelector("meta[name='description']");
    if (description) {
      description.setAttribute("content", snapshot.business.name + " mağaza vitrini - Pix2pi Market");
    }
  }

  async function bootStorefrontScreen() {
    const snapshot = await fetchStorefrontSnapshot();

    renderSEO(snapshot);
    renderBusinessHero(snapshot);
    renderStoreStatus(snapshot);
    renderCampaigns(snapshot);
    renderCategories(snapshot);
    renderProducts(snapshot);
    renderFulfillment(snapshot);
    renderScope(snapshot);

    document.body.setAttribute("data-market-storefront-rendered", "true");
    return buildStorefrontSnapshotContract(snapshot);
  }

  window.Pix2piMarketStorefront = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getStoreSlug: getStoreSlug,
    tenantStoreHeaders: tenantStoreHeaders,
    validateStorefrontScope: validateStorefrontScope,
    fetchStorefrontSnapshot: fetchStorefrontSnapshot,
    buildStorefrontSnapshotContract: buildStorefrontSnapshotContract,
    buildProductCardData: buildProductCardData,
    renderBusinessHero: renderBusinessHero,
    renderStoreStatus: renderStoreStatus,
    renderCampaigns: renderCampaigns,
    renderCategories: renderCategories,
    renderProducts: renderProducts,
    renderFulfillment: renderFulfillment,
    renderScope: renderScope,
    renderSEO: renderSEO,
    bootStorefrontScreen: bootStorefrontScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_335_MARKET_STOREFRONT_RUNTIME_END */
