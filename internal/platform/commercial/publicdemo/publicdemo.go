package publicdemo

import (
	"fmt"
	"net/mail"
	"strings"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
)

type LeadStatus string
type CTA string
type ReasonCode string

const (
	LeadStatusNew                 LeadStatus = "NEW"
	LeadStatusQualified           LeadStatus = "QUALIFIED"
	LeadStatusReadyForOnboarding  LeadStatus = "READY_FOR_ONBOARDING"
	LeadStatusRejected            LeadStatus = "REJECTED"
)

const (
	CTARequestDemo          CTA = "request_demo"
	CTAStartTrial           CTA = "start_trial"
	CTAMarketplaceDiscovery CTA = "marketplace_discovery"
	CTAIntegrationCatalog   CTA = "integration_catalog"
	CTAAccountantPortal     CTA = "accountant_portal"
)

const (
	ReasonAllowDemoRequestReady ReasonCode = "ALLOW_DEMO_REQUEST_READY"
	ReasonAllowReadyOnboarding  ReasonCode = "ALLOW_READY_FOR_ONBOARDING"
	ReasonDenyRequestRequired   ReasonCode = "DENY_REQUEST_REQUIRED"
	ReasonDenyBusinessRequired  ReasonCode = "DENY_BUSINESS_REQUIRED"
	ReasonDenyContactRequired   ReasonCode = "DENY_CONTACT_REQUIRED"
	ReasonDenyEmailInvalid      ReasonCode = "DENY_EMAIL_INVALID"
	ReasonDenyPhoneRequired     ReasonCode = "DENY_PHONE_REQUIRED"
	ReasonDenyCompanyRequired   ReasonCode = "DENY_COMPANY_SIZE_REQUIRED"
	ReasonDenyPlanRequired      ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown       ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyConsentRequired   ReasonCode = "DENY_CONSENT_REQUIRED"
	ReasonDenyPublicLaunch      ReasonCode = "DENY_PUBLIC_LAUNCH_DISABLED"
)

type DemoRequest struct {
	RequestID      string
	BusinessName   string
	ContactName    string
	Email          string
	Phone          string
	CompanySize    string
	RequestedPlan  catalog.PlanCode
	Message        string
	ConsentAccepted bool
	CTA            CTA
	CreatedAt      time.Time
}

type Lead struct {
	RequestID     string
	BusinessName  string
	ContactName   string
	Email         string
	Phone         string
	CompanySize   string
	RequestedPlan catalog.PlanCode
	Message       string
	CTA           CTA
	Status        LeadStatus
	CreatedAt     time.Time
}

type Decision struct {
	Status        entitlement.DecisionStatus
	ReasonCode    string
	ReasonMessage string

	RequestID     string
	BusinessName  string
	ContactName   string
	Email         string
	RequestedPlan catalog.PlanCode
	LeadStatus    LeadStatus
	CTA           CTA
}

type LandingModel struct {
	Title       string
	Description string
	Plans       []catalog.PlanCode
	Sections    []string
	CTAs        []CTA
	SEOType     string
}

type Runtime struct {
	catalog catalog.Catalog

	PublicProductionLaunchEnabled bool
	RealPaymentEnabled            bool
	RequiresLegalApproval         bool
	RequiresKVKKApproval          bool
	RequiresCloudflareGreenMode   bool
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	return &Runtime{
		catalog: c,
		PublicProductionLaunchEnabled: false,
		RealPaymentEnabled: false,
		RequiresLegalApproval: true,
		RequiresKVKKApproval: true,
		RequiresCloudflareGreenMode: true,
	}, nil
}

func (r *Runtime) LandingModel() LandingModel {
	return LandingModel{
		Title: "Pix2pi SaaS ERP",
		Description: "POS, stok, cari, rapor, muhasebeci portal ve entegrasyon hazirligi.",
		Plans: []catalog.PlanCode{
			catalog.PlanStarter,
			catalog.PlanPro,
			catalog.PlanEnterprise,
			catalog.PlanAccountant,
			catalog.PlanMarketplace,
		},
		Sections: []string{
			"hero",
			"product_value",
			"plans",
			"demo_request",
			"trial_cta",
			"integration_cta",
			"seo_schema",
		},
		CTAs: []CTA{
			CTARequestDemo,
			CTAStartTrial,
			CTAMarketplaceDiscovery,
			CTAIntegrationCatalog,
			CTAAccountantPortal,
		},
		SEOType: "SoftwareApplication",
	}
}

