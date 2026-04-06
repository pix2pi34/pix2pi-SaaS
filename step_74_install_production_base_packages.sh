#!/bin/bash
set -e

apt update

apt install -y \
  curl \
  git \
  ufw \
  ca-certificates \
  gnupg \
  lsb-release \
  apt-transport-https \
  unzip \
  jq \
  net-tools \
  htop

echo "OK ✅ production temel paketleri kuruldu"
