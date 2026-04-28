#!/bin/bash
set -e
source .venv/bin/activate
python3 scripts/f16.py "$@"