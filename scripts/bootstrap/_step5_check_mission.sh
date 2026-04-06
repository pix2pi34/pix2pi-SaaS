set -e
echo "== ss =="
ss -lntp | grep -E ':5860' || echo "HATA: 5860 dinlemiyor"

echo ""
echo "== curl =="
curl -sS http://127.0.0.1:5860/health || true
echo ""
echo "OK ✅ step5 bitti"
