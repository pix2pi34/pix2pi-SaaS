import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchJobsQueueOverview } from './jobs-queue-api';
import type { JobsQueueRow, JobsRecentRow } from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['succeeded', 'queued', 'empty'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['failed', 'dead_letter', 'cancelled'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['processing', 'scheduled'].includes(normalized)) {
    return 'status-pill status-pill--degraded';
  }

  return 'status-pill status-pill--unknown';
}

function totalQueueJobs(queue: JobsQueueRow): number {
  return queue.queuedCount + queue.processingCount + queue.failedCount + queue.deadLetterCount;
}

function filterQueues(rows: JobsQueueRow[], query: string): JobsQueueRow[] {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return rows;
  }

  return rows.filter((row) =>
    [
      row.queueKey,
      row.displayName,
      row.visibilityScope,
      row.deadLetterQueueKey,
      row.updatedAt,
    ].some((value) => value.toLowerCase().includes(trimmed)),
  );
}

function filterRecent(rows: JobsRecentRow[], query: string): JobsRecentRow[] {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return rows;
  }

  return rows.filter((row) =>
    [
      row.jobId,
      row.queueKey,
      row.jobKey,
      row.jobType,
      row.priority,
      row.status,
      row.lastError,
      row.lockedBy,
    ].some((value) => value.toLowerCase().includes(trimmed)),
  );
}

export function JobsQueuePage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const jobsQuery = useQuery({
    queryKey: ['operations', 'jobs-queue', tenantId],
    queryFn: () => fetchJobsQueueOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = jobsQuery.data?.summary ?? [];
  const queues = jobsQuery.data?.queues ?? [];
  const recent = jobsQuery.data?.recent ?? [];

  const filteredQueues = useMemo(() => filterQueues(queues, query), [queues, query]);
  const filteredRecent = useMemo(() => filterRecent(recent, query), [recent, query]);

  const totalJobs = summary.reduce((acc, item) => acc + item.count, 0);
  const queueCount = summary[0]?.queueCount ?? queues.length;
  const attemptCount = summary[0]?.attemptCount ?? 0;

  if (jobsQuery.isLoading || jobsQuery.isPending) {
    return <LoadingState message="Jobs Queue yukleniyor..." />;
  }

  if (jobsQuery.isError) {
    return (
      <ErrorState
        title="Jobs Queue okunamadi"
        description="Jobs Runtime servisi, 5880 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void jobsQuery.refetch()}
      />
    );
  }

  if (!jobsQuery.data) {
    return (
      <EmptyState
        title="Jobs Queue verisi bulunamadi"
        description="Jobs Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Jobs Queue</strong>
            <p className="small">
              Background job kuyruklarini, retry/DLQ durumunu ve son job kayitlarini izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void jobsQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {jobsQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {jobsQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Toplam Job {totalJobs}</span>
          <span className="badge">Queue {queueCount}</span>
          <span className="badge">Attempt {attemptCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. Gercek worker/executor ayri asamada kontrollu acilacak.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /jobs-runtime/api/jobs/summary</div>
          </div>
          <input
            aria-label="Jobs ara"
            placeholder="Queue veya job ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Queue Sayisi</th>
              <th>Attempt Sayisi</th>
              <th>Uretim Zamani</th>
            </tr>
          </thead>
          <tbody>
            {summary.map((item) => (
              <tr key={item.status}>
                <td>
                  <span className={statusClassName(item.status)}>{item.status}</span>
                </td>
                <td>{item.count}</td>
                <td>{item.queueCount}</td>
                <td>{item.attemptCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Queue Listesi</strong>
            <div className="small">Kaynak: /jobs-runtime/api/jobs/queues</div>
          </div>
          <span className="badge">Gosterilen {filteredQueues.length} / {queues.length}</span>
        </div>

        {queues.length === 0 ? (
          <EmptyState
            title="Queue kaydi yok"
            description="Henüz runtime.job_queues tablosunda kuyruk bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Queue</th>
                <th>Gorunurluk</th>
                <th>Aktif</th>
                <th>Queued</th>
                <th>Processing</th>
                <th>Failed</th>
                <th>DLQ</th>
                <th>Toplam</th>
              </tr>
            </thead>
            <tbody>
              {filteredQueues.map((queue) => (
                <tr key={queue.queueKey}>
                  <td>{queue.queueKey}</td>
                  <td>{queue.visibilityScope}</td>
                  <td>{queue.isEnabled ? 'Evet' : 'Hayir'}</td>
                  <td>{queue.queuedCount}</td>
                  <td>{queue.processingCount}</td>
                  <td>{queue.failedCount}</td>
                  <td>{queue.deadLetterCount}</td>
                  <td>{totalQueueJobs(queue)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Son Job Kayitlari</strong>
            <div className="small">Kaynak: /jobs-runtime/api/jobs/recent</div>
          </div>
          <span className="badge">Gosterilen {filteredRecent.length} / {recent.length}</span>
        </div>

        {recent.length === 0 ? (
          <EmptyState
            title="Job kaydi yok"
            description="Henüz runtime.jobs tablosunda job bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Job</th>
                <th>Queue</th>
                <th>Tip</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Retry</th>
                <th>Locked By</th>
                <th>Olusturma</th>
              </tr>
            </thead>
            <tbody>
              {filteredRecent.map((job) => (
                <tr key={job.jobId}>
                  <td>{job.jobKey}</td>
                  <td>{job.queueKey}</td>
                  <td>{job.jobType}</td>
                  <td>{job.priority}</td>
                  <td>
                    <span className={statusClassName(job.status)}>{job.status}</span>
                  </td>
                  <td>{job.retryCount} / {job.maxAttempts}</td>
                  <td>{job.lockedBy || '-'}</td>
                  <td>{job.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
