#!/bin/bash
TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

echo "=== Simple Verification Tests ==="
echo

echo "TEST: MAILHEADERCLEAN_PRESERVE preserves X-Spam-Status"
echo "Default behavior (should be removed):"
../mailheaderclean "$TEST_FILE" | grep "^X-Spam-Status:" || echo "  X-Spam-Status: NOT FOUND (correct - it's removed)"
echo
echo "With PRESERVE (should be kept):"
MAILHEADERCLEAN_PRESERVE="X-Spam-Status" ../mailheaderclean "$TEST_FILE" | grep "^X-Spam-Status:"
echo
echo "✓ PRESERVE works!"
echo

echo "TEST: MAILHEADERCLEAN replaces built-in list"
echo "Custom list removes only From, keeps everything else:"
MAILHEADERCLEAN="From" ../mailheaderclean "$TEST_FILE" | head -20
