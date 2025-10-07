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

# Find test email files
TEST_FILE=""
TEST_DIR=""
if [[ -d /home/vmail/okusi.dev/contact/cur ]]; then
  TEST_FILE=$(sudo find /home/vmail/okusi.dev/contact/cur -type f | head -1)
  # Create a test directory with a few files
  TEST_DIR="/tmp/mailgetaddresses_test"
  mkdir -p "$TEST_DIR"
  sudo cp /home/vmail/okusi.dev/contact/cur/171075* "$TEST_DIR/" 2>/dev/null || true
elif [[ -d tests/test-data ]]; then
  TEST_FILE=$(find tests/test-data -type f | head -1)
  TEST_DIR="tests/test-data"
elif [[ -f test.eml ]]; then
  TEST_FILE="test.eml"
  TEST_DIR=""
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
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailgetaddresses "$TEST_FILE"
else
  ./mailgetaddresses "$TEST_FILE"
fi
echo

# Test 2: Extract with names
echo -e "${BLUE}Test 2: Extract with names (-n option)${NC}"
echo "Command: mailgetaddresses -n \"$TEST_FILE\""
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailgetaddresses -n "$TEST_FILE"
else
  ./mailgetaddresses -n "$TEST_FILE"
fi
echo

# Test 3: Separated by header type
echo -e "${BLUE}Test 3: Separated by header type (-s option)${NC}"
echo "Command: mailgetaddresses -s \"$TEST_FILE\""
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailgetaddresses -s "$TEST_FILE"
else
  ./mailgetaddresses -s "$TEST_FILE"
fi
echo

# Test 4: Extract only specific headers
echo -e "${BLUE}Test 4: Extract only From header (-h from)${NC}"
echo "Command: mailgetaddresses -h from \"$TEST_FILE\""
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailgetaddresses -h from "$TEST_FILE"
else
  ./mailgetaddresses -h from "$TEST_FILE"
fi
echo

# Test 5: Combine options
echo -e "${BLUE}Test 5: Combine -n and -s options${NC}"
echo "Command: mailgetaddresses -n -s -h from,to \"$TEST_FILE\""
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailgetaddresses -n -s -h from,to "$TEST_FILE"
else
  ./mailgetaddresses -n -s -h from,to "$TEST_FILE"
fi
echo

# Show original headers for comparison
echo -e "${BLUE}Original headers (for comparison):${NC}"
if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
  sudo ./mailheader "$TEST_FILE" | grep -iE '^(From|To|Cc):'
else
  ./mailheader "$TEST_FILE" | grep -iE '^(From|To|Cc):'
fi
echo

# Additional tests for multiple files/directories
if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
  echo -e "${BLUE}Test 6: Process directory${NC}"
  echo "Command: mailgetaddresses \"$TEST_DIR\""
  if [[ "$TEST_DIR" =~ ^/home/vmail ]]; then
    sudo ./mailgetaddresses "$TEST_DIR" | head -10
  else
    ./mailgetaddresses "$TEST_DIR" | head -10
  fi
  echo

  echo -e "${BLUE}Test 7: Process directory with deduplication${NC}"
  echo "Command: mailgetaddresses \"$TEST_DIR\" | sort -u"
  if [[ "$TEST_DIR" =~ ^/home/vmail ]]; then
    sudo ./mailgetaddresses "$TEST_DIR" | sort -u | head -10
  else
    ./mailgetaddresses "$TEST_DIR" | sort -u | head -10
  fi
  echo

  echo -e "${BLUE}Test 8: Combine file and directory${NC}"
  echo "Command: mailgetaddresses \"$TEST_FILE\" \"$TEST_DIR\""
  if [[ "$TEST_FILE" =~ ^/home/vmail ]]; then
    sudo ./mailgetaddresses "$TEST_FILE" "$TEST_DIR" | wc -l
  else
    ./mailgetaddresses "$TEST_FILE" "$TEST_DIR" | wc -l
  fi
  echo "Total addresses extracted from file + directory"
  echo
fi

echo -e "${GREEN}All tests completed successfully!${NC}"

# Cleanup
if [[ "$TEST_DIR" == "/tmp/mailgetaddresses_test" ]]; then
  rm -rf "$TEST_DIR"
fi

#fin
