package loginsmoke

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/auth/accessdenial"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/jwtlogin"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/loginerrors"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/multitenantuser"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/sessiontimeout"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/tenantpreference"
	"github.com/divrigili/pix2pi-SaaS/internal/auth/tenantselection"
)

func TestLoginSmokeFullE2EHappyPath(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	ctx := context.Background()

	passwordVerifier := jwtlogin.HMACPasswordVerifier{Secret: []byte("password-secret-which-is-long-enough-32")}
	jwtStore := newJWTStore(now, passwordVerifier)
	jwtService, err := jwtlogin.NewService(jwtlogin.Config{
		Issuer:          "pix2pi-auth",
		Audience:        "pix2pi-panel",
		Secret:          []byte("jwt-secret-which-is-long-enough-32-bytes"),
		AccessTokenTTL:  time.Hour,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		Now:             func() time.Time { return now },
	}, jwtStore, passwordVerifier)
	if err != nil {
		t.Fatalf("jwt service error: %v", err)
	}

	loginResult, err := jwtService.Login(ctx, jwtlogin.LoginInput{
		Email:     "owner@example.com",
		Password:  "correct-password",
		TenantID:  "tenant-001",
		IPAddress: "127.0.0.1",
		UserAgent: "login-smoke",
	})
	if err != nil {
		t.Fatalf("login error: %v", err)
	}
	if loginResult.AccessToken == "" || loginResult.RefreshToken == "" {
		t.Fatalf("tokens were not created")
	}

	selectionService := tenantselection.NewService(
		newTenantSelectionStore(),
		tokenVerifierAdapter{service: jwtService, email: "owner@example.com"},
		func() time.Time { return now },
	)

	tenantList, err := selectionService.ListTenants(ctx, loginResult.AccessToken)
	if err != nil {
		t.Fatalf("tenant list error: %v", err)
	}
	if len(tenantList.Tenants) != 2 {
		t.Fatalf("expected two tenant options, got %d", len(tenantList.Tenants))
	}

	selectedTenant, err := selectionService.SelectTenant(ctx, loginResult.AccessToken, "tenant-002")
	if err != nil {
		t.Fatalf("tenant select error: %v", err)
	}
	if selectedTenant.TenantID != "tenant-002" {
		t.Fatalf("selected tenant mismatch: %s", selectedTenant.TenantID)
	}

	multiTenantService := multitenantuser.NewService(newMultiTenantStore(), func() time.Time { return now })
	switched, err := multiTenantService.SwitchTenant(ctx, multitenantuser.SwitchTenantInput{
		UserID:    "user-001",
		SessionID: loginResult.SessionID,
		TenantID:  "tenant-002",
	})
	if err != nil {
		t.Fatalf("multi tenant switch error: %v", err)
	}
	if switched.RoleCode != "manager" {
		t.Fatalf("role mismatch after switch: %s", switched.RoleCode)
	}

	preferenceStore := newTenantPreferenceStore()
	preferenceService := tenantpreference.NewService(preferenceStore, func() time.Time { return now })
	remembered, err := preferenceService.RememberTenant(ctx, tenantpreference.SetPreferenceInput{
		UserID:    "user-001",
		SessionID: loginResult.SessionID,
		TenantID:  "tenant-002",
		Source:    "login_smoke",
	})
	if err != nil {
		t.Fatalf("remember tenant error: %v", err)
	}
	if remembered.TenantID != "tenant-002" {
		t.Fatalf("remembered tenant mismatch: %s", remembered.TenantID)
	}

	restored, err := preferenceService.ResolveRememberedTenant(ctx, tenantpreference.ResolvePreferenceInput{
		UserID:    "user-001",
		SessionID: "session-next",
	})
	if err != nil {
		t.Fatalf("resolve preference error: %v", err)
	}
	if restored.TenantID != "tenant-002" {
		t.Fatalf("restored tenant mismatch: %s", restored.TenantID)
	}

	sessionStore := jwtStore.sessionStore
	sessionService := sessiontimeout.NewService(sessionStore, sessiontimeout.TimeoutPolicy{
		IdleTimeout:     30 * time.Minute,
		AbsoluteTimeout: 12 * time.Hour,
	}, func() time.Time { return now.Add(5 * time.Minute) })

	validated, err := sessionService.ValidateSession(ctx, sessiontimeout.ValidationInput{
		SessionID:     loginResult.SessionID,
		AccessTokenID: loginResult.AccessTokenID,
		IPAddress:     "127.0.0.1",
		UserAgent:     "login-smoke",
	})
	if err != nil {
		t.Fatalf("session validation error: %v", err)
	}
	if validated.SessionID != loginResult.SessionID {
		t.Fatalf("validated session mismatch: %s", validated.SessionID)
	}
	if sessionStore.touched[loginResult.SessionID].IsZero() {
		t.Fatalf("session last seen was not touched")
	}

	if err := sessionService.Logout(ctx, loginResult.SessionID); err != nil {
		t.Fatalf("logout error: %v", err)
	}
	if sessionStore.revoked[loginResult.SessionID].IsZero() {
		t.Fatalf("session was not revoked")
	}
}

