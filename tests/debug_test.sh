#!/bin/bash
TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

enable -f ../mailheaderclean.so mailheaderclean 2>/dev/null

echo "=== Debug Test: MAILHEADERCLEAN='From' ==="
echo

echo "Expected: From should be REMOVED, Date should be KEPT"
echo

echo "Standalone:"
MAILHEADERCLEAN="From" ../mailheaderclean "$TEST_FILE" | grep "^From:" && echo "  ERROR: From found!" || echo "  ✓ From removed"
MAILHEADERCLEAN="From" ../mailheaderclean "$TEST_FILE" | grep "^Date:" && echo "  ✓ Date kept" || echo "  ERROR: Date missing!"
echo

echo "Builtin:"
MAILHEADERCLEAN="From" builtin mailheaderclean "$TEST_FILE" | grep "^From:" && echo "  ERROR: From found!" || echo "  ✓ From removed"
MAILHEADERCLEAN="From" builtin mailheaderclean "$TEST_FILE" | grep "^Date:" && echo "  ✓ Date kept" || echo "  ERROR: Date missing!"
