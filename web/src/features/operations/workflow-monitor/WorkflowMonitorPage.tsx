import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchWorkflowMonitorOverview } from './workflow-monitor-api';
import type {
  WorkflowApprovalRow,
  WorkflowDefinitionRow,
  WorkflowInstanceRow,
  WorkflowStepRow,
} from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['active', 'running', 'completed', 'approved', 'empty', 'published'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['failed', 'rejected', 'cancelled', 'expired'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['waiting', 'pending', 'in_progress', 'paused', 'draft'].includes(normalized)) {
    return 'status-pill status-pill--degraded';
  }

  return 'status-pill status-pill--unknown';
}

function includesAny(values: string[], query: string): boolean {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return true;
  }

  return values.some((value) => value.toLowerCase().includes(trimmed));
}

function filterDefinitions(rows: WorkflowDefinitionRow[], query: string): WorkflowDefinitionRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.workflowKey,
        row.displayName,
        row.visibilityScope,
        row.definitionStatus,
        row.triggerEvent,
      ],
      query,
    ),
  );
}

function filterInstances(rows: WorkflowInstanceRow[], query: string): WorkflowInstanceRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.instanceId,
        row.workflowKey,
        row.instanceKey,
        row.workflowStatus,
        row.subjectRefType,
        row.subjectRefId,
        row.currentStepKey,
      ],
      query,
    ),
  );
}

function filterSteps(rows: WorkflowStepRow[], query: string): WorkflowStepRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.stepId,
        row.instanceKey,
        row.stepKey,
        row.stepType,
        row.stepStatus,
        row.assignedTo,
      ],
      query,
    ),
  );
}

function filterApprovals(rows: WorkflowApprovalRow[], query: string): WorkflowApprovalRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.approvalId,
        row.instanceKey,
        row.stepId,
        row.approvalKey,
        row.approverRef,
        row.approvalStatus,
        row.responseNote,
      ],
      query,
    ),
  );
}

