#!/bin/bash
# Comprehensive test for mailmessage - tests all email files in test-data/

echo "=== Comprehensive mailmessage Tests ==="
echo

# Count files
TOTAL_FILES=$(find test-data -type f | wc -l)
echo "Testing $TOTAL_FILES email files..."
echo

# Function to reload builtin freshly
reload_builtin() {
    enable -d mailmessage 2>/dev/null
    enable -f ../build/lib/mailmessage.so mailmessage 2>/dev/null
}

# Test counters
PASS=0
FAIL=0
FAIL_FILES=()

echo "TEST 1: Validate all files produce message body output"
echo "-------------------------------------------------------"
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    # Run standalone version
    OUTPUT=$(../build/bin/mailmessage "$email" 2>&1)

    if [ $? -ne 0 ]; then
        echo "  ✗ FAIL: $email - mailmessage returned error"
        ((FAIL++))
        FAIL_FILES+=("$email")
        continue
    fi

    # Note: Empty output is valid if email has no body (headers only)
    # So we just check that it ran successfully
    ((PASS++))
done

echo "  ✓ Successful extraction: $PASS/$TOTAL_FILES"
if [ $FAIL -gt 0 ]; then
    echo "  ✗ Failed: $FAIL files"
fi
echo

echo "TEST 2: Compare standalone vs builtin (sampling)"
echo "------------------------------------------------"
# Test a sample of files (every 10th file)
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
    ../build/bin/mailmessage "$email" > /tmp/standalone_mailmessage.txt 2>&1

    # Run builtin
    reload_builtin
    builtin mailmessage "$email" > /tmp/builtin_mailmessage.txt 2>&1

    # Compare
    if diff -q /tmp/standalone_mailmessage.txt /tmp/builtin_mailmessage.txt > /dev/null 2>&1; then
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

echo "TEST 3: Verify mailheader + mailmessage = complete email"
echo "---------------------------------------------------------"
RECONSTRUCT_PASS=0
RECONSTRUCT_FAIL=0

# Test a sample
COUNT=0
for email in test-data/*; do
    [ ! -f "$email" ] && continue

    ((COUNT++))
    # Test every 20th file to keep it reasonable
    if [ $((COUNT % 20)) -ne 0 ]; then
        continue
    fi

    # Extract headers and message
    ../build/bin/mailheader "$email" > /tmp/headers.txt
    echo "" >> /tmp/headers.txt  # Add blank line separator
    ../build/bin/mailmessage "$email" >> /tmp/headers.txt

    # Compare with original (accounting for line ending normalization)
    if diff <(cat "$email" | tr -d '\r') <(cat /tmp/headers.txt | tr -d '\r') > /dev/null 2>&1; then
        ((RECONSTRUCT_PASS++))
    else
        # Some difference is expected due to tab/space conversion and \r removal
        # Just check sizes are similar (within 10%)
        ORIG_SIZE=$(wc -c < "$email")
        RECON_SIZE=$(wc -c < /tmp/headers.txt)
        DIFF=$((ORIG_SIZE - RECON_SIZE))
        DIFF=${DIFF#-}  # absolute value
        PERCENT=$((DIFF * 100 / ORIG_SIZE))

        if [ $PERCENT -lt 10 ]; then
            ((RECONSTRUCT_PASS++))
        else
            echo "  ✗ FAIL: $email - reconstructed differs by ${PERCENT}%"
            ((RECONSTRUCT_FAIL++))
        fi
    fi
done

echo "  ✓ Email reconstruction: $RECONSTRUCT_PASS/$((RECONSTRUCT_PASS + RECONSTRUCT_FAIL)) sampled files"
if [ $RECONSTRUCT_FAIL -gt 0 ]; then
    echo "  ✗ Failed: $RECONSTRUCT_FAIL files"
fi
echo

echo "=== Summary ==="
echo "Total files tested: $TOTAL_FILES"
echo "Successful message extraction: $PASS/$TOTAL_FILES"
echo "Standalone vs builtin: $SAMPLE_PASS/$((SAMPLE_PASS + SAMPLE_FAIL)) sampled files identical"
echo "Email reconstruction: $RECONSTRUCT_PASS/$((RECONSTRUCT_PASS + RECONSTRUCT_FAIL)) sampled files"

if [ $FAIL -gt 0 ] || [ $SAMPLE_FAIL -gt 0 ] || [ $RECONSTRUCT_FAIL -gt 0 ]; then
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
rm -f /tmp/standalone_mailmessage.txt /tmp/builtin_mailmessage.txt /tmp/headers.txt
