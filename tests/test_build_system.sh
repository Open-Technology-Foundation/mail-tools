#!/bin/bash
# Test build system after reorganization

set -euo pipefail

echo "=== Build System Validation ==="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$REPO_ROOT"

PASS=0
FAIL=0

echo "TEST 1: Clean build (make clean)"
echo "-------------------------------------------"
if make clean > /dev/null 2>&1; then
    echo "  ✓ make clean succeeded"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: make clean failed"
    ((FAIL++)) || true
fi

if [[ ! -d build ]]; then
    echo "  ✓ build/ directory removed"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: build/ directory still exists"
    ((FAIL++)) || true
fi
echo

echo "TEST 2: Build all (make all)"
echo "-------------------------------------------"
if make all > /dev/null 2>&1; then
    echo "  ✓ make all succeeded"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: make all failed"
    ((FAIL++)) || true
    echo "=== Summary ==="
    echo "Passed: $PASS"
    echo "Failed: $FAIL"
    exit 1
fi
echo

echo "TEST 3: Verify binaries in build/bin/"
echo "-------------------------------------------"
for bin in mailheader mailmessage mailheaderclean; do
    if [[ -f "build/bin/$bin" ]]; then
        echo "  ✓ build/bin/$bin exists"
        ((PASS++)) || true
        if [[ -x "build/bin/$bin" ]]; then
            echo "  ✓ build/bin/$bin is executable"
            ((PASS++)) || true
        else
            echo "  ✗ FAIL: build/bin/$bin is not executable"
            ((FAIL++)) || true
        fi
    else
        echo "  ✗ FAIL: build/bin/$bin missing"
        ((FAIL++)) || true
    fi
done
echo

echo "TEST 4: Verify shared libraries in build/lib/"
echo "-------------------------------------------"
for lib in mailheader.so mailmessage.so mailheaderclean.so; do
    if [[ -f "build/lib/$lib" ]]; then
        echo "  ✓ build/lib/$lib exists"
        ((PASS++)) || true
        if [[ -x "build/lib/$lib" ]]; then
            echo "  ✓ build/lib/$lib is executable"
            ((PASS++)) || true
        else
            echo "  ✗ FAIL: build/lib/$lib is not executable"
            ((FAIL++)) || true
        fi
    else
        echo "  ✗ FAIL: build/lib/$lib missing"
        ((FAIL++)) || true
    fi
done
echo

echo "TEST 5: Verify object files in build/obj/"
echo "-------------------------------------------"
for obj in mailheader_loadable.o mailmessage_loadable.o mailheaderclean_loadable.o; do
    if [[ -f "build/obj/$obj" ]]; then
        echo "  ✓ build/obj/$obj exists"
        ((PASS++)) || true
    else
        echo "  ✗ FAIL: build/obj/$obj missing"
        ((FAIL++)) || true
    fi
done
echo

echo "TEST 6: Verify binaries work"
echo "-------------------------------------------"
if build/bin/mailheader examples/test.eml > /dev/null 2>&1; then
    echo "  ✓ mailheader binary works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailheader binary failed"
    ((FAIL++)) || true
fi

if build/bin/mailmessage examples/test.eml > /dev/null 2>&1; then
    echo "  ✓ mailmessage binary works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailmessage binary failed"
    ((FAIL++)) || true
fi

if build/bin/mailheaderclean examples/test-bloat.eml > /dev/null 2>&1; then
    echo "  ✓ mailheaderclean binary works"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailheaderclean binary failed"
    ((FAIL++)) || true
fi
echo

echo "TEST 7: Verify builtins are loadable"
echo "-------------------------------------------"
if bash -c "enable -f build/lib/mailheader.so mailheader 2>/dev/null"; then
    echo "  ✓ mailheader.so is loadable"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailheader.so cannot be loaded"
    ((FAIL++)) || true
fi

if bash -c "enable -f build/lib/mailmessage.so mailmessage 2>/dev/null"; then
    echo "  ✓ mailmessage.so is loadable"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailmessage.so cannot be loaded"
    ((FAIL++)) || true
fi

if bash -c "enable -f build/lib/mailheaderclean.so mailheaderclean 2>/dev/null"; then
    echo "  ✓ mailheaderclean.so is loadable"
    ((PASS++)) || true
else
    echo "  ✗ FAIL: mailheaderclean.so cannot be loaded"
    ((FAIL++)) || true
fi
echo

echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo

if ((FAIL > 0)); then
    echo "❌ Build system validation FAILED"
    exit 1
else
    echo "✅ Build system validation PASSED"
    exit 0
fi
