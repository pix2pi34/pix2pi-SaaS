#!/bin/bash
set -e

FILE=~/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go

echo "=== BACKUP ==="
cp $FILE ${FILE}.bak_clean_$(date +%s)

echo "=== FIX HANDLER (MANUAL) ==="

# status handler bloğunu komple yeniden yaz
sed -i '/http.HandleFunc("\/status"/,/^}/c\
    http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {\
        mu.RLock()\
        defer mu.RUnlock()\
\
        global := computeGlobalStatus(current.Services)\
\
        writeJSON(w, http.StatusOK, map[string]any{\
            "services": current.Services,\
            "updated_at": current.UpdatedAt,\
            "global_status": global,\
        })\
    })' $FILE

echo "OK ✅ handler temiz şekilde yazıldı"
