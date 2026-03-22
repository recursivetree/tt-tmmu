#!/bin/bash
source ~/ttsetup/venv/bin/activate

export PDK_ROOT=~/ttsetup/pdk
export PDK=ihp-sg13g2
export LIBRELANE_TAG=3.0.0rc1

cd test
TOP_MODULE=$(cd .. && ./tt/tt_tool.py --print-top-module)
cp ../runs/wokwi/final/nl/$TOP_MODULE.nl.v gate_level_netlist.v
make -B GATES=yes