export function WorkflowMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const workflowQuery = useQuery({
    queryKey: ['operations', 'workflow-monitor', tenantId],
    queryFn: () => fetchWorkflowMonitorOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = workflowQuery.data?.summary ?? [];
  const definitions = workflowQuery.data?.definitions ?? [];
  const instances = workflowQuery.data?.instances ?? [];
  const steps = workflowQuery.data?.steps ?? [];
  const approvals = workflowQuery.data?.approvals ?? [];

  const filteredDefinitions = useMemo(() => filterDefinitions(definitions, query), [definitions, query]);
  const filteredInstances = useMemo(() => filterInstances(instances, query), [instances, query]);
  const filteredSteps = useMemo(() => filterSteps(steps, query), [steps, query]);
  const filteredApprovals = useMemo(() => filterApprovals(approvals, query), [approvals, query]);

  const totalInstances = summary.reduce((acc, item) => acc + item.count, 0);
  const definitionCount = summary[0]?.definitionCount ?? definitions.length;
  const stepCount = summary[0]?.stepCount ?? steps.length;
  const approvalCount = summary[0]?.approvalCount ?? approvals.length;

  if (workflowQuery.isLoading || workflowQuery.isPending) {
    return <LoadingState message="Workflow Monitor yukleniyor..." />;
  }

  if (workflowQuery.isError) {
    return (
      <ErrorState
        title="Workflow Monitor okunamadi"
        description="Workflow Runtime servisi, 5900 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void workflowQuery.refetch()}
      />
    );
  }

  if (!workflowQuery.data) {
    return (
      <EmptyState
        title="Workflow Monitor verisi bulunamadi"
        description="Workflow Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Workflow Monitor</strong>
            <p className="small">
              Workflow definition, instance, step ve manual approval akislarini read-only izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void workflowQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {workflowQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {workflowQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Definition {definitionCount}</span>
          <span className="badge">Instance {totalInstances}</span>
          <span className="badge">Step {stepCount}</span>
          <span className="badge">Approval {approvalCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. Gercek workflow executor/runner ayri asamada kontrollu acilacak.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /workflow-runtime/api/workflows/summary</div>
          </div>
          <input
            aria-label="Workflow ara"
            placeholder="Workflow, instance, step veya approval ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Definition</th>
              <th>Step</th>
              <th>Approval</th>
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
                <td>{item.definitionCount}</td>
                <td>{item.stepCount}</td>
                <td>{item.approvalCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Workflow Definitions</strong>
            <div className="small">Kaynak: /workflow-runtime/api/workflows/definitions</div>
          </div>
          <span className="badge">Gosterilen {filteredDefinitions.length} / {definitions.length}</span>
        </div>

        {definitions.length === 0 ? (
          <EmptyState
            title="Workflow definition kaydi yok"
            description="Henüz runtime.workflow_definitions tablosunda definition bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Workflow</th>
                <th>Versiyon</th>
                <th>Durum</th>
                <th>Gorunurluk</th>
                <th>Trigger</th>
                <th>Aktif</th>
              </tr>
            </thead>
            <tbody>
              {filteredDefinitions.map((definition) => (
                <tr key={`${definition.workflowKey}-${definition.versionNo}`}>
                  <td>{definition.workflowKey}</td>
                  <td>{definition.versionNo}</td>
                  <td>
                    <span className={statusClassName(definition.definitionStatus)}>
                      {definition.definitionStatus}
                    </span>
                  </td>
                  <td>{definition.visibilityScope}</td>
                  <td>{definition.triggerEvent || '-'}</td>
                  <td>{definition.isEnabled ? 'Evet' : 'Hayir'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Workflow Instances</strong>
            <div className="small">Kaynak: /workflow-runtime/api/workflows/instances</div>
          </div>
          <span className="badge">Gosterilen {filteredInstances.length} / {instances.length}</span>
        </div>

        {instances.length === 0 ? (
          <EmptyState
            title="Workflow instance kaydi yok"
            description="Henüz runtime.workflow_instances tablosunda instance bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Instance</th>
                <th>Workflow</th>
                <th>Status</th>
                <th>Subject</th>
                <th>Current Step</th>
                <th>Baslama</th>
              </tr>
            </thead>
            <tbody>
              {filteredInstances.map((instance) => (
                <tr key={instance.instanceId}>
                  <td>{instance.instanceKey}</td>
                  <td>{instance.workflowKey}</td>
                  <td>
                    <span className={statusClassName(instance.workflowStatus)}>
                      {instance.workflowStatus}
                    </span>
                  </td>
                  <td>{instance.subjectRefType}:{instance.subjectRefId}</td>
                  <td>{instance.currentStepKey || '-'}</td>
                  <td>{instance.startedAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Workflow Steps</strong>
            <div className="small">Kaynak: /workflow-runtime/api/workflows/steps</div>
          </div>
          <span className="badge">Gosterilen {filteredSteps.length} / {steps.length}</span>
        </div>

        {steps.length === 0 ? (
          <EmptyState
            title="Workflow step kaydi yok"
            description="Henüz runtime.workflow_steps tablosunda step bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Step</th>
                <th>Instance</th>
                <th>Tip</th>
                <th>Status</th>
                <th>Atanan</th>
                <th>Sira</th>
              </tr>
            </thead>
            <tbody>
              {filteredSteps.map((step) => (
                <tr key={step.stepId}>
                  <td>{step.stepKey}</td>
                  <td>{step.instanceKey}</td>
                  <td>{step.stepType}</td>
                  <td>
                    <span className={statusClassName(step.stepStatus)}>{step.stepStatus}</span>
                  </td>
                  <td>{step.assignedTo || '-'}</td>
                  <td>{step.stepOrder}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Manual Approvals</strong>
            <div className="small">Kaynak: /workflow-runtime/api/workflows/approvals</div>
          </div>
          <span className="badge">Gosterilen {filteredApprovals.length} / {approvals.length}</span>
        </div>

        {approvals.length === 0 ? (
          <EmptyState
            title="Approval kaydi yok"
            description="Henüz runtime.workflow_approvals tablosunda approval bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Approval</th>
                <th>Instance</th>
                <th>Approver</th>
                <th>Status</th>
                <th>Talep</th>
                <th>Cevap</th>
              </tr>
            </thead>
            <tbody>
              {filteredApprovals.map((approval) => (
                <tr key={approval.approvalId}>
                  <td>{approval.approvalKey}</td>
                  <td>{approval.instanceKey}</td>
                  <td>{approval.approverRef}</td>
                  <td>
                    <span className={statusClassName(approval.approvalStatus)}>
                      {approval.approvalStatus}
                    </span>
                  </td>
                  <td>{approval.requestedAt || '-'}</td>
                  <td>{approval.respondedAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
