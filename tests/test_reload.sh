#!/bin/bash
TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

# Disable any existing builtin
enable -d mailheaderclean 2>/dev/null

# Load from current directory
enable -f ../mailheaderclean.so mailheaderclean

echo "Builtin loaded from: $(enable -a | grep mailheaderclean)"
echo

export MAILHEADERCLEAN="From"
echo "Test with MAILHEADERCLEAN='From'"
builtin mailheaderclean "$TEST_FILE" | grep "^From:" && echo "ERROR: From found!" || echo "OK: From removed"
builtin mailheaderclean "$TEST_FILE" | grep "^Date:" && echo "OK: Date kept" || echo "ERROR: Date missing!"
