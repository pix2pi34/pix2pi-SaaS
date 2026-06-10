import { useMemo, useState } from 'react';

type Column<T> = {
  key: keyof T;
  label: string;
};

type DataTableProps<T extends Record<string, string>> = {
  title: string;
  rows: T[];
  columns: Column<T>[];
};

const PAGE_SIZE = 5;

export function DataTable<T extends Record<string, string>>({ title, rows, columns }: DataTableProps<T>) {
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    const trimmed = query.trim().toLowerCase();
    if (!trimmed) {
      return rows;
    }

    return rows.filter((row) =>
      Object.values(row).some((value) => value.toLowerCase().includes(trimmed)),
    );
  }, [query, rows]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const pageRows = filtered.slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);

  return (
    <div className="card span-12">
      <div className="toolbar">
        <div>
          <strong>{title}</strong>
          <div className="small">Filter + pagination standardi</div>
        </div>
        <input
          aria-label="Ara"
          placeholder="Ara"
          value={query}
          onChange={(event) => {
            setPage(1);
            setQuery(event.target.value);
          }}
        />
      </div>

      <table className="data-table">
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={String(column.key)}>{column.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {pageRows.map((row, index) => (
            <tr key={index}>
              {columns.map((column) => (
                <td key={String(column.key)}>{row[column.key]}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      <div className="toolbar" style={{ marginTop: 16 }}>
        <span className="small">
          Toplam {filtered.length} kayit · Sayfa {currentPage}/{totalPages}
        </span>
        <div className="button-row">
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => setPage((value) => Math.max(1, value - 1))}
          >
            Geri
          </button>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => setPage((value) => Math.min(totalPages, value + 1))}
          >
            Ileri
          </button>
        </div>
      </div>
    </div>
  );
}

