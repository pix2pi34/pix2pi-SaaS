#!/bin/bash
set -e

echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

cat /etc/resolv.conf

echo "OK ✅ DNS resolver duzeltildi"
