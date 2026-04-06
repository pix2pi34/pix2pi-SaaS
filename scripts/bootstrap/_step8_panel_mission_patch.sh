set -e

cd /root/pix2pi/pix2pi-SaaS

FILE="cmd/control-panel/control_panel.go"

cp $FILE $FILE.bak_$(date +%s)

grep -q "MISSION_PORT" $FILE || sed -i '/DEV_TOKEN_PORT/a \ \ missionPort := os.Getenv("MISSION_PORT")\n\ \ if missionPort == "" {\n\ \ \ \ missionPort = "5860"\n\ \ }' $FILE

grep -q "Mission Control" $FILE || sed -i '/Dev Token/a \ \ missionStatus := check("http://127.0.0.1:"+missionPort+"/health")' $FILE

grep -q "Mission Control:" $FILE || sed -i '/Dev Token:/a \ \ fmt.Fprintf(w, "Mission Control: %s (/health)\\n", missionStatus)' $FILE

echo "OK ✅ mission control panel patch"