func (r *Runtime) CreateDemoLead(req DemoRequest) (Lead, Decision) {
	if req.CreatedAt.IsZero() {
		req.CreatedAt = time.Now().UTC()
	}
	if req.CTA == "" {
		req.CTA = CTARequestDemo
	}

	if decision, ok := r.validateRequest(req); !ok {
		return Lead{
			RequestID: req.RequestID,
			BusinessName: req.BusinessName,
			ContactName: req.ContactName,
			Email: req.Email,
			RequestedPlan: req.RequestedPlan,
			CTA: req.CTA,
			Status: LeadStatusRejected,
			CreatedAt: req.CreatedAt,
		}, decision
	}

	lead := Lead{
		RequestID: strings.TrimSpace(req.RequestID),
		BusinessName: strings.TrimSpace(req.BusinessName),
		ContactName: strings.TrimSpace(req.ContactName),
		Email: strings.TrimSpace(req.Email),
		Phone: strings.TrimSpace(req.Phone),
		CompanySize: strings.TrimSpace(req.CompanySize),
		RequestedPlan: req.RequestedPlan,
		Message: strings.TrimSpace(req.Message),
		CTA: req.CTA,
		Status: LeadStatusNew,
		CreatedAt: req.CreatedAt,
	}

	return lead, Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowDemoRequestReady),
		ReasonMessage: "demo request lead is ready",
		RequestID: lead.RequestID,
		BusinessName: lead.BusinessName,
		ContactName: lead.ContactName,
		Email: lead.Email,
		RequestedPlan: lead.RequestedPlan,
		LeadStatus: lead.Status,
		CTA: lead.CTA,
	}
}

func (r *Runtime) QualifyLead(lead Lead) (Lead, Decision) {
	if lead.RequestID == "" {
		return lead, Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyRequestRequired),
			ReasonMessage: "lead request id is required",
			LeadStatus: LeadStatusRejected,
		}
	}

	if _, ok := r.catalog.Plan(lead.RequestedPlan); !ok {
		return lead, Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyPlanUnknown),
			ReasonMessage: "requested plan is not defined in catalog",
			RequestID: lead.RequestID,
			RequestedPlan: lead.RequestedPlan,
			LeadStatus: LeadStatusRejected,
			CTA: lead.CTA,
		}
	}

	lead.Status = LeadStatusQualified

	return lead, Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowDemoRequestReady),
		ReasonMessage: "lead is qualified",
		RequestID: lead.RequestID,
		BusinessName: lead.BusinessName,
		ContactName: lead.ContactName,
		Email: lead.Email,
		RequestedPlan: lead.RequestedPlan,
		LeadStatus: lead.Status,
		CTA: lead.CTA,
	}
}

func (r *Runtime) MarkReadyForOnboarding(lead Lead) (Lead, Decision) {
	if lead.Status != LeadStatusQualified {
		return lead, Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyRequestRequired),
			ReasonMessage: "lead must be qualified before onboarding",
			RequestID: lead.RequestID,
			RequestedPlan: lead.RequestedPlan,
			LeadStatus: lead.Status,
			CTA: lead.CTA,
		}
	}

	lead.Status = LeadStatusReadyForOnboarding

	return lead, Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowReadyOnboarding),
		ReasonMessage: "lead is ready for tenant onboarding",
		RequestID: lead.RequestID,
		BusinessName: lead.BusinessName,
		ContactName: lead.ContactName,
		Email: lead.Email,
		RequestedPlan: lead.RequestedPlan,
		LeadStatus: lead.Status,
		CTA: lead.CTA,
	}
}

func (r *Runtime) CheckPublicLaunchGate() Decision {
	if !r.PublicProductionLaunchEnabled {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyPublicLaunch),
			ReasonMessage: "public production launch is disabled in FAZ 7-7",
		}
	}

	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowDemoRequestReady),
		ReasonMessage: "public production launch gate is open",
	}
}

func (r *Runtime) validateRequest(req DemoRequest) (Decision, bool) {
	if strings.TrimSpace(req.RequestID) == "" {
		return r.deny(req, ReasonDenyRequestRequired, "request id is required"), false
	}
	if strings.TrimSpace(req.BusinessName) == "" {
		return r.deny(req, ReasonDenyBusinessRequired, "business name is required"), false
	}
	if strings.TrimSpace(req.ContactName) == "" {
		return r.deny(req, ReasonDenyContactRequired, "contact name is required"), false
	}
	if strings.TrimSpace(req.Email) == "" {
		return r.deny(req, ReasonDenyEmailInvalid, "email is required"), false
	}
	if _, err := mail.ParseAddress(req.Email); err != nil {
		return r.deny(req, ReasonDenyEmailInvalid, "email is invalid"), false
	}
	if strings.TrimSpace(req.Phone) == "" {
		return r.deny(req, ReasonDenyPhoneRequired, "phone is required"), false
	}
	if strings.TrimSpace(req.CompanySize) == "" {
		return r.deny(req, ReasonDenyCompanyRequired, "company size is required"), false
	}
	if req.RequestedPlan == "" {
		return r.deny(req, ReasonDenyPlanRequired, "requested plan is required"), false
	}
	if _, ok := r.catalog.Plan(req.RequestedPlan); !ok {
		return r.deny(req, ReasonDenyPlanUnknown, "requested plan is not defined in catalog"), false
	}
	if !req.ConsentAccepted {
		return r.deny(req, ReasonDenyConsentRequired, "consent must be accepted"), false
	}

	return Decision{}, true
}

func (r *Runtime) deny(req DemoRequest, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		RequestID: req.RequestID,
		BusinessName: req.BusinessName,
		ContactName: req.ContactName,
		Email: req.Email,
		RequestedPlan: req.RequestedPlan,
		LeadStatus: LeadStatusRejected,
		CTA: req.CTA,
	}
}
