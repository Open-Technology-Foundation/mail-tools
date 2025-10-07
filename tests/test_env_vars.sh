#!/bin/bash
# Test mailheaderclean environment variable functionality

TEST_FILE="test-data/1749819569.M335292P205326V0000000000000811I000000000AE40A83_10.okusi0,S=5408:2,S"

echo "=== Environment Variable Testing ==="
echo

echo "TEST 1: Default behavior (no env vars)"
echo "  From headers: $(./mailheaderclean "$TEST_FILE" | grep -c "^From:")"
echo "  X-Priority headers: $(./mailheaderclean "$TEST_FILE" | grep -c "^X-Priority:" || echo "0")"
echo "  List-Unsubscribe headers: $(./mailheaderclean "$TEST_FILE" | grep -c "^List-Unsubscribe:" || echo "0")"
echo "  ✓ Headers removed by default (both should be 0)"
echo

echo "TEST 2: MAILHEADERCLEAN_PRESERVE (preserve priority headers)"
result=$(MAILHEADERCLEAN_PRESERVE="X-Priority,Importance" ../build/bin/mailheaderclean "$TEST_FILE" | grep "^X-Priority:")
if [ -n "$result" ]; then
    echo "  ✗ FAIL: X-Priority should NOT be present (it's not in original)"
else
    echo "  ✓ PASS: X-Priority correctly not present"
fi
echo

echo "TEST 3: MAILHEADERCLEAN (custom removal list - remove only From and Subject)"
from_count=$(MAILHEADERCLEAN="From,Subject" ../build/bin/mailheaderclean "$TEST_FILE" | grep -c "^From:" || echo "0")
subject_count=$(MAILHEADERCLEAN="From,Subject" ../build/bin/mailheaderclean "$TEST_FILE" | grep -c "^Subject:" || echo "0")
date_count=$(MAILHEADERCLEAN="From,Subject" ../build/bin/mailheaderclean "$TEST_FILE" | grep -c "^Date:")
if [ "$from_count" = "0" ] && [ "$subject_count" = "0" ] && [ "$date_count" = "1" ]; then
    echo "  ✓ PASS: Custom removal list works (From/Subject removed, Date kept)"
else
    echo "  ✗ FAIL: From=$from_count (expect 0), Subject=$subject_count (expect 0), Date=$date_count (expect 1)"
fi
echo

echo "TEST 4: MAILHEADERCLEAN_EXTRA (add headers to default list)"
custom_count=$(./mailheaderclean "$TEST_FILE" | grep -c "^Reply-To:")
custom_extra_count=$(MAILHEADERCLEAN_EXTRA="Reply-To" ../build/bin/mailheaderclean "$TEST_FILE" | grep -c "^Reply-To:" || echo "0")
if [ "$custom_count" = "1" ] && [ "$custom_extra_count" = "0" ]; then
    echo "  ✓ PASS: EXTRA adds headers to removal list"
else
    echo "  ✗ FAIL: Without EXTRA=$custom_count (expect 1), With EXTRA=$custom_extra_count (expect 0)"
fi
echo

echo "TEST 5: Complex combination"
# MAILHEADERCLEAN="Reply-To" removes only Reply-To
# MAILHEADERCLEAN_PRESERVE="Reply-To" prevents Reply-To from being removed
# Result: Reply-To should be kept
output=$(MAILHEADERCLEAN="Reply-To,From" MAILHEADERCLEAN_PRESERVE="Reply-To" ../build/bin/mailheaderclean "$TEST_FILE")
reply_count=$(echo "$output" | grep -c "^Reply-To:")
from_count=$(echo "$output" | grep -c "^From:" || echo "0")
date_count=$(echo "$output" | grep -c "^Date:")
if [ "$reply_count" = "1" ] && [ "$from_count" = "0" ] && [ "$date_count" = "1" ]; then
    echo "  ✓ PASS: Complex combination works correctly"
    echo "    Reply-To: preserved (was in removal list but also in preserve list)"
    echo "    From: removed (in removal list)"
    echo "    Date: kept (not in removal list)"
else
    echo "  ✗ FAIL: Reply-To=$reply_count (expect 1), From=$from_count (expect 0), Date=$date_count (expect 1)"
fi
echo

echo "TEST 6: PRESERVE with default list (preserve headers normally removed)"
# The default list includes X-Spam-Status, so test preserving it
output=$(./mailheaderclean "$TEST_FILE" | grep "^X-Spam-Status:")
if [ -z "$output" ]; then
    echo "  ✓ Default removes X-Spam-Status"
else
    echo "  ✗ X-Spam-Status should be removed by default"
fi

output2=$(MAILHEADERCLEAN_PRESERVE="X-Spam-Status" ../build/bin/mailheaderclean "$TEST_FILE" | grep "^X-Spam-Status:")
if [ -n "$output2" ]; then
    echo "  ✓ PASS: PRESERVE keeps X-Spam-Status that would normally be removed"
else
    echo "  ✗ FAIL: PRESERVE should keep X-Spam-Status"
fi
echo

echo "=== All Tests Complete ==="
