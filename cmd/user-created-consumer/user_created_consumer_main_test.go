package main

import "testing"

func TestParseUserCreated_OK(t *testing.T) {
	data := []byte(`{
		"event":"user.created",
		"user_id":"1775967065371601283",
		"username":"ali",
		"created_at":"2026-04-11T14:40:05.371608945+03:00"
	}`)

	evt, err := parseUserCreated(data)
	if err != nil {
		t.Fatalf("beklenmeyen hata: %v", err)
	}

	if evt.Event != "user.created" {
		t.Fatalf("event yanlis: %s", evt.Event)
	}

	if evt.UserID != "1775967065371601283" {
		t.Fatalf("user_id yanlis: %s", evt.UserID)
	}

	if evt.Username != "ali" {
		t.Fatalf("username yanlis: %s", evt.Username)
	}
}

func TestParseUserCreated_MissingUserID(t *testing.T) {
	data := []byte(`{
		"event":"user.created",
		"user_id":"",
		"username":"ali"
	}`)

	_, err := parseUserCreated(data)
	if err == nil {
		t.Fatal("user_id bosken hata bekleniyordu")
	}
}
