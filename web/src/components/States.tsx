import type { ReactNode } from 'react';

export function LoadingState({ message = 'Yukleniyor...' }: { message?: string }) {
  return (
    <div className="state-box card span-12" role="status" aria-live="polite">
      <div className="badge">Loading</div>
      <strong>{message}</strong>
      <span className="small">Beklenen istek tamamlaninca ekran otomatik yenilenir.</span>
    </div>
  );
}

export function ErrorState({
  title = 'Bir hata olustu',
  description,
  retryAction,
}: {
  title?: string;
  description?: string;
  retryAction?: () => void;
}) {
  return (
    <div className="state-box card span-12" role="alert">
      <div className="badge">Error</div>
      <strong>{title}</strong>
      {description ? <span className="small">{description}</span> : null}
      {retryAction ? (
        <button type="button" className="btn btn-primary" onClick={retryAction}>
          Tekrar dene
        </button>
      ) : null}
    </div>
  );
}

export function EmptyState({
  title = 'Kayit bulunamadi',
  description,
  action,
}: {
  title?: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="state-box card span-12">
      <div className="badge">Empty</div>
      <strong>{title}</strong>
      {description ? <span className="small">{description}</span> : null}
      {action}
    </div>
  );
}

