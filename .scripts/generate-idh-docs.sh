#!/bin/sh

python3 -m venv .venv
source .venv/bin/activate
python3 -W "ignore" -m pip install pyyaml --break-system-packages
python3 -W "ignore" IDH/01_utils/doc_gen.py
deactivate
rm -rf .venv
