package main

import (
	"testing"
	"time"
)

func TestRegistryRegisterAndList(t *testing.T) {
	registry := NewRegistry(1 * time.Minute)

	registry.Register("stock_service", "http://127.0.0.1:7001", "HTTP")
	liste := registry.List()

	if len(liste) != 1 {
		t.Fatalf("beklenen 1 servis, gelen %d", len(liste))
	}

	if liste[0].Name != "stock_service" {
		t.Fatalf("beklenen stock_service, gelen %s", liste[0].Name)
	}

	if liste[0].Status != "RUNNING" {
		t.Fatalf("beklenen RUNNING, gelen %s", liste[0].Status)
	}

	if liste[0].Source != "HTTP" {
		t.Fatalf("beklenen HTTP, gelen %s", liste[0].Source)
	}
}

func TestRegistryHeartbeat(t *testing.T) {
	registry := NewRegistry(1 * time.Minute)

	registry.Register("accounting_service", "http://127.0.0.1:7002", "NATS")
	ok := registry.Heartbeat("accounting_service", "NATS")
	if !ok {
		t.Fatal("heartbeat false dondu")
	}

	yok := registry.Heartbeat("olmayan_servis", "NATS")
	if yok {
		t.Fatal("olmayan servis icin heartbeat true dondu")
	}
}
