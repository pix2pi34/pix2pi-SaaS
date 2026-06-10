package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
)

type UserConfig struct {
	Users []User `json:"users"`
}

type User struct {
	Email               string `json:"email"`
	Password            string `json:"password"`
	DisplayName         string `json:"display_name"`
	Role                string `json:"role"`
	ScopeType           string `json:"scope_type"`
	ScopeID             string `json:"scope_id"`
	RemoteAccessAllowed bool   `json:"remote_access_allowed"`
	ReactRedirect       string `json:"react_redirect"`
	Vue3Redirect        string `json:"vue3_redirect"`
}

type OTPEntry struct {
	Email     string `json:"email"`
	Hash      string `json:"hash"`
	ExpiresAt int64  `json:"expires_at"`
	Attempts  int    `json:"attempts"`
}

type OTPStore struct {
	Entries map[string]OTPEntry `json:"entries"`
}

type Server struct {
	addr        string
	usersFile   string
	stateDir    string
	stateFile   string
	otpSecret   string
	otpTTL      int64
	maxAttempts int
	mailFrom    string
	mu          sync.Mutex
}

func env(name, fallback string) string {
	value := strings.TrimSpace(os.Getenv(name))
	if value == "" {
		return fallback
	}
	return value
}

func sha256Hex(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func randomCode() (string, error) {
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (s *Server) loadUsers() ([]User, error) {
	data, err := os.ReadFile(s.usersFile)
	if err != nil {
		return nil, err
	}

	var cfg UserConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	return cfg.Users, nil
}

func (s *Server) findUser(email string) (*User, error) {
	users, err := s.loadUsers()
	if err != nil {
		return nil, err
	}

	email = normalizeEmail(email)

	for _, user := range users {
		if normalizeEmail(user.Email) == email {
			u := user
			return &u, nil
		}
	}

	return nil, errors.New("user not found")
}

func (s *Server) otpHash(email, code string) string {
	return sha256Hex(fmt.Sprintf("%s:%s:%s", normalizeEmail(email), strings.TrimSpace(code), s.otpSecret))
}

func (s *Server) loadStore() OTPStore {
	store := OTPStore{Entries: map[string]OTPEntry{}}

	data, err := os.ReadFile(s.stateFile)
	if err != nil {
		return store
	}

	if err := json.Unmarshal(data, &store); err != nil {
		return OTPStore{Entries: map[string]OTPEntry{}}
	}

	if store.Entries == nil {
		store.Entries = map[string]OTPEntry{}
	}

	return store
}

func (s *Server) saveStore(store OTPStore) error {
	if err := os.MkdirAll(s.stateDir, 0700); err != nil {
		return err
	}

	data, err := json.MarshalIndent(store, "", "  ")
	if err != nil {
		return err
	}

	tmp := s.stateFile + ".tmp"
	if err := os.WriteFile(tmp, data, 0600); err != nil {
		return err
	}

	return os.Rename(tmp, s.stateFile)
}

func (s *Server) storeOTP(email, code string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	store := s.loadStore()
	email = normalizeEmail(email)

	store.Entries[email] = OTPEntry{
		Email:     email,
		Hash:      s.otpHash(email, code),
		ExpiresAt: time.Now().Unix() + s.otpTTL,
		Attempts:  0,
	}

	return s.saveStore(store)
}

func (s *Server) consumeOTP(email, code string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	store := s.loadStore()
	email = normalizeEmail(email)

	entry, ok := store.Entries[email]
	if !ok {
		return false
	}

	if time.Now().Unix() > entry.ExpiresAt {
		delete(store.Entries, email)
		_ = s.saveStore(store)
		return false
	}

	if entry.Attempts >= s.maxAttempts {
		delete(store.Entries, email)
		_ = s.saveStore(store)
		return false
	}

	entry.Attempts++
	store.Entries[email] = entry

	if entry.Hash != s.otpHash(email, code) {
		_ = s.saveStore(store)
		return false
	}

	delete(store.Entries, email)
	_ = s.saveStore(store)

	return true
}

func (s *Server) sendEmail(to, code string) error {
	subject := "Pix2pi giriş doğrulama kodu"
	body := fmt.Sprintf("Pix2pi giriş doğrulama kodunuz: %s\n\nBu kod 5 dakika geçerlidir.\nBu girişi siz başlatmadıysanız bu maili dikkate almayın.\n", code)

	message := fmt.Sprintf(
		"From: Pix2pi <%s>\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\n%s",
		s.mailFrom,
		to,
		subject,
		body,
	)

	for _, p := range []string{"/usr/sbin/sendmail", "/usr/bin/sendmail", "sendmail"} {
		if strings.HasPrefix(p, "/") {
			if _, statErr := os.Stat(p); statErr != nil {
				continue
			}
		} else if _, err := exec.LookPath(p); err != nil {
			continue
		}

		cmd := exec.Command(p, "-t", "-oi")
		cmd.Stdin = strings.NewReader(message)
		out, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("sendmail failed: %v: %s", err, strings.TrimSpace(string(out)))
		}
		return nil
	}

	return errors.New("sendmail/msmtp bulunamadı")
}

func writeJSON(w http.ResponseWriter, status int, payload map[string]any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status":  "ok",
		"service": "pix2pi-customer-otp-auth",
		"marker":  "PIX2PI_ROLE_BASED_OTP_AUTH_HEALTH",
	})
}

