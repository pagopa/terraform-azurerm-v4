#!/bin/sh

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install pyyaml
python3 .scripts/idh_doc_gen.py
echo "p_exit: $?"
rm -rf .venv
echo "rm_exit: $?"
