#!/bin/bash
enable -f ../mailheaderclean.so mailheaderclean 2>/dev/null

TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

echo "=== Testing with debug output ==="
export MAILHEADERCLEAN="From"
builtin mailheaderclean "$TEST_FILE" 2>&1 | head -20
