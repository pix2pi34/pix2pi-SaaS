/* PIX2PI_319_347_REAL_DB_API_FRONTEND_BIND_START */
(function () {
  const endpoint = "/api/panel/onboarding/tenant-opening";

  function byName(name) {
    return document.querySelector("[name='" + name + "']");
  }

  function value(name) {
    const el = byName(name);
    return el ? String(el.value || "").trim() : "";
  }

  function payload() {
    return {
      tenant_slug: value("tenantSlug"),
      business_name: value("businessName"),
      tax_identity: value("taxIdentity"),
      address_line: value("addressLine"),
      city: value("city"),
      country: "TR",
      sector: value("sector"),
      branch_name: value("branchName"),
      default_currency: value("defaultCurrency"),
      default_language: value("defaultLanguage"),
      initial_role: value("initialRole"),
      default_plan: value("defaultPlan"),
      register_code: value("registerCode"),
      register_name: "Merkez Kasa",
      owner_user_id: "user-owner-preview",
      requested_by_user_id: "user-owner-preview",
      opened_by_user_id: "platform-admin-preview",
      tenant_domain: "panel.pix2pi.com.tr",
      environment: "pilot",
      default_timezone: "Europe/Istanbul",
      correlation_id: "corr-web-onboarding"
    };
  }

  function setStatus(message, ok) {
    const el = document.querySelector("[data-onboarding-status]");
    if (!el) return;
    el.textContent = message;
    el.dataset.status = ok ? "ok" : "error";
  }

  function setPreview(data) {
    const el = document.querySelector("[data-onboarding-payload]");
    if (el) el.textContent = JSON.stringify(data, null, 2);
  }

  async function submitReal(event) {
    event.preventDefault();

    const body = payload();
    setPreview(body);
    setStatus("İşletme kaydı gönderiliyor...", true);

    try {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(body)
      });

      const json = await res.json();
      setPreview(json);

      if (res.status === 201 && json.ok && json.next_url) {
        setStatus("İşletme oluşturuldu. Kullanıcı davetine geçiliyor.", true);
        window.setTimeout(function () {
          window.location.href = json.next_url;
        }, 700);
        return;
      }

      setStatus("Kayıt başarısız: " + (json.error || res.status), false);
    } catch (err) {
      setStatus("API bağlantı hatası: " + err.message, false);
    }
  }

  window.PIX2PI_319_347_REAL_DB_API = { endpoint, payload };

  document.addEventListener("submit", function (event) {
    const form = event.target;
    if (!form || !form.matches("[data-onboarding-form]")) return;
    submitReal(event);
  });
})();
/* PIX2PI_319_347_REAL_DB_API_FRONTEND_BIND_END */
