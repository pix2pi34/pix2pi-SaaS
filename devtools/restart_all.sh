#!/bin/bash
set -euo pipefail
"$(dirname "$0")/stop_all.sh"
sleep 1
"$(dirname "$0")/run_all.sh"
