#!/bin/bash
# Test mailgetheaders script

set -euo pipefail

echo "=== mailgetheaders Script Validation ==="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

PASS=0
FAIL=0

echo "TEST 1: Basic functionality with test.eml"
echo "-------------------------------------------"
if OUTPUT=$(scripts/mailgetheaders examples/test.eml 2>&1); then
    echo "  ✓ mailgetheaders executed successfully"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailgetheaders failed to execute"
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q "declare -A Headers="; then
    echo "  ✓ Output starts with declare -A Headers="
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Output doesn't contain declare -A Headers="
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q '\[From\]="sender@example.com"'; then
    echo "  ✓ From header extracted correctly"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: From header not found or incorrect"
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q '\[To\]="recipient@example.com"'; then
    echo "  ✓ To header extracted correctly"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: To header not found or incorrect"
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q '\[Subject\]="Test email with continuation line"'; then
    echo "  ✓ Subject header extracted correctly"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Subject header not found or incorrect"
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q '\[Date\]="Mon, 1 Jan 2025 12:00:00 +0000"'; then
    echo "  ✓ Date header extracted correctly"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Date header not found or incorrect"
    ((FAIL++)) || true
fi

if echo "$OUTPUT" | grep -q '\[file\]='; then
    echo "  ✓ File path included in output"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: File path not found in output"
    ((FAIL++)) || true
fi
echo

echo "TEST 2: Test with test-bloat.eml"
echo "-------------------------------------------"
if OUTPUT2=$(scripts/mailgetheaders examples/test-bloat.eml 2>&1); then
    echo "  ✓ mailgetheaders executed with test-bloat.eml"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailgetheaders failed with test-bloat.eml"
    ((FAIL++)) || true
fi

if echo "$OUTPUT2" | grep -q '\[From\]="sender@example.com"'; then
    echo "  ✓ From header extracted from bloat email"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: From header not extracted from bloat email"
    ((FAIL++)) || true
fi
echo

echo "TEST 3: Test output format is valid bash"
echo "-------------------------------------------"
# Try to evaluate the output as bash
if bash -c "$OUTPUT" 2>/dev/null; then
    echo "  ✓ Output is valid bash code"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Output is not valid bash code"
    ((FAIL++)) || true
fi
echo

echo "TEST 4: Test with multiple email files"
echo "-------------------------------------------"
TEST_COUNT=0
for email in tests/test-data/*; do
    [[ ! -f "$email" ]] && continue

    ((TEST_COUNT++))
    if ((TEST_COUNT > 10)); then
        break  # Only test first 10 files
    fi

    if scripts/mailgetheaders "$email" > /dev/null 2>&1; then
        ((PASS++)) || true
    else
        echo "  ✗ FAIL: mailgetheaders failed on $(basename "$email")"
        ((FAIL++)) || true
    fi
done

if ((TEST_COUNT > 0)); then
    echo "  ✓ Tested $TEST_COUNT email files successfully"
fi
echo

echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if ((FAIL > 0)); then
    echo "❌ mailgetheaders validation FAILED"
    exit 1
else
    echo "✅ mailgetheaders validation PASSED"
    exit 0
fi
