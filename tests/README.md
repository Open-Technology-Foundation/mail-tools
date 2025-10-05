# Tests Directory

This directory contains all test scripts and test data for the mailheader utilities.

## Test Data

- **test-data/** - Directory containing real email files used for testing
  - 632 email files in Maildir format
  - Various spam and legitimate emails with different header configurations

## Test Scripts

### Comprehensive Tests (All 632 Files)

- **test_all_mailheader.sh** - Comprehensive mailheader tests
  - Validates all 632 files produce valid header output
  - Compares standalone vs builtin versions (sampling)
  - Verifies headers end at blank line

- **test_all_mailmessage.sh** - Comprehensive mailmessage tests
  - Validates all 632 files produce valid message body output
  - Compares standalone vs builtin versions (sampling)
  - Verifies mailheader + mailmessage = complete email

- **test_all_mailheaderclean.sh** - Comprehensive mailheaderclean tests
  - Validates all 632 files produce valid email output
  - Compares standalone vs builtin versions (sampling)
  - Verifies bloat headers are removed
  - Verifies message body is preserved
  - Tests environment variables (MAILHEADERCLEAN, MAILHEADERCLEAN_PRESERVE, MAILHEADERCLEAN_EXTRA)

### Quick Functionality Tests

- **test_simple.sh** - Quick validation tests
  - Tests MAILHEADERCLEAN_PRESERVE functionality
  - Tests MAILHEADERCLEAN custom removal list
  - Simple pass/fail verification

- **test_builtin_vs_standalone.sh** - Comprehensive comparison test
  - Verifies standalone binary and bash builtin produce identical output
  - Tests all environment variable combinations
  - 5 test scenarios with different configurations

- **validate_email_format.sh** - RFC 822 format validation
  - Validates output is valid email format
  - Checks header/body separator
  - Verifies headers and continuation lines
  - Ensures body content preserved

- **test_mailheaderclean.sh** - Detailed functionality test
  - Tests header removal
  - Tests continuation line handling
  - Tests body preservation
  - Validates against all test-data files

### Environment Variable Tests

- **test_env_vars.sh** - Environment variable functionality
  - Tests MAILHEADERCLEAN
  - Tests MAILHEADERCLEAN_PRESERVE
  - Tests MAILHEADERCLEAN_EXTRA
  - Tests complex combinations

### Debug/Development Tests

- **test_export.sh** - Tests environment variable export behavior
  - Inline vs exported variables
  - Bash builtin vs standalone differences

- **test_reload.sh** - Tests builtin reload functionality
  - Ensures clean builtin loading
  - Verifies no caching issues

- **debug_test.sh** - Simple debug test
  - Quick verification of basic functionality

- **test_debug.sh** - Debug with output
  - Shows debug information during testing

## Running Tests

**IMPORTANT:** Tests must be run from the `tests/` directory:

```bash
# Navigate to tests directory
cd tests

# Run comprehensive tests (all 632 files)
./test_all_mailheader.sh
./test_all_mailmessage.sh
./test_all_mailheaderclean.sh

# Run quick functionality tests
./test_simple.sh
./test_builtin_vs_standalone.sh
./validate_email_format.sh

# Or run directly
cd tests && ./test_all_mailheader.sh
```

Tests use relative paths and expect:
- `../mailheader`, `../mailmessage`, `../mailheaderclean` (parent directory)
- `../mailheader.so`, `../mailmessage.so`, `../mailheaderclean.so` (parent directory)
- `test-data/` (current directory)

## Test Requirements

- Built binaries in parent directory: `../mailheader`, `../mailmessage`, `../mailheaderclean`
- Built builtins in parent directory: `../mailheader.so`, `../mailmessage.so`, `../mailheaderclean.so`
- bash-builtins package installed (for builtin tests)
- Test data in `tests/test-data/` (632 email files)

## Notes

- All test scripts use relative paths (`../mailheader`, `../mailmessage`, `../mailheaderclean`, `test-data/`)
- Builtin tests require loading the .so file with `enable -f`
- Some tests require exported environment variables (bash builtins don't see inline vars)
- Comprehensive tests use sampling (every 10th-20th file) for performance-intensive checks
- Tests clean up temporary files in `/tmp/`
