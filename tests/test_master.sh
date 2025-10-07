#!/bin/bash
# Master test runner - runs all tests in correct order

set -euo pipefail

echo "╔════════════════════════════════════════════════════════╗"
echo "║   MAILHEADER PROJECT COMPREHENSIVE TEST SUITE         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Array to track failed tests
declare -a FAILED_TESTS=()

# Function to run a test
run_test() {
    local test_script="$1"
    local test_name
    test_name="$(basename "$test_script" .sh)"

    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ((TESTS_RUN++))

    if "./$test_script"; then
        ((TESTS_PASSED++))
        echo "✅ $test_name PASSED"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
        echo "❌ $test_name FAILED"
    fi
}

# Phase 1: Structure and Build Tests
echo "═══════════════════════════════════════════════════════"
echo " PHASE 1: Structure and Build Validation"
echo "═══════════════════════════════════════════════════════"

run_test "test_structure.sh"
run_test "test_build_system.sh"

# Phase 2: Core Functionality Tests
echo
echo "═══════════════════════════════════════════════════════"
echo " PHASE 2: Core Functionality Tests"
echo "═══════════════════════════════════════════════════════"

run_test "test_simple.sh"
run_test "test_builtin_vs_standalone.sh"
run_test "test_env_vars.sh"

# Phase 3: Comprehensive Tests (slow but thorough)
echo
echo "═══════════════════════════════════════════════════════"
echo " PHASE 3: Comprehensive Tests (632 test emails)"
echo "═══════════════════════════════════════════════════════"

run_test "test_all_mailheader.sh"
run_test "test_all_mailmessage.sh"
run_test "test_all_mailheaderclean.sh"

# Phase 4: Script Tests
echo
echo "═══════════════════════════════════════════════════════"
echo " PHASE 4: Script Functionality Tests"
echo "═══════════════════════════════════════════════════════"

run_test "test_mailgetaddresses.sh"
run_test "test_mailgetheaders.sh"

# Phase 5: Format Validation
echo
echo "═══════════════════════════════════════════════════════"
echo " PHASE 5: Email Format Validation"
echo "═══════════════════════════════════════════════════════"

run_test "validate_email_format.sh"

# Phase 6: Installation Tests
echo
echo "═══════════════════════════════════════════════════════"
echo " PHASE 6: Installation System Tests"
echo "═══════════════════════════════════════════════════════"

run_test "test_installation.sh"

# Final Summary
echo
echo
echo "╔════════════════════════════════════════════════════════╗"
echo "║              COMPREHENSIVE TEST SUMMARY                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo

if ((TESTS_FAILED > 0)); then
    echo "Failed Tests:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  ❌ $test"
    done
    echo
    echo "═══════════════════════════════════════════════════════"
    echo "❌ TEST SUITE FAILED"
    echo "═══════════════════════════════════════════════════════"
    exit 1
else
    echo "═══════════════════════════════════════════════════════"
    echo "✅ ALL TESTS PASSED!"
    echo "═══════════════════════════════════════════════════════"
    exit 0
fi
