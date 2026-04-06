package domain

type ExportRecord struct {
	RecordID    string
	TenantID    string
	TenantUUID  string
	Entity      string
	EntityID    string
	Content     string
}
