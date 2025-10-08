#!/bin/bash
# Comprehensive test for mailheader - tests all email files in test-data/

echo "=== Comprehensive mailheader Tests ==="
echo

# Count files (exclude hidden directories like .claude)
TOTAL_FILES=$(find test-data -type f -not -path '*/.*' | wc -l)
echo "Testing $TOTAL_FILES email files..."
echo

# Function to reload builtin freshly
reload_builtin() {
    enable -d mailheader 2>/dev/null
    enable -f ../build/lib/mailheader.so mailheader 2>/dev/null
}

# Test counters
PASS=0
FAIL=0
FAIL_FILES=()

echo "TEST 1: Validate all files produce valid header output"
echo "------------------------------------------------------"
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    # Run standalone version
    OUTPUT=$(../build/bin/mailheader "$email" 2>&1)

    if [ $? -ne 0 ]; then
        echo "  ✗ FAIL: $email - mailheader returned error"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    # Check output is not empty
    if [ -z "$OUTPUT" ]; then
        echo "  ✗ FAIL: $email - empty output"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    # Check output contains header-like lines (format: "Header: value")
    if ! echo "$OUTPUT" | grep -qE '^[A-Za-z-]+:'; then
        echo "  ✗ FAIL: $email - output doesn't look like headers"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    ((PASS++))
done

echo "  ✓ Valid header output: $PASS/$TOTAL_FILES"
if [ $FAIL -gt 0 ]; then
    echo "  ✗ Failed: $FAIL files"
fi
echo

echo "TEST 2: Compare standalone vs builtin (sampling)"
echo "------------------------------------------------"
# Test a sample of files (every 10th file) to avoid overwhelming output
SAMPLE_PASS=0
SAMPLE_FAIL=0
COUNT=0

for email in test-data/*; do
    [ ! -f "$email" ] && continue

    ((COUNT++))
    # Test every 10th file
    if [ $((COUNT % 10)) -ne 0 ]; then
        continue
    fi

    # Run standalone
    ../build/bin/mailheader "$email" > /tmp/standalone_mailheader.txt 2>&1

    # Run builtin
    reload_builtin
    builtin mailheader "$email" > /tmp/builtin_mailheader.txt 2>&1

    # Compare
    if diff -q /tmp/standalone_mailheader.txt /tmp/builtin_mailheader.txt > /dev/null 2>&1; then
        ((SAMPLE_PASS++))
    else
        echo "  ✗ FAIL: $email - standalone vs builtin differ"
        ((SAMPLE_FAIL++))
    fi
done

echo "  ✓ Identical output: $SAMPLE_PASS/$((SAMPLE_PASS + SAMPLE_FAIL)) files tested"
if [ $SAMPLE_FAIL -gt 0 ]; then
    echo "  ✗ Differences found: $SAMPLE_FAIL files"
fi
echo

echo "TEST 3: Verify headers end at blank line"
echo "-----------------------------------------"
CHECK_PASS=0
CHECK_FAIL=0

for email in test-data/*; do
    [ ! -f "$email" ] && continue

    # Get header output
    HEADERS=$(../build/bin/mailheader "$email")

    # Headers should not contain blank lines (should stop before first blank)
    if echo "$HEADERS" | grep -q '^$'; then
        echo "  ✗ FAIL: $email - headers contain blank line"
        ((CHECK_FAIL++))
    else
        ((CHECK_PASS++))
    fi
done

echo "  ✓ Headers properly terminated: $CHECK_PASS/$TOTAL_FILES"
if [ $CHECK_FAIL -gt 0 ]; then
    echo "  ✗ Failed: $CHECK_FAIL files"
fi
echo

echo "=== Summary ==="
echo "Total files tested: $TOTAL_FILES"
echo "Valid header extraction: $PASS/$TOTAL_FILES"
echo "Standalone vs builtin: $SAMPLE_PASS/$((SAMPLE_PASS + SAMPLE_FAIL)) sampled files identical"
echo "Proper termination: $CHECK_PASS/$TOTAL_FILES"

if [ $FAIL -gt 0 ] || [ $SAMPLE_FAIL -gt 0 ] || [ $CHECK_FAIL -gt 0 ]; then
    echo
    echo "⚠ Some tests failed"
    if [ ${#FAIL_FILES[@]} -gt 0 ]; then
        echo "Failed files:"
        for f in "${FAIL_FILES[@]}"; do
            echo "  - $f"
        done
    fi
    exit 1
else
    echo
    echo "✓ All tests passed!"
    exit 0
fi

# Cleanup
rm -f /tmp/standalone_mailheader.txt /tmp/builtin_mailheader.txt
