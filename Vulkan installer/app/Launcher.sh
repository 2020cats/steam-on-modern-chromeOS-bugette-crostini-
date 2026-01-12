#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

#launches the app
cd "$SCRIPT_DIR"

python3 "appUI.py"
