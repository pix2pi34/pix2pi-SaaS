package query_read_model

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	"gorm.io/gorm"
)

type Service struct{}

type UserProjection struct {
	UserID    string    `json:"user_id"`
	Username  string    `json:"username"`
	CreatedAt time.Time `json:"created_at"`
}

type ListMeta struct {
	TotalUsers    int64 `json:"total_users"`
	ReturnedCount int   `json:"returned_count"`
	Limit         int   `json:"limit"`
	Offset        int   `json:"offset"`
	HasMore       bool  `json:"has_more"`
	NextOffset    *int  `json:"next_offset,omitempty"`
	Source        string `json:"source"`
}

type ListUsersResult struct {
	Meta    ListMeta       `json:"meta"`
	Filters map[string]any `json:"filters,omitempty"`
	Users   []UserProjection `json:"users"`
}

func New() *Service {
	return &Service{}
}

func normalizeLimit(limit int) int {
	if limit <= 0 {
		return 20
	}
	if limit > 100 {
		return 100
	}
	return limit
}

func normalizeOffset(offset int) int {
	if offset < 0 {
		return 0
	}
	return offset
}

func normalizeUsername(username string) string {
	return strings.TrimSpace(username)
}

func getReadDBWithFallback() (*gorm.DB, string, error) {
	db := kernel.GetReadDB()
	source := "readDB"

	if db == nil {
		log.Println("WARN ⚠️ kernel readDB nil, writeDB fallback kullaniliyor")
		db = kernel.GetWriteDB()
		source = "writeDB"
	}

	if db == nil {
		return nil, "", fmt.Errorf("read ve write db nil")
	}

	return db, source, nil
}

func buildUserListSQL(username string) (string, string, []any) {
	where := ""
	args := make([]any, 0, 1)

	if username != "" {
		where = "WHERE username ILIKE ?"
		args = append(args, "%"+username+"%")
	}

	listSQL := fmt.Sprintf(`
SELECT user_id, username, created_at
FROM read_user_projection
%s
ORDER BY created_at DESC
LIMIT ? OFFSET ?
`, where)

	countSQL := fmt.Sprintf(`
SELECT COUNT(*)
FROM read_user_projection
%s
`, where)

	return listSQL, countSQL, args
}

func (s *Service) GetUsers() (int64, error) {
	db, source, err := getReadDBWithFallback()
	if err != nil {
		log.Println("ERROR ❌ hem readDB hem writeDB nil")
		return 0, err
	}

	var count int64
	err = db.Raw(`SELECT COALESCE(MAX(total_count), 0) FROM read_users`).Scan(&count).Error
	if err != nil {
		log.Println("ERROR ❌ read model query error:", err)
		return 0, err
	}

	log.Printf("OK ✅ read model user count: %d (source=%s)\n", count, source)
	return count, nil
}

func (s *Service) ListUsers(limit int) ([]UserProjection, error) {
	result, err := s.ListUsersAdvanced(limit, 0, "")
	if err != nil {
		return nil, err
	}
	return result.Users, nil
}

func (s *Service) ListUsersAdvanced(limit int, offset int, username string) (*ListUsersResult, error) {
	limit = normalizeLimit(limit)
	offset = normalizeOffset(offset)
	username = normalizeUsername(username)

	db, source, err := getReadDBWithFallback()
	if err != nil {
		log.Println("ERROR ❌ hem readDB hem writeDB nil")
		return nil, err
	}

	listSQL, countSQL, args := buildUserListSQL(username)

	var total int64
	if err := db.Raw(countSQL, args...).Scan(&total).Error; err != nil {
		log.Println("ERROR ❌ read model count query error:", err)
		return nil, err
	}

	listArgs := append(append([]any{}, args...), limit, offset)

	var users []UserProjection
	if err := db.Raw(listSQL, listArgs...).Scan(&users).Error; err != nil {
		log.Println("ERROR ❌ read model list query error:", err)
		return nil, err
	}

	hasMore := int64(offset+len(users)) < total

	var nextOffset *int
	if hasMore {
		v := offset + len(users)
		nextOffset = &v
	}

	var filters map[string]any
	if username != "" {
		filters = map[string]any{
			"username": username,
		}
	}

	log.Printf("OK ✅ read model users list: %d kayit (source=%s, limit=%d, offset=%d, username=%q)\n",
		len(users), source, limit, offset, username)

	return &ListUsersResult{
		Meta: ListMeta{
			TotalUsers:    total,
			ReturnedCount: len(users),
			Limit:         limit,
			Offset:        offset,
			HasMore:       hasMore,
			NextOffset:    nextOffset,
			Source:        source,
		},
		Filters: filters,
		Users:   users,
	}, nil
}

func (s *Service) GetUserByID(userID string) (*UserProjection, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return nil, fmt.Errorf("user_id bos")
	}

	db, source, err := getReadDBWithFallback()
	if err != nil {
		log.Println("ERROR ❌ hem readDB hem writeDB nil")
		return nil, err
	}

	var user UserProjection
	if err := db.Raw(`
SELECT user_id, username, created_at
FROM read_user_projection
WHERE user_id = ?
LIMIT 1
`, userID).Scan(&user).Error; err != nil {
		log.Println("ERROR ❌ read model detail query error:", err)
		return nil, err
	}

	if strings.TrimSpace(user.UserID) == "" {
		log.Printf("WARN ⚠️ user detail bulunamadi -> %s (source=%s)\n", userID, source)
		return nil, nil
	}

	log.Printf("OK ✅ read model user detail bulundu -> %s (source=%s)\n", userID, source)
	return &user, nil
}
