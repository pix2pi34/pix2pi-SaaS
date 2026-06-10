#!/bin/bash
set -e

mkdir -p ~/pix2pi/fail2ban-backups

cp -a /etc/fail2ban /root/pix2pi/fail2ban-backups/fail2ban_before_nginx_jail_$(date +%Y%m%d_%H%M%S)

echo "OK ✅ fail2ban yedegi alindi"