func TestLoginSmokeWrongPasswordSafeError(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	ctx := context.Background()

	passwordVerifier := jwtlogin.HMACPasswordVerifier{Secret: []byte("password-secret-which-is-long-enough-32")}
	jwtStore := newJWTStore(now, passwordVerifier)
	jwtService, err := jwtlogin.NewService(jwtlogin.Config{
		Secret:          []byte("jwt-secret-which-is-long-enough-32-bytes"),
		AccessTokenTTL:  time.Hour,
		RefreshTokenTTL: time.Hour,
		Now:             func() time.Time { return now },
	}, jwtStore, passwordVerifier)
	if err != nil {
		t.Fatalf("jwt service error: %v", err)
	}

	_, err = jwtService.Login(ctx, jwtlogin.LoginInput{
		Email:    "owner@example.com",
		Password: "wrong-password",
		TenantID: "tenant-001",
	})
	if !errors.Is(err, jwtlogin.ErrInvalidCredentials) {
		t.Fatalf("expected invalid credentials, got %v", err)
	}

	errorStore := &loginErrorStore{}
	errorService := loginerrors.NewService(errorStore, func() time.Time { return now })
	public := errorService.Build(ctx, loginerrors.ErrInvalidCredentials, loginerrors.RequestContext{
		CorrelationID: "corr-login-smoke",
		Locale:        loginerrors.LocaleTR,
		Email:         "owner@example.com",
	})

	if public.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", public.HTTPStatus)
	}
	if public.Code != loginerrors.CodeInvalidCredentials {
		t.Fatalf("code mismatch: %s", public.Code)
	}
	if public.Message != "E-posta veya şifre hatalı." {
		t.Fatalf("unsafe or wrong message: %s", public.Message)
	}
	if len(errorStore.events) != 1 {
		t.Fatalf("login error event was not recorded")
	}
}

func TestLoginSmokeAccessDenialDecisions(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)
	ctx := context.Background()

	denialStore := &accessDenialStore{}
	denialService := accessdenial.NewService(denialStore, func() time.Time { return now })

	unauthorized := denialService.Decide(ctx, accessdenial.ErrMissingToken, accessdenial.RequestContext{
		RoutePath:     "/dashboard/",
		ActionCode:    "panel:dashboard:view",
		CorrelationID: "corr-401",
		Locale:        accessdenial.LocaleTR,
	})
	if unauthorized.HTTPStatus != http.StatusUnauthorized {
		t.Fatalf("unauthorized status mismatch: %d", unauthorized.HTTPStatus)
	}
	if unauthorized.Screen != accessdenial.ScreenUnauthorized {
		t.Fatalf("unauthorized screen mismatch: %s", unauthorized.Screen)
	}

	forbidden := denialService.Decide(ctx, accessdenial.ErrPermissionDenied, accessdenial.RequestContext{
		TenantID:      "tenant-001",
		UserID:        "user-001",
		RoleCode:      "cashier",
		RoutePath:     "/billing/",
		ActionCode:    "billing:view",
		CorrelationID: "corr-403",
		Locale:        accessdenial.LocaleEN,
	})
	if forbidden.HTTPStatus != http.StatusForbidden {
		t.Fatalf("forbidden status mismatch: %d", forbidden.HTTPStatus)
	}
	if forbidden.Screen != accessdenial.ScreenForbidden {
		t.Fatalf("forbidden screen mismatch: %s", forbidden.Screen)
	}
	if len(denialStore.events) != 2 {
		t.Fatalf("expected two access denial events, got %d", len(denialStore.events))
	}
}

func TestLoginSmokeReportRequiresEveryStep(t *testing.T) {
	now := time.Date(2026, 5, 11, 12, 0, 0, 0, time.UTC)

	report := BuildReport(now, []StepStatus{
		{Step: "317.2", Name: "JWT login bağlantısı", Status: "PASS"},
		{Step: "317.3", Name: "Tenant selection screen", Status: "PASS"},
		{Step: "317.4", Name: "Multi-tenant user destek", Status: "PASS"},
		{Step: "317.5", Name: "Remember tenant preference", Status: "PASS"},
		{Step: "317.6", Name: "Session timeout davranışı", Status: "PASS"},
		{Step: "317.7", Name: "Login error messages", Status: "PASS"},
		{Step: "317.8", Name: "Unauthorized / forbidden ekranları", Status: "PASS"},
	})

	if !AllPass(report) {
		t.Fatalf("expected all pass report")
	}
	if report.PassCount != 7 || report.FailCount != 0 {
		t.Fatalf("counter mismatch pass=%d fail=%d", report.PassCount, report.FailCount)
	}
}

