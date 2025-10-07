#!/bin/bash
# Test that builtin and standalone versions produce identical output

TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

# Function to reload builtin freshly
reload_builtin() {
    enable -d mailheaderclean 2>/dev/null
    enable -f ../build/lib/mailheaderclean.so mailheaderclean 2>/dev/null
}

echo "=== Comparing Standalone vs Builtin Output ==="
echo

echo "TEST 1: Default behavior"
../build/bin/mailheaderclean "$TEST_FILE" > /tmp/standalone_default.txt
reload_builtin
builtin mailheaderclean "$TEST_FILE" > /tmp/builtin_default.txt
if diff -q /tmp/standalone_default.txt /tmp/builtin_default.txt > /dev/null; then
    echo "  ✓ PASS: Identical output (default)"
else
    echo "  ✗ FAIL: Outputs differ (default)"
    diff /tmp/standalone_default.txt /tmp/builtin_default.txt | head -20
fi
echo

echo "TEST 2: With MAILHEADERCLEAN_PRESERVE"
MAILHEADERCLEAN_PRESERVE="X-Spam-Status,X-Priority" ../build/bin/mailheaderclean "$TEST_FILE" > /tmp/standalone_preserve.txt
reload_builtin
export MAILHEADERCLEAN_PRESERVE="X-Spam-Status,X-Priority"
builtin mailheaderclean "$TEST_FILE" > /tmp/builtin_preserve.txt
unset MAILHEADERCLEAN_PRESERVE
if diff -q /tmp/standalone_preserve.txt /tmp/builtin_preserve.txt > /dev/null; then
    echo "  ✓ PASS: Identical output (PRESERVE)"
else
    echo "  ✗ FAIL: Outputs differ (PRESERVE)"
    diff /tmp/standalone_preserve.txt /tmp/builtin_preserve.txt | head -20
fi
echo

echo "TEST 3: With MAILHEADERCLEAN"
MAILHEADERCLEAN="From,To,Subject" ../build/bin/mailheaderclean "$TEST_FILE" > /tmp/standalone_custom.txt
reload_builtin
export MAILHEADERCLEAN="From,To,Subject"
builtin mailheaderclean "$TEST_FILE" > /tmp/builtin_custom.txt
unset MAILHEADERCLEAN
if diff -q /tmp/standalone_custom.txt /tmp/builtin_custom.txt > /dev/null; then
    echo "  ✓ PASS: Identical output (MAILHEADERCLEAN)"
else
    echo "  ✗ FAIL: Outputs differ (MAILHEADERCLEAN)"
    diff /tmp/standalone_custom.txt /tmp/builtin_custom.txt | head -20
fi
echo

echo "TEST 4: With MAILHEADERCLEAN_EXTRA"
MAILHEADERCLEAN_EXTRA="Reply-To,Message-ID" ../build/bin/mailheaderclean "$TEST_FILE" > /tmp/standalone_extra.txt
reload_builtin
export MAILHEADERCLEAN_EXTRA="Reply-To,Message-ID"
builtin mailheaderclean "$TEST_FILE" > /tmp/builtin_extra.txt
unset MAILHEADERCLEAN_EXTRA
if diff -q /tmp/standalone_extra.txt /tmp/builtin_extra.txt > /dev/null; then
    echo "  ✓ PASS: Identical output (EXTRA)"
else
    echo "  ✗ FAIL: Outputs differ (EXTRA)"
    diff /tmp/standalone_extra.txt /tmp/builtin_extra.txt | head -20
fi
echo

echo "TEST 5: Complex combination"
MAILHEADERCLEAN="From,X-Spam-Status" MAILHEADERCLEAN_PRESERVE="X-Spam-Status" MAILHEADERCLEAN_EXTRA="Reply-To" \
  ../build/bin/mailheaderclean "$TEST_FILE" > /tmp/standalone_complex.txt
reload_builtin
export MAILHEADERCLEAN="From,X-Spam-Status"
export MAILHEADERCLEAN_PRESERVE="X-Spam-Status"
export MAILHEADERCLEAN_EXTRA="Reply-To"
builtin mailheaderclean "$TEST_FILE" > /tmp/builtin_complex.txt
unset MAILHEADERCLEAN MAILHEADERCLEAN_PRESERVE MAILHEADERCLEAN_EXTRA
if diff -q /tmp/standalone_complex.txt /tmp/builtin_complex.txt > /dev/null; then
    echo "  ✓ PASS: Identical output (complex)"
else
    echo "  ✗ FAIL: Outputs differ (complex)"
    diff /tmp/standalone_complex.txt /tmp/builtin_complex.txt | head -20
fi
echo

echo "=== All Comparison Tests Complete ==="

# Cleanup
rm -f /tmp/standalone_*.txt /tmp/builtin_*.txt
