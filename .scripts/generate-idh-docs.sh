#!/bin/sh

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install pyyaml
echo "BELLO"
python3 .scripts/idh_doc_gen.py
echo "MA NON BALLA"
deactivate
rm -rf .venv
