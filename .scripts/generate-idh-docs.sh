#!/bin/sh

apt install -y python3-virtualenv
virtualenv .venv
source .venv/bin/activate
python3 -W "ignore" -m pip install pyyaml --break-system-packages
python3 -W "ignore" .scripts/idh_doc_gen.py
deactivate
rm -rf .venv
