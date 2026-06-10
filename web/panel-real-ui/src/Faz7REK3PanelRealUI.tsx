import React from "react";
import "./faz7r-ek3-panel-real-ui.css";

export default function Faz7REK3PanelRealUI() {
  const modules = [
    "Tenant yönetimi",
    "Kullanıcı / rol",
    "Ürün / stok",
    "POS erişim",
    "Marketplace",
    "Billing / entitlement",
    "Destek / incident",
    "Audit / evidence"
  ];

  return (
    <main
      className="pix2pi-panel"
      data-faz="FAZ_7R_EK3"
      data-marker="FAZ_7R_EK3_PANEL_REAL_UI_MARKER"
      data-react-app="PIX2PI_REAL_PANEL_REACT_APP"
    >
      <aside className="pix2pi-sidebar">
        <strong>Pix2pi Panel</strong>
        <span>Gerçek Panel UI</span>
        <nav>
          {modules.map((module) => (
            <a key={module} href="#">{module}</a>
          ))}
        </nav>
      </aside>

      <section className="pix2pi-workspace">
        <header className="pix2pi-topbar">
          <div>
            <p>FAZ 7-R / EK3</p>
            <h1>Gerçek Panel UI REAL FINAL</h1>
          </div>
          <div className="pix2pi-tenant-pill">pilot-tenant-001 · owner-admin</div>
        </header>

        <section className="pix2pi-grid">
          <article className="pix2pi-card">
            <p>Route</p>
            <h2>/panel-real-ui/</h2>
            <span>PANEL_ROUTE_BOUND_MARKER</span>
          </article>
          <article className="pix2pi-card">
            <p>Runtime</p>
            <h2>React + HTML</h2>
            <span>PIX2PI_REAL_PANEL_REACT_APP</span>
          </article>
          <article className="pix2pi-card">
            <p>i18n</p>
            <h2>TR · OTA · AR · FA · EN</h2>
            <span>I18N_TR_MARKER</span>
          </article>
          <article className="pix2pi-card">
            <p>RTL / e-Kalem</p>
            <h2 lang="ota-Arab" dir="rtl">حسرو قلمى آماده</h2>
            <span>HUSREV_EKALEM_RTL_MARKER</span>
          </article>
        </section>
      </section>
    </main>
  );
}
