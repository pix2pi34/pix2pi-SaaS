#!/usr/bin/env bash
set -e

ROOT="$HOME/pix2pi/pix2pi-SaaS"
OUT="$ROOT/step_46i_consumer_recon.txt"

echo "OK ✅ rapor olustu -> $OUT"

{
  echo "==== STEP 46I / CONSUMER RECON ===="
  echo

  echo "==== 1) CMD DOSYALARI ===="
  cd "$ROOT"
  find cmd -maxdepth 2 -type f | sort
  echo

  echo "==== 2) NATS CONNECT ===="
  grep -Rni "nats.Connect\|nats.NewConn\|DefaultURL\|NATS_URL" cmd internal || true
  echo

  echo "==== 3) SUBSCRIBE SATIRLARI ===="
  grep -Rni "Subscribe\|QueueSubscribe\|ChanSubscribe\|PullSubscribe" cmd internal || true
  echo

  echo "==== 4) user.created / user subject ===="
  grep -Rni "user.created\|user_\|users\." cmd internal || true
  echo

  echo "==== 5) event consumer / subscriber / reporting ===="
  grep -Rni "consumer\|subscriber\|reporting" cmd internal || true
  echo

  echo "==== 6) read_users / read model ===="
  grep -Rni "read_users\|query_read_model\|user_count" cmd internal || true
  echo

  echo "==== 7) event publish noktaları ===="
  grep -Rni "Publish(" cmd internal || true
  echo

  echo "==== 8) identity register / create ===="
  grep -Rni "register\|CreateUser\|user created\|user_created" cmd internal || true
  echo

  echo "==== 9) SONUC ===="
  echo "Bu rapor sonraki adimda mevcut consumeri patchlemek icin kullanilacak."
} > "$OUT"

echo
echo "===== RAPOR ON IZLEME ====="
sed -n '1,260p' "$OUT"

echo
echo "OK ✅ STEP 46I tamam"
