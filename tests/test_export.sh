#!/bin/bash
TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

enable -f ../mailheaderclean.so mailheaderclean 2>/dev/null

echo "=== Testing with export ==="
echo

echo "Test 1: Inline variable (might not work with builtins)"
MAILHEADERCLEAN="From" builtin mailheaderclean "$TEST_FILE" | grep "^From:" && echo "  From FOUND (BUG)" || echo "  From removed (OK)"

echo

echo "Test 2: Exported variable (should work)"
export MAILHEADERCLEAN="From"
builtin mailheaderclean "$TEST_FILE" | grep "^From:" && echo "  From FOUND (BUG)" || echo "  From removed (OK)"
unset MAILHEADERCLEAN

echo

echo "Test 3: For comparison, standalone with inline"
MAILHEADERCLEAN="From" ../mailheaderclean "$TEST_FILE" | grep "^From:" && echo "  From FOUND (BUG)" || echo "  From removed (OK)"
