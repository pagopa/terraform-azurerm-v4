#!/bin/sh

python3 -m venv .venv
source ./.venv/bin/activate
python3 -m pip install pyyaml

python3 IDH/01_utils/doc_gen.py
