#!/bin/bash
set -e

apt-get update
apt-get install -y redis-tools

echo "OK ✅ redis-tools kuruldu"
