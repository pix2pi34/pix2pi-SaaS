#!/bin/bash
set -e

FILE=~/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go

echo "=== BACKUP ==="
cp $FILE ${FILE}.bak_$(date +%s)

echo "=== PATCH /status handler ==="

awk '
/http.HandleFunc\("\/status"/ {
    print
    getline
    print "        mu.RLock()"
    print "        defer mu.RUnlock()"
    print ""
    print "        global := computeGlobalStatus(current.Services)"
    print ""
    print "        writeJSON(w, http.StatusOK, map[string]any{"
    print "            \"services\": current.Services,"
    print "            \"updated_at\": current.UpdatedAt,"
    print "            \"global_status\": global,"
    print "        })"
    skip=1
    next
}

skip==1 && /\}/ {
    skip=0
    next
}

skip!=1 { print }

' $FILE > ${FILE}.tmp

mv ${FILE}.tmp $FILE

echo "OK ✅ status handler override edildi"
