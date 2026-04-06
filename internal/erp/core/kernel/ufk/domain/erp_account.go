package domain

type Account struct {
	Code      string
	Name      string
	ParentCode string
	Level     int
	IsLeaf    bool
	IsSystem  bool
}
