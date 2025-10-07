#!/bin/bash
# Comprehensive test script for mailheaderclean

echo "=== COMPREHENSIVE MAILHEADERCLEAN VALIDATION ==="
echo

# Test each file
for file in test-data/*; do
    filename=$(basename "$file")
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $filename"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run mailheaderclean
    cleaned=$(../build/bin/mailheaderclean "$file")

    # Test 1: Non-empty output
    if [ -z "$cleaned" ]; then
        echo "❌ FAIL: Empty output"
        continue
    fi
    echo "✓ Output is non-empty"

    # Test 2: Blank line separator exists
    blank_line=$(echo "$cleaned" | grep -n "^$" | head -1 | cut -d: -f1)
    if [ -z "$blank_line" ]; then
        echo "❌ FAIL: No blank line separator"
        continue
    fi
    echo "✓ Blank line separator at line $blank_line"

    # Test 3: Headers before blank line
    header_lines=$((blank_line - 1))
    if [ "$header_lines" -lt 1 ]; then
        echo "❌ FAIL: No headers found"
        continue
    fi
    echo "✓ Headers section: $header_lines lines"

    # Test 4: Body after blank line
    total_lines=$(echo "$cleaned" | wc -l)
    body_lines=$((total_lines - blank_line))
    if [ "$body_lines" -lt 1 ]; then
        echo "❌ FAIL: No message body"
        continue
    fi
    echo "✓ Message body: $body_lines lines"

    # Test 5: Essential headers preserved
    has_from=$(echo "$cleaned" | grep -i "^From:" | wc -l)
    has_date=$(echo "$cleaned" | grep -i "^Date:" | wc -l)
    has_subject=$(echo "$cleaned" | grep -i "^Subject:" | wc -l)

    if [ "$has_from" -eq 0 ]; then
        echo "⚠ WARNING: No From: header"
    else
        echo "✓ From: header present"
    fi

    if [ "$has_date" -eq 0 ]; then
        echo "⚠ WARNING: No Date: header"
    else
        echo "✓ Date: header present"
    fi

    if [ "$has_subject" -eq 0 ]; then
        echo "⚠ WARNING: No Subject: header (might be intentional)"
    else
        echo "✓ Subject: header present"
    fi

    # Test 6: Bloat headers removed
    has_xoriginato=$(echo "$cleaned" | grep -i "^X-Original-To:" | wc -l)
    has_deliveredto=$(echo "$cleaned" | grep -i "^Delivered-To:" | wc -l)
    has_authresults=$(echo "$cleaned" | grep -i "^Authentication-Results:" | wc -l)

    if [ "$has_xoriginato" -gt 0 ]; then
        echo "❌ FAIL: X-Original-To: header still present"
    else
        echo "✓ X-Original-To: removed"
    fi

    if [ "$has_deliveredto" -gt 0 ]; then
        echo "❌ FAIL: Delivered-To: header still present"
    else
        echo "✓ Delivered-To: removed"
    fi

    if [ "$has_authresults" -gt 0 ]; then
        echo "❌ FAIL: Authentication-Results: header still present"
    else
        echo "✓ Authentication-Results: removed"
    fi

    # Test 7: Only one Received header
    received_count=$(echo "$cleaned" | grep -i "^Received:" | wc -l)
    if [ "$received_count" -gt 1 ]; then
        echo "❌ FAIL: Multiple Received: headers ($received_count found)"
    else
        echo "✓ Received: header count: $received_count (max 1 expected)"
    fi

    # Test 8: Continuation lines properly formatted
    # Check if continuation lines start with space/tab
    continuation_errors=$(echo "$cleaned" | awk -v blank="$blank_line" '
        NR < blank && NR > 1 {
            if (/^[ \t]/ && prev !~ /^[^ \t]/) {
                print "Line " NR " is continuation but previous line is also continuation"
            }
            prev = $0
        }
    ')

    if [ -n "$continuation_errors" ]; then
        echo "⚠ WARNING: Potential continuation line issues:"
        echo "$continuation_errors"
    else
        echo "✓ Continuation lines appear valid"
    fi

    # Test 9: Body content preserved (compare line count)
    orig_body_start=$(grep -n "^$" "$file" | head -1 | cut -d: -f1)
    orig_total=$(wc -l < "$file")
    orig_body_lines=$((orig_total - orig_body_start))

    if [ "$body_lines" -ne "$orig_body_lines" ]; then
        echo "❌ FAIL: Body line count mismatch (original: $orig_body_lines, cleaned: $body_lines)"
    else
        echo "✓ Body line count matches original: $body_lines lines"
    fi

    # Test 10: Body content exactly matches original
    orig_body=$(tail -n +$((orig_body_start + 1)) "$file")
    clean_body=$(echo "$cleaned" | tail -n +$((blank_line + 1)))

    if [ "$orig_body" != "$clean_body" ]; then
        echo "❌ FAIL: Body content differs from original"
        echo "   First difference:"
        diff <(echo "$orig_body" | head -5) <(echo "$clean_body" | head -5) | head -10
    else
        echo "✓ Body content exactly matches original"
    fi

    echo
done

echo "=== VALIDATION COMPLETE ==="
