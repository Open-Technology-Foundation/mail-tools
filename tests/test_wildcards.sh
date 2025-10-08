#!/usr/bin/env bash
#
# test_wildcards.sh - Test wildcard pattern matching in mailheaderclean
#
# Tests fnmatch() wildcard support for header filtering

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_BIN="${SCRIPT_DIR}/../build/bin"
BUILD_LIB="${SCRIPT_DIR}/../build/lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test counters
test_count() {
    ((TOTAL_TESTS++)) || true
}

test_pass() {
    ((PASSED_TESTS++)) || true
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    ((FAILED_TESTS++)) || true
    echo -e "${RED}✗${NC} $1"
    [[ "${2:-}" ]] && echo "  Expected: $2" >&2
    [[ "${3:-}" ]] && echo "  Got: $3" >&2
}

# Create test email file
create_test_email() {
    cat <<'EOF'
From: sender@example.com
To: recipient@example.com
Subject: Test Email
Date: Mon, 1 Jan 2025 12:00:00 +0000
X-Spam-Status: Yes
X-Spam-Score: 5.0
X-Microsoft-Antispam: test
X-MS-Exchange-Test: value
X-Custom-Status: active
List-Unsubscribe: <mailto:unsub@example.com>
Content-Type: text/plain

This is the message body.
EOF
}

# Test if header exists in output
header_exists() {
    local output="$1"
    local header="$2"
    echo "$output" | grep -qi "^${header}:" && return 0 || return 1
}

# Test if header does NOT exist in output
header_not_exists() {
    local output="$1"
    local header="$2"
    ! header_exists "$output" "$header"
}

echo "Testing wildcard pattern support in mailheaderclean"
echo "=================================================="
echo

# Check if binaries exist
if [[ ! -f "${BUILD_BIN}/mailheaderclean" ]]; then
    echo -e "${RED}Error: ${BUILD_BIN}/mailheaderclean not found. Run 'make' first.${NC}"
    exit 1
fi

# Create temp directory for tests
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

TEST_EMAIL="${TEMP_DIR}/test.eml"
create_test_email > "$TEST_EMAIL"

echo "Test 1: Prefix wildcard (X-*)"
echo "------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_not_exists "$OUTPUT" "X-MS-Exchange-Test" && \
   header_exists "$OUTPUT" "From" && \
   header_exists "$OUTPUT" "Subject"; then
    test_pass "X-* removes all X- headers"
else
    test_fail "X-* pattern matching"
fi
echo

echo "Test 2: Suffix wildcard (*-Status)"
echo "-----------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="*-Status" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Custom-Status" && \
   header_exists "$OUTPUT" "X-Spam-Score" && \
   header_exists "$OUTPUT" "From"; then
    test_pass "*-Status removes all headers ending with -Status"
else
    test_fail "*-Status pattern matching"
fi
echo

echo "Test 3: Specific prefix wildcard (X-Spam-*)"
echo "--------------------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-Spam-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Spam-Score" && \
   header_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_exists "$OUTPUT" "X-MS-Exchange-Test"; then
    test_pass "X-Spam-* removes only X-Spam- headers"
else
    test_fail "X-Spam-* pattern matching"
fi
echo

echo "Test 4: Multiple wildcard patterns"
echo "-----------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-Spam-*,X-Microsoft-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_exists "$OUTPUT" "X-MS-Exchange-Test" && \
   header_exists "$OUTPUT" "From"; then
    test_pass "Multiple wildcard patterns work"
else
    test_fail "Multiple wildcard patterns"
fi
echo

echo "Test 5: Wildcard with PRESERVE"
echo "-------------------------------"
test_count
# Test: Use X-* as removal list, but preserve List-Unsubscribe
OUTPUT=$(MAILHEADERCLEAN="X-*,List-Unsubscribe" MAILHEADERCLEAN_PRESERVE="List-Unsubscribe" \
    "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_exists "$OUTPUT" "List-Unsubscribe" && \
   header_exists "$OUTPUT" "From"; then
    test_pass "Wildcard with PRESERVE works correctly"
else
    test_fail "Wildcard with PRESERVE"
fi
echo

echo "Test 6: Case-insensitive matching"
echo "----------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="x-spam-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Spam-Score"; then
    test_pass "Lowercase pattern matches uppercase headers"
else
    test_fail "Case-insensitive matching"
fi
echo

echo "Test 7: Wildcard in middle (X-*-Test)"
echo "--------------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-*-Test" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-MS-Exchange-Test" && \
   header_exists "$OUTPUT" "X-Spam-Status" && \
   header_exists "$OUTPUT" "X-Microsoft-Antispam"; then
    test_pass "Middle wildcard pattern works"
else
    test_fail "Middle wildcard pattern"
fi
echo

echo "Test 8: Mix exact and wildcard patterns"
echo "----------------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-Spam-Status,X-Microsoft-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_not_exists "$OUTPUT" "X-Spam-Status" && \
   header_not_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_exists "$OUTPUT" "X-Spam-Score" && \
   header_exists "$OUTPUT" "X-MS-Exchange-Test"; then
    test_pass "Mix of exact and wildcard patterns works"
else
    test_fail "Mix of exact and wildcard patterns"
fi
echo

echo "Test 9: Wildcard matches nothing"
echo "---------------------------------"
test_count
OUTPUT=$(MAILHEADERCLEAN="X-NonExistent-*" "${BUILD_BIN}/mailheaderclean" "$TEST_EMAIL")
if header_exists "$OUTPUT" "X-Spam-Status" && \
   header_exists "$OUTPUT" "X-Microsoft-Antispam" && \
   header_exists "$OUTPUT" "From"; then
    test_pass "Non-matching wildcard preserves all headers"
else
    test_fail "Non-matching wildcard"
fi
echo

echo "Test 10: Test with builtin (if available)"
echo "------------------------------------------"
if [[ -f "${BUILD_LIB}/mailheaderclean.so" ]]; then
    test_count
    OUTPUT=$(bash -c "enable -f '${BUILD_LIB}/mailheaderclean.so' mailheaderclean 2>/dev/null && \
        MAILHEADERCLEAN='X-Spam-*' mailheaderclean '$TEST_EMAIL'" 2>/dev/null || true)
    if [[ -n "$OUTPUT" ]] && \
       header_not_exists "$OUTPUT" "X-Spam-Status" && \
       header_exists "$OUTPUT" "X-Microsoft-Antispam"; then
        test_pass "Builtin wildcard matching works"
    else
        test_fail "Builtin wildcard matching" "" "Empty or incorrect output"
    fi
else
    echo -e "${YELLOW}Skipped: builtin not found${NC}"
fi
echo

# Summary
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    exit 1
else
    echo -e "Failed: $FAILED_TESTS"
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
fi
