set -e

echo "OK ✅ step1: packages"
apt-get update -y
apt-get install -y rsync zstd coreutils

echo "OK ✅ step1: dirs"
BASE="/root/pix2pi/Back-Up/pix2pi-time-machine"
mkdir -p "$BASE"/{daily,hourly,logs,tmp}

echo "OK ✅ step1: show"
ls -lah /root/pix2pi/Back-Up || true
tree -a /root/pix2pi/Back-Up/pix2pi-time-machine || true

echo "OK ✅ step1 bitti"