type jwtStore struct {
	users        map[string]jwtlogin.User
	memberships  map[string]jwtlogin.TenantMembership
	sessionStore *sessionStore
	now          time.Time
}

func newJWTStore(now time.Time, verifier jwtlogin.HMACPasswordVerifier) *jwtStore {
	return &jwtStore{
		now: now,
		users: map[string]jwtlogin.User{
			"owner@example.com": {
				ID:           "user-001",
				Email:        "owner@example.com",
				PasswordHash: verifier.HashPassword("correct-password"),
				Status:       "active",
			},
		},
		memberships: map[string]jwtlogin.TenantMembership{
			"user-001|tenant-001": {
				TenantID: "tenant-001",
				UserID:   "user-001",
				RoleCode: "owner",
				Status:   "active",
			},
			"user-001|tenant-002": {
				TenantID: "tenant-002",
				UserID:   "user-001",
				RoleCode: "manager",
				Status:   "active",
			},
		},
		sessionStore: &sessionStore{
			sessions: map[string]sessiontimeout.SessionRecord{},
			touched:  map[string]time.Time{},
			revoked:  map[string]time.Time{},
			events:   []sessiontimeout.SessionEvent{},
		},
	}
}

func (s *jwtStore) FindUserByEmail(_ context.Context, email string) (jwtlogin.User, error) {
	user, ok := s.users[email]
	if !ok {
		return jwtlogin.User{}, errors.New("user missing")
	}
	return user, nil
}

func (s *jwtStore) FindTenantMembership(_ context.Context, userID string, tenantID string) (jwtlogin.TenantMembership, error) {
	membership, ok := s.memberships[userID+"|"+tenantID]
	if !ok {
		return jwtlogin.TenantMembership{}, errors.New("membership missing")
	}
	return membership, nil
}

func (s *jwtStore) RecordLoginSession(_ context.Context, record jwtlogin.SessionRecord) error {
	s.sessionStore.sessions[record.SessionID] = sessiontimeout.SessionRecord{
		TenantID:              record.TenantID,
		UserID:                record.UserID,
		SessionID:             record.SessionID,
		AccessTokenID:         record.AccessTokenID,
		RefreshTokenID:        record.RefreshTokenID,
		IssuedAt:              record.IssuedAt,
		AccessTokenExpiresAt:  record.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: record.RefreshTokenExpiresAt,
		LastSeenAt:            record.IssuedAt,
		IPAddress:             record.IPAddress,
		UserAgent:             record.UserAgent,
	}
	return nil
}

type tokenVerifierAdapter struct {
	service *jwtlogin.Service
	email   string
}

func (v tokenVerifierAdapter) VerifyAccessToken(_ context.Context, token string) (tenantselection.AuthClaims, error) {
	claims, err := v.service.Verify(token)
	if err != nil {
		return tenantselection.AuthClaims{}, err
	}

	return tenantselection.AuthClaims{
		UserID:    claims.Subject,
		Email:     v.email,
		TenantID:  claims.TenantID,
		SessionID: claims.SessionID,
		TokenUse:  claims.TokenUse,
		ExpiresAt: time.Unix(claims.ExpiresAt, 0).UTC(),
	}, nil
}

type tenantSelectionStore struct {
	preferences map[string]string
}

func newTenantSelectionStore() *tenantSelectionStore {
	return &tenantSelectionStore{preferences: map[string]string{}}
}

func (s *tenantSelectionStore) ListActiveMemberships(_ context.Context, userID string) ([]tenantselection.Membership, error) {
	return []tenantselection.Membership{
		{TenantID: "tenant-001", UserID: userID, RoleCode: "owner", Status: "active"},
		{TenantID: "tenant-002", UserID: userID, RoleCode: "manager", Status: "active"},
	}, nil
}

func (s *tenantSelectionStore) GetTenant(_ context.Context, tenantID string) (tenantselection.Tenant, error) {
	tenants := map[string]tenantselection.Tenant{
		"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
		"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
	}
	tenant, ok := tenants[tenantID]
	if !ok {
		return tenantselection.Tenant{}, errors.New("tenant missing")
	}
	return tenant, nil
}

func (s *tenantSelectionStore) SaveTenantPreference(_ context.Context, userID string, tenantID string) error {
	s.preferences[userID] = tenantID
	return nil
}

type multiTenantStore struct {
	current map[string]string
}

func newMultiTenantStore() *multiTenantStore {
	return &multiTenantStore{current: map[string]string{}}
}

func (s *multiTenantStore) ListMembershipsForUser(_ context.Context, userID string) ([]multitenantuser.Membership, error) {
	return []multitenantuser.Membership{
		{UserID: userID, TenantID: "tenant-001", RoleCode: "owner", Status: "active"},
		{UserID: userID, TenantID: "tenant-002", RoleCode: "manager", Status: "active"},
	}, nil
}

