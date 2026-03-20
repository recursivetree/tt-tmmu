export PDK_ROOT := ~/ttsetup/pdk
export PDK := ihp-sg13g2
export LIBRELANE_TAG := 3.0.0rc1

harden:
	./tt/tt_tool.py --create-user-config --ihp