func (s *Server) requestLoginCode(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		UI       string `json:"ui"`
	}

	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "message": "method not allowed"})
		return
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "message": "Geçersiz istek."})
		return
	}

	user, err := s.findUser(req.Email)
	if err != nil || user == nil {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"ok": false, "message": "Bu e-posta sistemde tanımlı değil."})
		return
	}

	if !user.RemoteAccessAllowed {
		writeJSON(w, http.StatusForbidden, map[string]any{"ok": false, "message": "Bu kullanıcı uzaktan panele giremez. POS/local cihazdan giriş yapmalıdır."})
		return
	}

	if req.Password != user.Password {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"ok": false, "message": "Şifre hatalı."})
		return
	}

	code, err := randomCode()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"ok": false, "message": "Kod üretilemedi."})
		return
	}

	if err := s.storeOTP(user.Email, code); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{"ok": false, "message": "Kod kaydedilemedi."})
		return
	}

	if err := s.sendEmail(user.Email, code); err != nil {
		log.Printf("mail send error email=%s err=%v", user.Email, err)
		writeJSON(w, http.StatusBadGateway, map[string]any{"ok": false, "message": "Kod üretildi ama mail gönderilemedi."})
		return
	}

	log.Printf("otp sent email=%s role=%s scope=%s", user.Email, user.Role, user.ScopeID)

	writeJSON(w, http.StatusOK, map[string]any{
		"ok":      true,
		"message": "Doğrulama kodu e-posta adresine gönderildi.",
	})
}

func (s *Server) verifyLoginCode(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
		UI    string `json:"ui"`
	}

	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "message": "method not allowed"})
		return
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "message": "Geçersiz istek."})
		return
	}

	user, err := s.findUser(req.Email)
	if err != nil || user == nil {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"ok": false, "message": "Kullanıcı bulunamadı."})
		return
	}

	if !s.consumeOTP(user.Email, req.Code) {
		writeJSON(w, http.StatusUnauthorized, map[string]any{"ok": false, "message": "Kod hatalı veya süresi doldu."})
		return
	}

	redirect := user.ReactRedirect
	if strings.ToLower(strings.TrimSpace(req.UI)) == "vue3" {
		redirect = user.Vue3Redirect
	}

	log.Printf("otp verified email=%s role=%s redirect=%s", user.Email, user.Role, redirect)

	writeJSON(w, http.StatusOK, map[string]any{
		"ok":           true,
		"message":      "Kod doğrulandı.",
		"redirect":     redirect,
		"display_name": user.DisplayName,
		"role":         user.Role,
		"scope_type":   user.ScopeType,
		"scope_id":     user.ScopeID,
	})
}

func main() {
	ttl, _ := strconv.ParseInt(env("PIX2PI_OTP_TTL_SECONDS", "300"), 10, 64)
	maxAttempts, _ := strconv.Atoi(env("PIX2PI_OTP_MAX_ATTEMPTS", "5"))

	stateDir := env("PIX2PI_AUTH_STATE_DIR", "/var/lib/pix2pi/customer-otp-auth")

	s := &Server{
		addr:        env("PIX2PI_AUTH_ADDR", "127.0.0.1:9027"),
		usersFile:   env("PIX2PI_AUTH_USERS_FILE", "/etc/pix2pi/customer-otp-users.json"),
		stateDir:    stateDir,
		stateFile:   filepath.Join(stateDir, "otp-store.json"),
		otpSecret:   env("PIX2PI_OTP_SECRET", ""),
		otpTTL:      ttl,
		maxAttempts: maxAttempts,
		mailFrom:    env("PIX2PI_MAIL_FROM", "no-reply@pix2pi.com.tr"),
	}

	if s.otpSecret == "" {
		log.Fatal("PIX2PI_OTP_SECRET zorunlu")
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/auth-api/health", s.health)
	mux.HandleFunc("/auth-api/request-login-code", s.requestLoginCode)
	mux.HandleFunc("/auth-api/verify-login-code", s.verifyLoginCode)

	log.Printf("pix2pi role based otp auth listening on %s", s.addr)

	if err := http.ListenAndServe(s.addr, mux); err != nil {
		log.Fatal(err)
	}
}
