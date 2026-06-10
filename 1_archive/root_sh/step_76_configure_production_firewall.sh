#!/bin/bash
set -e

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp

ufw --force enable
ufw status verbose

echo "OK ✅ production firewall ayari bitti"