func (s *multiTenantStore) GetTenant(_ context.Context, tenantID string) (multitenantuser.Tenant, error) {
	tenants := map[string]multitenantuser.Tenant{
		"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
		"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
	}
	tenant, ok := tenants[tenantID]
	if !ok {
		return multitenantuser.Tenant{}, errors.New("tenant missing")
	}
	return tenant, nil
}

func (s *multiTenantStore) SaveCurrentTenant(_ context.Context, contextValue multitenantuser.CurrentTenantContext) error {
	s.current[contextValue.UserID+"|"+contextValue.SessionID] = contextValue.TenantID
	return nil
}

func (s *multiTenantStore) GetCurrentTenantID(_ context.Context, userID string, sessionID string) (string, error) {
	tenantID, ok := s.current[userID+"|"+sessionID]
	if !ok {
		return "", errors.New("current tenant missing")
	}
	return tenantID, nil
}

type tenantPreferenceStore struct {
	persistent map[string]string
	session    map[string]tenantpreference.TenantPreference
}

func newTenantPreferenceStore() *tenantPreferenceStore {
	return &tenantPreferenceStore{
		persistent: map[string]string{},
		session:    map[string]tenantpreference.TenantPreference{},
	}
}

func (s *tenantPreferenceStore) ListMembershipsForUser(_ context.Context, userID string) ([]tenantpreference.Membership, error) {
	return []tenantpreference.Membership{
		{UserID: userID, TenantID: "tenant-001", RoleCode: "owner", Status: "active"},
		{UserID: userID, TenantID: "tenant-002", RoleCode: "manager", Status: "active"},
	}, nil
}

func (s *tenantPreferenceStore) GetTenant(_ context.Context, tenantID string) (tenantpreference.Tenant, error) {
	tenants := map[string]tenantpreference.Tenant{
		"tenant-001": {ID: "tenant-001", Slug: "alpha", Name: "Alpha Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
		"tenant-002": {ID: "tenant-002", Slug: "beta", Name: "Beta Market", DefaultLanguage: "tr-TR", Currency: "TRY", Status: "active"},
	}
	tenant, ok := tenants[tenantID]
	if !ok {
		return tenantpreference.Tenant{}, errors.New("tenant missing")
	}
	return tenant, nil
}

func (s *tenantPreferenceStore) GetPersistentTenantID(_ context.Context, userID string) (string, error) {
	tenantID, ok := s.persistent[userID]
	if !ok {
		return "", errors.New("preference missing")
	}
	return tenantID, nil
}

func (s *tenantPreferenceStore) SavePersistentTenantPreference(_ context.Context, preference tenantpreference.TenantPreference) error {
	s.persistent[preference.UserID] = preference.TenantID
	return nil
}

func (s *tenantPreferenceStore) SaveSessionTenantPreference(_ context.Context, preference tenantpreference.TenantPreference) error {
	s.session[preference.UserID+"|"+preference.SessionID] = preference
	return nil
}

type sessionStore struct {
	sessions map[string]sessiontimeout.SessionRecord
	touched  map[string]time.Time
	revoked  map[string]time.Time
	events   []sessiontimeout.SessionEvent
}

func (s *sessionStore) GetSessionByID(_ context.Context, sessionID string) (sessiontimeout.SessionRecord, error) {
	session, ok := s.sessions[sessionID]
	if !ok {
		return sessiontimeout.SessionRecord{}, errors.New("session missing")
	}
	return session, nil
}

func (s *sessionStore) TouchSession(_ context.Context, sessionID string, lastSeenAt time.Time) error {
	s.touched[sessionID] = lastSeenAt
	session := s.sessions[sessionID]
	session.LastSeenAt = lastSeenAt
	s.sessions[sessionID] = session
	return nil
}

func (s *sessionStore) RevokeSession(_ context.Context, sessionID string, revokedAt time.Time) error {
	s.revoked[sessionID] = revokedAt
	session := s.sessions[sessionID]
	session.RevokedAt = &revokedAt
	s.sessions[sessionID] = session
	return nil
}

func (s *sessionStore) RecordSessionEvent(_ context.Context, event sessiontimeout.SessionEvent) error {
	s.events = append(s.events, event)
	return nil
}

type loginErrorStore struct {
	events []loginerrors.Event
}

func (s *loginErrorStore) RecordLoginError(_ context.Context, event loginerrors.Event) error {
	s.events = append(s.events, event)
	return nil
}

type accessDenialStore struct {
	events []accessdenial.Event
}

func (s *accessDenialStore) RecordAccessDenial(_ context.Context, event accessdenial.Event) error {
	s.events = append(s.events, event)
	return nil
}
