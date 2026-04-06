set -e

sudo ufw allow 5860/tcp

echo "OK ✅ ufw allow 5860"
sudo ufw status verbose | sed -n '1,120p'
