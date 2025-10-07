#!/bin/bash
# Test repository structure after reorganization

set -euo pipefail

echo "=== Repository Structure Validation ==="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

PASS=0
FAIL=0

# Test function
test_exists() {
    local path="$1"
    local type="$2"  # "dir" or "file"

    if [[ "$type" == "dir" ]]; then
        if [[ -d "$path" ]]; then
            echo "  ✓ Directory exists: $path"
            ((PASS++)) || true
        else
            echo "  ✗ FAIL: Missing directory: $path"
            ((FAIL++)) || true
        fi
    else
        if [[ -f "$path" ]]; then
            echo "  ✓ File exists: $path"
            ((PASS++)) || true
        else
            echo "  ✗ FAIL: Missing file: $path"
            ((FAIL++)) || true
        fi
    fi
}

echo "TEST 1: Check required directories exist"
echo "-------------------------------------------"
test_exists "src" "dir"
test_exists "scripts" "dir"
test_exists "man" "dir"
test_exists "examples" "dir"
test_exists "tools" "dir"
test_exists "tests" "dir"
test_exists "build" "dir"
test_exists "build/bin" "dir"
test_exists "build/lib" "dir"
test_exists "build/obj" "dir"
echo

echo "TEST 2: Check source files in src/"
echo "-------------------------------------------"
test_exists "src/mailheader.c" "file"
test_exists "src/mailheader_loadable.c" "file"
test_exists "src/mailmessage.c" "file"
test_exists "src/mailmessage_loadable.c" "file"
test_exists "src/mailheaderclean.c" "file"
test_exists "src/mailheaderclean_loadable.c" "file"
test_exists "src/mailheaderclean_headers.h" "file"
echo

echo "TEST 3: Check scripts in scripts/"
echo "-------------------------------------------"
test_exists "scripts/mailgetaddresses" "file"
test_exists "scripts/mailgetheaders" "file"
test_exists "scripts/mail-tools.sh" "file"
echo

echo "TEST 4: Check man pages in man/"
echo "-------------------------------------------"
test_exists "man/mailheader.1" "file"
test_exists "man/mailmessage.1" "file"
test_exists "man/mailheaderclean.1" "file"
test_exists "man/mailgetaddresses.1" "file"
echo

echo "TEST 5: Check examples in examples/"
echo "-------------------------------------------"
test_exists "examples/test.eml" "file"
test_exists "examples/test-bloat.eml" "file"
echo

echo "TEST 6: Check tools in tools/"
echo "-------------------------------------------"
test_exists "tools/benchmark.sh" "file"
test_exists "tools/benchmark_detailed.sh" "file"
echo

echo "TEST 7: Check root-level files"
echo "-------------------------------------------"
test_exists "Makefile" "file"
test_exists "install.sh" "file"
test_exists "README.md" "file"
test_exists "CLAUDE.md" "file"
echo

echo "TEST 8: Check .gitignore excludes build/"
echo "-------------------------------------------"
if grep -q "^build/" .gitignore; then
    echo "  ✓ .gitignore contains build/"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: .gitignore doesn't contain build/"
    ((FAIL++)) || true
fi
echo

echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if ((FAIL > 0)); then
    echo "❌ Structure validation FAILED"
    exit 1
else
    echo "✅ Structure validation PASSED"
    exit 0
fi
