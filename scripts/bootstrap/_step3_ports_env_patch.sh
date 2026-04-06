set -e

# yoksa ekle
grep -q '^MISSION_PORT=' /etc/pix2pi/ports.env || {
  echo "" >> /etc/pix2pi/ports.env
  echo "# Mission Control" >> /etc/pix2pi/ports.env
  echo "MISSION_PORT=5860" >> /etc/pix2pi/ports.env
}

echo "OK ✅ ports.env güncel"
grep -nE '^(PANEL_PORT|IDENTITY_PORT|DEV_TOKEN_PORT|MISSION_PORT)=' /etc/pix2pi/ports.env || true
