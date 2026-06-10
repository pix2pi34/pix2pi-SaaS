import { DataTable } from '../components/DataTable';

const rows = [
  { kod: 'TENANT_A', durum: 'active', sube: '3', ulke: 'TR' },
  { kod: 'TENANT_B', durum: 'active', sube: '7', ulke: 'TR' },
  { kod: 'TENANT_C', durum: 'draft', sube: '1', ulke: 'TR' },
  { kod: 'TENANT_D', durum: 'active', sube: '5', ulke: 'TR' },
  { kod: 'TENANT_E', durum: 'passive', sube: '2', ulke: 'DE' },
  { kod: 'TENANT_F', durum: 'active', sube: '9', ulke: 'TR' },
];

export function DashboardPage() {
  return (
    <div className="page-grid">
      <section className="card span-8">
        <strong>Faz 1 Durum Ozeti</strong>
        <p className="small">
          Bu ekran WEB-L1 icin app shell, layout, loading/error/empty pattern, form standardi ve table standardini tek yerde gosterir.
        </p>
        <div className="button-row">
          <span className="badge">DB-L1/L2/L3 omurgasi hazir</span>
          <span className="badge">WEB-L1/L2 iskeleti hazir</span>
        </div>
      </section>
      <section className="card span-4">
        <strong>Runtime Config</strong>
        <p className="small">Environment ve API tabani ayri runtime config ile tasinir.</p>
      </section>
      <DataTable
        title="Tenant Ozeti"
        rows={rows}
        columns={[
          { key: 'kod', label: 'Kod' },
          { key: 'durum', label: 'Durum' },
          { key: 'sube', label: 'Sube' },
          { key: 'ulke', label: 'Ulke' },
        ]}
      />
    </div>
  );
}

