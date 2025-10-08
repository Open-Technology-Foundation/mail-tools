#!/bin/bash

# test_mailgetaddresses.sh - Test mailgetaddresses functionality

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing mailgetaddresses script${NC}"
echo "=================================="
echo

# Find test email files - prefer local test-data when running from tests directory
TEST_FILE=""
TEST_DIR=""
if [[ -d test-data ]]; then
  TEST_FILE=$(find test-data -type f -not -path '*/.*' | head -1)
  TEST_DIR="test-data"
elif [[ -f ../examples/test.eml ]]; then
  TEST_FILE="../examples/test.eml"
  TEST_DIR="../examples"
else
  echo "Error: No test email files found"
  exit 1
fi

echo -e "${GREEN}Using test file: $TEST_FILE${NC}"
if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
  echo -e "${GREEN}Using test directory: $TEST_DIR${NC}"
fi
echo

# Test 1: Basic extraction
echo -e "${BLUE}Test 1: Extract email addresses only${NC}"
echo "Command: mailgetaddresses \"$TEST_FILE\""
../scripts/mailgetaddresses "$TEST_FILE"
echo

# Test 2: Extract with names
echo -e "${BLUE}Test 2: Extract with names (-n option)${NC}"
echo "Command: mailgetaddresses -n \"$TEST_FILE\""
../scripts/mailgetaddresses -n "$TEST_FILE"
echo

# Test 3: Separated by header type
echo -e "${BLUE}Test 3: Separated by header type (-s option)${NC}"
echo "Command: mailgetaddresses -s \"$TEST_FILE\""
../scripts/mailgetaddresses -s "$TEST_FILE"
echo

# Test 4: Extract only specific headers
echo -e "${BLUE}Test 4: Extract only From header (-h from)${NC}"
echo "Command: mailgetaddresses -h from \"$TEST_FILE\""
../scripts/mailgetaddresses -h from "$TEST_FILE"
echo

# Test 5: Combine options
echo -e "${BLUE}Test 5: Combine -n and -s options${NC}"
echo "Command: mailgetaddresses -n -s -h from,to \"$TEST_FILE\""
../scripts/mailgetaddresses -n -s -h from,to "$TEST_FILE"
echo

# Show original headers for comparison
echo -e "${BLUE}Original headers (for comparison):${NC}"
../build/bin/mailheader "$TEST_FILE" | grep -iE '^(From|To|Cc):'
echo

echo -e "${GREEN}All tests completed successfully!${NC}"
