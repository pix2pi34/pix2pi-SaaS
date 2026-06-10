package main

import (
	"context"
	"errors"
	"os"
	"strings"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	errERPRuntimeGatewayDSNRequired  = errors.New("erp runtime gateway dsn zorunlu")
	errERPRuntimeGatewayPoolRequired = errors.New("erp runtime gateway db pool zorunlu")
)

type erpRuntimeGatewayAPIServiceBundle struct {
	service apisurface.RuntimeFlowAPIService
	pool    *pgxpool.Pool
}

func (b *erpRuntimeGatewayAPIServiceBundle) Close() {
	if b == nil || b.pool == nil {
		return
	}

	b.pool.Close()
}

func erpRuntimeGatewayDSNFromEnv() string {
	for _, key := range []string{
		"DB_WRITE_DSN",
		"PIX2PI_DB_TEST_DSN",
		"DATABASE_URL",
	} {
		value := strings.TrimSpace(os.Getenv(key))
		if value != "" {
			return value
		}
	}

	return ""
}

func newERPRuntimeGatewayAPIServiceBundleFromEnv(ctx context.Context) (*erpRuntimeGatewayAPIServiceBundle, error) {
	return newERPRuntimeGatewayAPIServiceBundle(ctx, erpRuntimeGatewayDSNFromEnv())
}

func newERPRuntimeGatewayAPIServiceBundle(ctx context.Context, dsn string) (*erpRuntimeGatewayAPIServiceBundle, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	dsn = strings.TrimSpace(dsn)
	if dsn == "" {
		return nil, errERPRuntimeGatewayDSNRequired
	}

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, err
	}

	service, err := buildERPRuntimeGatewayAPIService(pool)
	if err != nil {
		pool.Close()
		return nil, err
	}

	return &erpRuntimeGatewayAPIServiceBundle{
		service: service,
		pool:    pool,
	}, nil
}

func buildERPRuntimeGatewayAPIService(pool *pgxpool.Pool) (apisurface.RuntimeFlowAPIService, error) {
	if pool == nil {
		return nil, errERPRuntimeGatewayPoolRequired
	}

	registry, err := e2eflow.NewRuntimeBridgeStepAdapterRegistry(runtimeGatewayBridgeHandlers())
	if err != nil {
		return nil, err
	}

	orchestrator := e2eflow.NewDefaultRuntimeE2EOrchestrator(
		e2eflow.NewDefaultRuntimeFlowPlanner(),
		e2eflow.NewAdapterRuntimeFlowStepRunner(registry, nil, true),
		e2eflow.NewPostgresRuntimeFlowStore(pool),
		&erpRuntimeGatewayFlowPublisher{},
	)

	return apisurface.NewDefaultRuntimeFlowAPIService(orchestrator), nil
}

func runtimeGatewayBridgeHandlers() e2eflow.RuntimeBridgeHandlers {
	return e2eflow.RuntimeBridgeHandlers{
		PersistDocument: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
		CalculateTax: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
		ExecuteCashBankPayment: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
		PostJournal: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
		PostLedger: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
		PublishRuntimeEvent: func(ctx context.Context, plan e2eflow.RuntimeFlowPlan) error {
			return nil
		},
	}
}

type erpRuntimeGatewayFlowPublisher struct{}

func (p *erpRuntimeGatewayFlowPublisher) PublishFlowCompleted(ctx context.Context, result e2eflow.RuntimeFlowResult) error {
	return nil
}

func (p *erpRuntimeGatewayFlowPublisher) PublishFlowFailed(ctx context.Context, plan e2eflow.RuntimeFlowPlan, cause error) error {
	return nil
}
