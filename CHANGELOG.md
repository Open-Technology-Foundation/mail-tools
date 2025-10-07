# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive test suite with 632 real-world email files
- GitHub Actions CI/CD workflow
- Contributing guidelines (CONTRIBUTING.md)
- Code of Conduct (CODE_OF_CONDUCT.md)
- Master test runner (test_master.sh)
- Repository structure validation tests
- Build system validation tests
- Installation script tests
- mailgetheaders script tests

### Changed
- Reorganized repository structure with clean separation of source and build artifacts
- Moved all source files to src/ directory
- Moved all bash scripts to scripts/ directory
- Moved all man pages to man/ directory
- Moved example files to examples/ directory
- Moved benchmarks to tools/ directory
- Build artifacts now generated in build/ directory (bin/, lib/, obj/)
- Enhanced installation script with better error handling and dry-run support
- Improved test suite organization and coverage

### Fixed
- Shellcheck warnings in test scripts
- Environment variable handling in scripts

## [1.0.0] - Initial Release

### Added
- mailheader utility (standalone binary and bash builtin)
  - Extracts email headers from mail files
  - Handles RFC 822 continuation lines
  - Available as both standalone binary and bash loadable builtin

- mailmessage utility (standalone binary and bash builtin)
  - Extracts email message body from mail files
  - Complementary to mailheader
  - Available as both standalone binary and bash loadable builtin

- mailheaderclean utility (standalone binary and bash builtin)
  - Filters ~207 bloat headers from email files
  - Environment variable support for customization:
    - MAILHEADERCLEAN: Replace built-in removal list
    - MAILHEADERCLEAN_PRESERVE: Exclude headers from removal
    - MAILHEADERCLEAN_EXTRA: Add headers to removal list
  - Available as both standalone binary and bash loadable builtin

- mailgetaddresses script
  - Extracts email addresses from From, To, Cc headers
  - RFC 2047 encoded-word decoding
  - Name cleaning (removes quotes, parenthetical notation)
  - Directory processing with exclusion support
  - Multiple output formats

- mailgetheaders script
  - Parses email headers into bash associative array
  - Outputs bash code for eval
  - Handles continuation lines

- mailheaderclean-batch script
  - Production script for batch email cleaning
  - Age filtering support
  - Preserves timestamps and permissions
  - Backwards-compatible clean-email-headers symlink

- Comprehensive installation system
  - Interactive install.sh script
  - Automatic dependency detection and installation
  - Dry-run support
  - Prefix customization
  - Uninstall support

- Documentation
  - Detailed README.md with usage examples
  - Man pages for all utilities
  - Developer guidance (CLAUDE.md)
  - GPL v3.0 license

- Testing
  - Test suite with real-world email samples
  - Functionality tests
  - Format validation tests
  - Environment variable tests
  - Builtin vs standalone comparison tests

- Performance
  - Bash builtins provide 10-20x speedup for batch processing
  - Benchmarking utilities included

[Unreleased]: https://github.com/Open-Technology-Foundation/mailheader/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Open-Technology-Foundation/mailheader/releases/tag/v1.0.0
