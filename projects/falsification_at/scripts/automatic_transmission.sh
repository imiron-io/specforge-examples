#!/bin/bash
set -e
# Redirect output of the source command to /dev/null
source .venv/bin/activate >/dev/null 2>&1
python3 scripts/automatic_transmission.py "$@"