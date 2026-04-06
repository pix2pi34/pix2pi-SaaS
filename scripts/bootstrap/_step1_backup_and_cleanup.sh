set -e

cd /root/pix2pi/pix2pi-SaaS

mkdir -p /root/pix2pi/_bak/mission-control

if [ -f cmd/mission-control/main.go ]; then
  cp -f cmd/mission-control/main.go /root/pix2pi/_bak/mission-control/main.go.bak_$(date +%Y%m%d_%H%M%S)
  echo "OK ✅ backup alındı: cmd/mission-control/main.go"
fi

echo "OK ✅ step1 bitti"
