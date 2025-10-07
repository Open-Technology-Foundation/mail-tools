#!/bin/bash
# Test install.sh script

set -euo pipefail

echo "=== Installation Script Validation ==="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

PASS=0
FAIL=0
TEST_PREFIX="/tmp/mailheader-test-install"

# Cleanup function
cleanup() {
    if [[ -d "$TEST_PREFIX" ]]; then
        rm -rf "$TEST_PREFIX"
    fi
}

# Register cleanup on exit
trap cleanup EXIT

echo "TEST 1: --help shows updated text"
echo "-------------------------------------------"
if ./install.sh --help | grep -q "mailgetheaders"; then
    echo "  ✓ Help text mentions mailgetheaders"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Help text doesn't mention mailgetheaders"
    ((FAIL++)) || true
fi

if ./install.sh --help | grep -q "Scripts:"; then
    echo "  ✓ Help text has Scripts section"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Help text missing Scripts section"
    ((FAIL++)) || true
fi

if ./install.sh --help | grep -q "regardless of --prefix"; then
    echo "  ✓ Help text documents PROFILE_DIR behavior"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Help text doesn't document PROFILE_DIR behavior"
    ((FAIL++)) || true
fi
echo

echo "TEST 2: --dry-run shows all files"
echo "-------------------------------------------"
DRY_RUN_OUTPUT=$(sudo ./install.sh --dry-run --no-builtin 2>&1)

if echo "$DRY_RUN_OUTPUT" | grep -q "mailgetaddresses"; then
    echo "  ✓ Dry-run shows mailgetaddresses"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Dry-run doesn't show mailgetaddresses"
    ((FAIL++)) || true
fi

if echo "$DRY_RUN_OUTPUT" | grep -q "mailgetheaders"; then
    echo "  ✓ Dry-run shows mailgetheaders"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Dry-run doesn't show mailgetheaders"
    ((FAIL++)) || true
fi
echo

echo "TEST 3: Installation to custom prefix"
echo "-------------------------------------------"
if sudo ./install.sh --prefix="$TEST_PREFIX" --no-builtin --non-interactive > /dev/null 2>&1; then
    echo "  ✓ Installation succeeded"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Installation failed"
    ((FAIL++)) || true
fi
echo

echo "TEST 4: Verify files installed to correct locations"
echo "-------------------------------------------"
# Check binaries
for bin in mailheader mailmessage mailheaderclean; do
    if [[ -f "$TEST_PREFIX/bin/$bin" ]]; then
        echo "  ✓ $TEST_PREFIX/bin/$bin installed"
        ((PASS++)) || true
    else
        echo "  ✗ FAIL: $TEST_PREFIX/bin/$bin missing"
        ((FAIL++)) || true
    fi
done

# Check scripts
for script in mailgetaddresses mailgetheaders; do
    if [[ -f "$TEST_PREFIX/bin/$script" ]]; then
        echo "  ✓ $TEST_PREFIX/bin/$script installed"
        ((PASS++)) || true
    else
        echo "  ✗ FAIL: $TEST_PREFIX/bin/$script missing"
        ((FAIL++)) || true
    fi
done

# Check man pages
for man in mailheader.1 mailmessage.1 mailheaderclean.1 mailgetaddresses.1; do
    if [[ -f "$TEST_PREFIX/share/man/man1/$man" ]]; then
        echo "  ✓ $TEST_PREFIX/share/man/man1/$man installed"
        ((PASS++)) || true
    else
        echo "  ✗ FAIL: $TEST_PREFIX/share/man/man1/$man missing"
        ((FAIL++)) || true
    fi
done

# Check documentation
if [[ -d "$TEST_PREFIX/share/doc/mailheader" ]]; then
    echo "  ✓ $TEST_PREFIX/share/doc/mailheader/ installed"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: $TEST_PREFIX/share/doc/mailheader/ missing"
    ((FAIL++)) || true
fi
echo

echo "TEST 5: Verify installed binaries work"
echo "-------------------------------------------"
if "$TEST_PREFIX/bin/mailheader" examples/test.eml > /dev/null 2>&1; then
    echo "  ✓ Installed mailheader works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Installed mailheader doesn't work"
    ((FAIL++)) || true
fi

if "$TEST_PREFIX/bin/mailgetaddresses" examples/test.eml > /dev/null 2>&1; then
    echo "  ✓ Installed mailgetaddresses works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Installed mailgetaddresses doesn't work"
    ((FAIL++)) || true
fi

if "$TEST_PREFIX/bin/mailgetheaders" examples/test.eml > /dev/null 2>&1; then
    echo "  ✓ Installed mailgetheaders works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Installed mailgetheaders doesn't work"
    ((FAIL++)) || true
fi
echo

echo "TEST 6: Uninstall removes all files"
echo "-------------------------------------------"
if sudo ./install.sh --prefix="$TEST_PREFIX" --uninstall > /dev/null 2>&1; then
    echo "  ✓ Uninstall succeeded"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: Uninstall failed"
    ((FAIL++)) || true
fi

# Check if binaries are removed
BINARIES_REMAIN=0
for bin in mailheader mailmessage mailheaderclean mailgetaddresses mailgetheaders; do
    if [[ -f "$TEST_PREFIX/bin/$bin" ]]; then
        echo "  ✗ FAIL: $TEST_PREFIX/bin/$bin still exists"
        ((FAIL++)) || true
        BINARIES_REMAIN=1
    fi
done

if ((BINARIES_REMAIN == 0)); then
    echo "  ✓ All binaries removed"
    ((PASS++)) || true
fi
echo

echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if ((FAIL > 0)); then
    echo "❌ Installation validation FAILED"
    exit 1
else
    echo "✅ Installation validation PASSED"
    exit 0
fi
