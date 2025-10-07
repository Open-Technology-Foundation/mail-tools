#!/bin/bash
# Validate that mailheaderclean produces valid RFC 822 email format

echo "=== RFC 822 EMAIL FORMAT VALIDATION ==="
echo

total_files=0
passed_files=0

for file in test-data/*; do
    total_files=$((total_files + 1))
    filename=$(basename "$file")

    # Run mailheaderclean
    output=$(../build/bin/mailheaderclean "$file")

    # Test 1: Has headers section
    headers_end=$(echo "$output" | grep -n "^$" | head -1 | cut -d: -f1)
    if [ -z "$headers_end" ]; then
        echo "❌ $filename: No header/body separator"
        continue
    fi

    # Test 2: Headers before blank line, body after
    header_count=$((headers_end - 1))
    total_lines=$(echo "$output" | wc -l)
    body_count=$((total_lines - headers_end))

    if [ "$header_count" -lt 1 ]; then
        echo "❌ $filename: No headers"
        continue
    fi

    if [ "$body_count" -lt 1 ]; then
        echo "❌ $filename: No message body"
        continue
    fi

    # Test 3: All header lines either start with letter or whitespace
    invalid_headers=$(echo "$output" | head -n $header_count | grep -v "^[A-Za-z]" | grep -v "^[ \t]" | wc -l)
    if [ "$invalid_headers" -gt 0 ]; then
        echo "❌ $filename: Invalid header lines found"
        echo "$output" | head -n $header_count | grep -v "^[A-Za-z]" | grep -v "^[ \t]"
        continue
    fi

    # Test 4: All non-continuation headers have colons
    missing_colons=$(echo "$output" | head -n $header_count | grep "^[A-Za-z]" | grep -v ":" | wc -l)
    if [ "$missing_colons" -gt 0 ]; then
        echo "❌ $filename: Header lines missing colons"
        continue
    fi

    # Test 5: Body content preserved exactly
    orig_body_start=$(grep -n "^$" "$file" | head -1 | cut -d: -f1)
    orig_body=$(tail -n +$((orig_body_start + 1)) "$file")
    clean_body=$(echo "$output" | tail -n +$((headers_end + 1)))

    if [ "$orig_body" != "$clean_body" ]; then
        echo "❌ $filename: Body content modified"
        continue
    fi

    # Test 6: Essential headers present
    has_from=$(echo "$output" | head -n $header_count | grep -i "^From:" | wc -l)
    has_date=$(echo "$output" | head -n $header_count | grep -i "^Date:" | wc -l)

    if [ "$has_from" -eq 0 ] || [ "$has_date" -eq 0 ]; then
        echo "⚠  $filename: Missing From/Date (Headers: $header_count, Body: $body_count lines)"
    else
        echo "✓  $filename: Valid RFC 822 (Headers: $header_count, Body: $body_count lines)"
        passed_files=$((passed_files + 1))
    fi
done

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed_files/$total_files files passed validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$passed_files" -eq "$total_files" ]; then
    echo "✓ All files produce valid RFC 822 email format"
    exit 0
else
    echo "❌ Some files failed validation"
    exit 1
fi
