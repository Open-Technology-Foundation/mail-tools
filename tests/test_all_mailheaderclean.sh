#!/bin/bash
# Comprehensive test for mailheaderclean - tests all email files in test-data/

echo "=== Comprehensive mailheaderclean Tests ==="
echo

# Count files
TOTAL_FILES=$(find test-data -type f | wc -l)
echo "Testing $TOTAL_FILES email files..."
echo

# Function to reload builtin freshly
reload_builtin() {
    enable -d mailheaderclean 2>/dev/null
    enable -f ../mailheaderclean.so mailheaderclean 2>/dev/null
}

# Test counters
PASS=0
FAIL=0
FAIL_FILES=()

echo "TEST 1: Validate all files produce valid email output"
echo "------------------------------------------------------"
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    # Run standalone version
    OUTPUT=$(../mailheaderclean "$email" 2>&1)

    if [ $? -ne 0 ]; then
        echo "  ✗ FAIL: $email - mailheaderclean returned error"
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

    # Check output has header-like lines
    if ! echo "$OUTPUT" | grep -qE '^[A-Za-z-]+:'; then
        echo "  ✗ FAIL: $email - output doesn't contain headers"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    # Check output has blank line separator (headers/body separator)
    if ! echo "$OUTPUT" | grep -q '^$'; then
        echo "  ✗ FAIL: $email - missing header/body separator"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    ((PASS++))
done

echo "  ✓ Valid email output: $PASS/$TOTAL_FILES"
if [ $FAIL -gt 0 ]; then
    echo "  ✗ Failed: $FAIL files"
fi
echo

echo "TEST 2: Compare standalone vs builtin (sampling)"
echo "------------------------------------------------"
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
    ../mailheaderclean "$email" > /tmp/standalone_clean.txt 2>&1

    # Run builtin
    reload_builtin
    builtin mailheaderclean "$email" > /tmp/builtin_clean.txt 2>&1

    # Compare
    if diff -q /tmp/standalone_clean.txt /tmp/builtin_clean.txt > /dev/null 2>&1; then
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

echo "TEST 3: Verify bloat headers are removed"
echo "-----------------------------------------"
REMOVE_PASS=0
REMOVE_FAIL=0

# Test a sample to check that bloat headers are actually removed
COUNT=0
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    ((COUNT++))
    if [ $((COUNT % 20)) -ne 0 ]; then
        continue
    fi

    # Check if original has X-Spam headers
    if grep -qi '^X-Spam-' "$email"; then
        # Cleaned version should not have them
        if ../mailheaderclean "$email" | grep -qi '^X-Spam-'; then
            echo "  ✗ FAIL: $email - X-Spam headers not removed"
            ((REMOVE_FAIL++))
            continue
        fi
    fi

    # Check if original has Received headers (should keep only first one)
    ORIG_RECEIVED=$(grep -c '^Received:' "$email" || true)
    CLEAN_RECEIVED=$(../mailheaderclean "$email" | grep -c '^Received:' || true)

    if [ $ORIG_RECEIVED -gt 1 ] && [ $CLEAN_RECEIVED -ne 1 ]; then
        echo "  ✗ FAIL: $email - should have exactly 1 Received header (has $CLEAN_RECEIVED)"
        ((REMOVE_FAIL++))
        continue
    fi

    ((REMOVE_PASS++))
done

echo "  ✓ Bloat headers removed: $REMOVE_PASS/$((REMOVE_PASS + REMOVE_FAIL)) sampled files"
if [ $REMOVE_FAIL -gt 0 ]; then
    echo "  ✗ Failed: $REMOVE_FAIL files"
fi
echo

echo "TEST 4: Verify message body is preserved"
echo "-----------------------------------------"
BODY_PASS=0
BODY_FAIL=0

COUNT=0
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    ((COUNT++))
    if [ $((COUNT % 20)) -ne 0 ]; then
        continue
    fi

    # Extract body from original
    ../mailmessage "$email" > /tmp/orig_body.txt

    # Extract body from cleaned version
    ../mailheaderclean "$email" | ../mailmessage /dev/stdin > /tmp/clean_body.txt 2>/dev/null

    # Compare bodies (should be identical)
    if diff -q /tmp/orig_body.txt /tmp/clean_body.txt > /dev/null 2>&1; then
        ((BODY_PASS++))
    else
        echo "  ✗ FAIL: $email - message body was modified"
        ((BODY_FAIL++))
    fi
done

echo "  ✓ Body preserved: $BODY_PASS/$((BODY_PASS + BODY_FAIL)) sampled files"
if [ $BODY_FAIL -gt 0 ]; then
    echo "  ✗ Failed: $BODY_FAIL files"
fi
echo

echo "TEST 5: Environment variables (sample test)"
echo "--------------------------------------------"
# Pick one file for env var testing
TEST_EMAIL=$(find test-data -type f | head -1)

# Test MAILHEADERCLEAN_PRESERVE
../mailheaderclean "$TEST_EMAIL" > /tmp/default.txt
MAILHEADERCLEAN_PRESERVE="X-Spam-Status" ../mailheaderclean "$TEST_EMAIL" > /tmp/preserve.txt

# If original had X-Spam-Status, preserved version should have it
if grep -q '^X-Spam-Status:' "$TEST_EMAIL"; then
    if grep -q '^X-Spam-Status:' /tmp/preserve.txt; then
        echo "  ✓ MAILHEADERCLEAN_PRESERVE works"
    else
        echo "  ✗ MAILHEADERCLEAN_PRESERVE failed"
    fi
else
    echo "  ℹ MAILHEADERCLEAN_PRESERVE not testable (no X-Spam-Status in sample)"
fi

# Test MAILHEADERCLEAN (custom list)
MAILHEADERCLEAN="From,To" ../mailheaderclean "$TEST_EMAIL" > /tmp/custom.txt
if ! grep -q '^From:' /tmp/custom.txt && ! grep -q '^To:' /tmp/custom.txt; then
    echo "  ✓ MAILHEADERCLEAN works"
else
    echo "  ✗ MAILHEADERCLEAN failed"
fi

# Test MAILHEADERCLEAN_EXTRA
MAILHEADERCLEAN_EXTRA="Subject" ../mailheaderclean "$TEST_EMAIL" > /tmp/extra.txt
if ! grep -q '^Subject:' /tmp/extra.txt; then
    echo "  ✓ MAILHEADERCLEAN_EXTRA works"
else
    echo "  ✗ MAILHEADERCLEAN_EXTRA failed"
fi
echo

echo "=== Summary ==="
echo "Total files: $TOTAL_FILES"
echo "Valid email output: $PASS/$TOTAL_FILES"
echo "Standalone vs builtin: $SAMPLE_PASS/$((SAMPLE_PASS + SAMPLE_FAIL)) sampled files identical"
echo "Bloat headers removed: $REMOVE_PASS/$((REMOVE_PASS + REMOVE_FAIL)) sampled files"
echo "Body preserved: $BODY_PASS/$((BODY_PASS + BODY_FAIL)) sampled files"

if [ $FAIL -gt 0 ] || [ $SAMPLE_FAIL -gt 0 ] || [ $REMOVE_FAIL -gt 0 ] || [ $BODY_FAIL -gt 0 ]; then
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
rm -f /tmp/standalone_clean.txt /tmp/builtin_clean.txt /tmp/orig_body.txt /tmp/clean_body.txt
rm -f /tmp/default.txt /tmp/preserve.txt /tmp/custom.txt /tmp/extra.txt
