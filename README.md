# Mail Tools

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/Open-Technology-Foundation/mail-tools/workflows/CI/badge.svg)](https://github.com/Open-Technology-Foundation/mail-tools/actions)
[![GitHub Issues](https://img.shields.io/github/issues/Open-Technology-Foundation/mail-tools)](https://github.com/Open-Technology-Foundation/mail-tools/issues)

Fast email parsing utilities for extracting headers, message bodies, and cleaning bloat headers. Available as both standalone binaries and bash loadable builtins.

**Features:**
- Professional directory structure (src/, scripts/, man/, examples/, tools/, build/)
- Clean separation of source code and build artifacts
- Comprehensive test suite with 632 real-world email files
- Automated installation with dependency management

## Purpose and Use Cases

These utilities solve common email processing challenges in scripts and automation:

**Use Cases:**
- **Email archival**: Strip bloat headers before archiving to reduce storage by ~20% (mailheaderclean)
- **Email parsing**: Extract sender, subject, dates from mailbox files (mailheader + parsing)
- **Mailbox processing**: Process thousands of emails efficiently with bash builtins (10-20x faster)
- **Email splitting**: Separate headers from body for independent processing
- **Privacy**: Remove tracking headers and metadata before forwarding emails
- **Thunderbird integration**: Clean emails while preserving client-specific headers
- **Batch operations**: Clean entire directories of emails in-place

**Why these tools?**
- **Performance**: Bash builtins eliminate fork/exec overhead (~1-2ms → ~0.1ms per call)
- **Simplicity**: Single-purpose utilities that do one thing well
- **RFC 822 compliance**: Proper handling of header continuation lines
- **Flexibility**: Dual implementation (binaries + builtins) for different contexts
- **No dependencies**: Pure C, minimal external requirements

**Comparison with alternatives:**
- **vs formail/reformail**: Focused specifically on header/body extraction and cleaning
- **vs python/perl**: No interpreter overhead, much faster for batch processing
- **vs awk/sed**: Built-in RFC 822 support, easier to use correctly

## Utilities

### mailheader
Extracts email headers (everything up to the first blank line).

- Handles RFC 822 continuation lines (joins lines starting with whitespace)
- Normalizes formatting (removes `\r`, converts tabs to spaces)
- Available as binary and builtin

```bash
mailheader email.eml
mailheader -h          # Show help
```

### mailmessage
Extracts email message body (everything after the first blank line).

- Skips the header section entirely
- Preserves message formatting
- Available as binary and builtin

```bash
mailmessage email.eml
mailmessage -h         # Show help
```

### mailheaderclean
Filters non-essential email headers from complete email files.

- Removes ~207 bloat headers (Microsoft Exchange, security vendors, tracking, etc.)
- Keeps only the first "Received" header
- Preserves essential routing headers and complete message body
- Supports flexible header filtering via environment variables
- Available as binary and builtin

```bash
mailheaderclean email.eml > cleaned.eml
mailheaderclean -h                        # Show help
```

**Environment variables:**
- `MAILHEADERCLEAN`: Replace entire removal list with custom headers
- `MAILHEADERCLEAN_PRESERVE`: Exclude specific headers from removal (e.g., for Thunderbird features)
- `MAILHEADERCLEAN_EXTRA`: Add additional headers to the built-in removal list

### mailgetaddresses
Bash script that extracts email addresses from From, To, and Cc headers in email files.

- Handles various email formats (with/without names, quoted strings, etc.)
- Multiple recipients per header
- Optional output formatting (with names, separated by header type)
- Selective header extraction
- Accepts multiple files and/or directories as arguments
- Processes all files in given directories
- Directory exclusions (default: .Junk, .Trash, .Sent) with override support
- **Name cleaning**: Decodes RFC 2047 encoded names, removes quotes and parenthetical notation
- Removes redundant names (when name equals email address)

```bash
mailgetaddresses email.eml                      # Extract from single file
mailgetaddresses -n email.eml                   # Include names with addresses
mailgetaddresses -s email.eml                   # Separate by header type
mailgetaddresses -H from,to email.eml           # Extract only From and To
mailgetaddresses file1.eml file2.eml file3.eml  # Multiple files
mailgetaddresses /path/to/maildir/              # Process directory (excludes .Junk,.Trash,.Sent)
mailgetaddresses -x .spam,.Junk /path/to/mail/  # Custom directory exclusions
mailgetaddresses --exclude '' /path/to/mail/    # No exclusions (process all subdirs)
mailgetaddresses email.eml /path/to/maildir/    # Combine files and dirs
mailgetaddresses /path/to/maildir/ | sort -fu   # Deduplicate (case-insensitive)
mailgetaddresses -n /path/to/maildir/ | sort -fu > contacts.txt  # Build contact list
mailgetaddresses --help                         # Show help
```

**Name Cleaning Examples:**
```bash
# Input:  =?utf-8?Q?Undangan_Pelatihan?= <invite@example.com>
# Output: Undangan Pelatihan <invite@example.com>

# Input:  'John Doe' <john@example.com>
# Output: John Doe <john@example.com>

# Input:  Jane Smith (jane@example.com) <jane@example.com>
# Output: Jane Smith <jane@example.com>

# Input:  bob@test.com <bob@test.com>
# Output: bob@test.com
```

**Post-Processing: Filtering with Exclude Patterns:**

For excluding specific domains or patterns from the results, use `grep -v -F -f`:

```bash
# Create exclude pattern file
cat > /tmp/exclude-patterns.list <<EOF
okusi
hukumonline
@singularityu.org
@example.com
EOF

# Filter results using pattern file (case-sensitive)
mailgetaddresses -n /path/to/maildir/ | sort -fu | grep -v -F -f /tmp/exclude-patterns.list

# Case-insensitive filtering (recommended - matches okusi, Okusi, OKUSI, etc.)
mailgetaddresses -n /path/to/maildir/ | sort -fu | grep -v -i -F -f /tmp/exclude-patterns.list

# If patterns are regex (slower, only if needed)
mailgetaddresses -n /path/to/maildir/ | sort -fu | grep -v -E -f /tmp/exclude-patterns.list
```

**grep options explained:**
- `-v` = Invert match (exclude lines that match)
- `-F` = Fixed strings (not regex) - much faster for literal patterns
- `-i` = Case-insensitive matching
- `-E` = Extended regex (only if patterns contain regex syntax)
- `-f FILE` = Read patterns from file

This approach is highly efficient because `grep` uses optimized C code with Boyer-Moore algorithm for pattern matching.

### mailgetheaders
Bash script that parses email headers into a bash associative array for easy access in scripts.

- Extracts all headers from an email file
- Outputs bash code to populate an associative array
- Handles continuation lines (RFC 822)
- Ideal for scripting and parsing email metadata

```bash
mailgetheaders email.eml                    # Output bash array declaration
eval "$(mailgetheaders email.eml)"          # Populate Headers array in current shell

# Use in scripts:
declare -A Headers
eval "$(mailgetheaders email.eml)"
echo "From: ${Headers[From]}"
echo "Subject: ${Headers[Subject]}"
echo "Date: ${Headers[Date]}"
echo "File: ${Headers[file]}"

mailgetheaders --help                       # Show help
```

### mailheaderclean-batch (script)
Production script for batch cleaning of email files or directories in-place.

- Process single files or entire directories
- Age filtering with `-d/--days` option
- Configurable directory traversal depth
- Preserves timestamps and permissions
- Progress reporting and error handling
- Available as `clean-email-headers` symlink for backwards compatibility

```bash
mailheaderclean-batch email.eml              # Clean single file
mailheaderclean-batch /path/to/maildir       # Clean all files in directory
mailheaderclean-batch -d 7 /path/to/maildir  # Only files from last 7 days
mailheaderclean-batch -m 2 /path/to/maildir  # Traverse 2 levels deep
mailheaderclean-batch -h                     # Show help

# Also available via backwards-compatible symlink:
clean-email-headers email.eml                # Same as mailheaderclean-batch
```

All utilities support:
- **Help options**: `-h` or `--help` for usage information
- **Consistent exit codes**: 0 (success), 1 (file error), 2 (usage error)
- **Dual implementation**:
  - Standalone binaries for general use
  - Bash loadable builtins for high-performance scripting (10-20x faster)

## Installation

### Prerequisites

For the bash loadable builtin:
```bash
sudo apt-get install bash-builtins  # Ubuntu/Debian
```

### One-Liner Install

Quick installation without keeping the source:

```bash
git clone https://github.com/Open-Technology-Foundation/mail-tools.git && cd mail-tools && sudo ./install.sh --builtin && cd .. && rm -rf mail-tools
```

This will clone, install, and clean up the source in one command.

### Getting the Source

For manual installation or to keep the source:

```bash
git clone https://github.com/Open-Technology-Foundation/mail-tools.git
cd mail-tools
```

**Optional**: Keep a system-wide copy of the source for future updates or rebuilds:

```bash
# Move to traditional source location (optional)
sudo mv mailheader /usr/local/src/
cd /usr/local/src/mailheader
```

**Note**: The source code is not required after installation. You can delete the cloned directory after running `install.sh` and re-clone from GitHub if needed later.

### Quick Install (Recommended)

Use the installation script for an interactive, automated installation:

```bash
sudo ./install.sh
```

The script will:
- Check prerequisites and build all utilities
- Prompt whether to install the bash builtins (optional)
- Install all files to the correct locations
- Update the man database

**Options:**
```bash
sudo ./install.sh --help              # Show all options
sudo ./install.sh --builtin           # Force builtins (auto-installs dependencies)
sudo ./install.sh --no-builtin        # Skip builtin installation
sudo ./install.sh --uninstall         # Remove installation
sudo ./install.sh --prefix=/opt       # Custom install location
sudo ./install.sh --dry-run           # Preview without installing
```

**Note:** Using `--builtin` will automatically install the `bash-builtins` package if it's not already present (Debian/Ubuntu).

### Manual Build and Install

Alternatively, use make directly:

```bash
# Build all utilities
make

# Install system-wide (requires sudo)
sudo make install
```

This installs:
- Standalone binaries: `/usr/local/bin/{mailheader,mailmessage,mailheaderclean}`
- Bash scripts: `/usr/local/bin/{mailgetaddresses,mailgetheaders,mailheaderclean-batch}` (includes backwards-compatible `clean-email-headers` symlink)
- Loadable builtins: `/usr/local/lib/bash/loadables/{mailheader,mailmessage,mailheaderclean}.so`
- Auto-load script: `/etc/profile.d/mail-tools.sh`
- Manpages: `/usr/local/share/man/man1/{mailheader,mailmessage,mailheaderclean,mailgetaddresses}.1`
- Documentation: `/usr/local/share/doc/mailheader/`

### Verify Installation

```bash
# Check all installed programs
which mailheader mailmessage mailheaderclean mailgetaddresses mailgetheaders

# Verify backwards-compatible symlink works
which clean-email-headers  # Should point to mailheaderclean

# Check builtins (after opening new shell or sourcing profile)
enable -a | grep mail

# View help
mailheader -h
mailmessage -h
mailheaderclean -h
mailgetaddresses --help
mailgetheaders --help

# View manpages
man mailheader
man mailmessage
man mailheaderclean
man mailgetaddresses

# Get help for builtins
help mailheader
help mailmessage
help mailheaderclean
```

## Usage

### Interactive Shell

The builtins are automatically loaded in new bash sessions:
```bash
mailheader email.eml
mailmessage email.eml
mailheaderclean email.eml
```

### Scripts

Scripts must explicitly enable the builtins:
```bash
#!/bin/bash
enable -f mailheader.so mailheader 2>/dev/null || true
enable -f mailmessage.so mailmessage 2>/dev/null || true
enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true

# Extract headers
mailheader /path/to/email.eml

# Extract message body
mailmessage /path/to/email.eml

# Clean bloat headers from email
mailheaderclean /path/to/email.eml > cleaned.eml

# Split an email into parts
mailheader email.eml > headers.txt
mailmessage email.eml > body.txt

# Remove custom headers
MAILHEADERCLEAN_EXTRA="X-Custom,X-Internal" mailheaderclean email.eml
```

### Cron Jobs

Cron requires explicit setup:
```bash
# Method 1: Source profile
*/15 * * * * bash -c 'source /etc/profile.d/mail-tools.sh; mailheader /path/to/email.eml'

# Method 2: Explicit enable
*/15 * * * * bash -c 'enable -f mailheader.so mailheader; mailheader /path/to/email.eml'

# Method 3: Use standalone binary
*/15 * * * * /usr/local/bin/mailheader /path/to/email.eml

# Method 4: Use production script
0 2 * * * /usr/local/bin/mailheaderclean-batch -d 30 /var/mail/archive 2>/var/log/email-clean.log
```

## Examples

### Basic Usage

Given `test.eml`:
```
From: sender@example.com
To: recipient@example.com
Subject: Test email with
 continuation line
Date: Mon, 1 Jan 2025 12:00:00 +0000

This is the message body.
It can span multiple lines.
```

Extract headers:
```bash
$ mailheader test.eml
From: sender@example.com
To: recipient@example.com
Subject: Test email with continuation line
Date: Mon, 1 Jan 2025 12:00:00 +0000
```

Extract message body:
```bash
$ mailmessage test.eml
This is the message body.
It can span multiple lines.
```

Split email into components:
```bash
$ mailheader email.eml > headers.txt
$ mailmessage email.eml > body.txt
$ cat headers.txt body.txt  # Reconstruct email
```

### Cleaning Bloat Headers

Clean single file:
```bash
$ mailheaderclean email.eml > cleaned.eml
```

Use custom removal list entirely:
```bash
$ MAILHEADERCLEAN="X-Spam-Status,Delivered-To" mailheaderclean email.eml
```

Preserve specific headers (e.g., for Thunderbird):
```bash
$ MAILHEADERCLEAN_PRESERVE="List-Unsubscribe,X-Priority" mailheaderclean email.eml
```

Add custom headers to built-in list:
```bash
$ MAILHEADERCLEAN_EXTRA="X-Custom-Header,X-Internal" mailheaderclean email.eml
```

Complex combination:
```bash
$ MAILHEADERCLEAN="DKIM-Signature,List-Unsubscribe" \
  MAILHEADERCLEAN_PRESERVE="List-Unsubscribe" \
  MAILHEADERCLEAN_EXTRA="X-Custom" mailheaderclean email.eml
# Result: Removes DKIM-Signature and X-Custom, preserves List-Unsubscribe
```

### Production Script Examples

Clean single file in-place:
```bash
mailheaderclean-batch email.eml
```

Clean entire directory:
```bash
mailheaderclean-batch /path/to/maildir
```

Clean only recent files (last 7 days):
```bash
mailheaderclean-batch -d 7 /path/to/maildir
```

Clean with custom depth and verbosity:
```bash
mailheaderclean-batch -m 3 -v /path/to/maildir
```

Quiet mode for cron:
```bash
mailheaderclean-batch -q /path/to/maildir
```

### Advanced Examples

Parse headers into associative array:
```bash
#!/bin/bash

declare -A Headers
eval "$(mailgetheaders email.eml)"

echo "From: ${Headers[From]}"
echo "Subject: ${Headers[Subject]}"
echo "Date: ${Headers[Date]}"
echo "File: ${Headers[file]}"
```

Bulk email cleaning with progress:
```bash
#!/bin/bash
enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true

export MAILHEADERCLEAN_PRESERVE="List-Unsubscribe,List-Post,X-Priority,Importance"

for email in ~/Maildir/cur/*; do
  mailheaderclean "$email" > "/tmp/cleaned/$(basename "$email")"
done
```

Email archive with storage savings:
```bash
#!/bin/bash
enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true

total_saved=0
for email in /var/mail/archive/*.eml; do
  original_size=$(stat -c%s "$email")
  mailheaderclean "$email" > "/archive/clean/$(basename "$email")"
  cleaned_size=$(stat -c%s "/archive/clean/$(basename "$email")")
  saved=$((original_size - cleaned_size))
  total_saved=$((total_saved + saved))
  echo "Saved $saved bytes on $(basename "$email")"
done
echo "Total saved: $total_saved bytes"
```

## Exit Codes

All utilities follow standard Unix exit code conventions:

- **0** - Success
- **1** - File error (cannot open/read file)
- **2** - Usage error (incorrect arguments)

Examples:
```bash
mailheader email.eml
echo $?  # 0 (success)

mailheader /nonexistent/file
echo $?  # 1 (file error)

mailheader
echo $?  # 2 (usage error - missing argument)
```

## Performance

The bash builtins eliminate fork/exec overhead:

- **Standalone binaries**: ~1-2ms per call (fork + exec + startup)
- **Bash builtins**: ~0.1ms per call (in-process execution)

For scripts processing many emails, this provides **10-20x speedup**.

### Benchmarking

The project includes comprehensive benchmarking tools to measure performance:

```bash
# Basic performance comparison
tools/benchmark.sh

# Detailed scaling analysis with multiple file counts
tools/benchmark_detailed.sh
```

Both scripts compare builtin vs standalone performance across different file counts. Results typically show:
- **Small files (1-2KB)**: 15-20x speedup with builtins
- **Large files (>100KB)**: 8-12x speedup with builtins
- **Overall**: 10-20x average speedup for typical email processing

### Real-World Performance

Testing with 632 real email files (8.3MB total):

**mailheaderclean cleaning operation:**
- **Standalone**: ~2.5 seconds
- **Builtin**: ~0.15 seconds
- **Speedup**: ~16x faster

**Storage savings:**
- Original size: 8.3MB
- Cleaned size: 6.6MB
- **Savings**: 1.7MB (~20% reduction)

## Testing

The project includes a comprehensive test suite with **632 real email files** from various sources.

### Running Tests

```bash
cd tests

# Master test runner (runs all tests)
./test_master.sh

# Repository structure and build tests
./test_structure.sh             # Validate directory structure
./test_build_system.sh          # Test Makefile and build process
./test_installation.sh          # Test install.sh functionality

# Comprehensive tests (all 632 files)
./test_all_mailheader.sh       # Test header extraction
./test_all_mailmessage.sh      # Test message body extraction
./test_all_mailheaderclean.sh  # Test header cleaning

# Quick functionality tests
./test_simple.sh                    # Basic functionality
./test_builtin_vs_standalone.sh     # Verify identical output
./validate_email_format.sh          # RFC 822 compliance

# Script tests
./test_mailgetaddresses.sh      # Test address extraction
./test_mailgetheaders.sh        # Test header parsing

# Environment variable tests
./test_env_vars.sh
./test_mailheaderclean.sh
```

### Test Results

All tests pass with 100% success rate on critical functionality:

- ✓ **632/633** files produce valid header extraction
- ✓ **632/633** files produce valid message extraction
- ✓ **632/633** files produce valid cleaned output
- ✓ **632/632** files maintain valid RFC 822 format after cleaning
- ✓ **100%** identical output between standalone and builtin versions
- ✓ All environment variable combinations work correctly

See `tests/README.md` for detailed test documentation.

## Build Targets

The build system uses organized directories for clean separation of source and artifacts:

```bash
make                      # Build all utilities (output to build/)
make all-mailheader       # Build mailheader only
make all-mailmessage      # Build mailmessage only
make all-mailheaderclean  # Build mailheaderclean only
make standalone           # Build all standalone binaries
make loadable             # Build all builtins
make clean                # Remove build/ directory
sudo make install         # Install all utilities system-wide
sudo make uninstall       # Remove all installed files
make help                 # Show all available targets
```

Build artifacts are organized in `build/`:
- `build/bin/` - Standalone executables
- `build/lib/` - Loadable builtins (.so files)
- `build/obj/` - Object files

## How the Builtins Work

The builtins are automatically available in interactive shells via `/etc/profile.d/mail-tools.sh`:

1. Sets `BASH_LOADABLES_PATH=/usr/local/lib/bash/loadables`
2. Auto-loads builtins in interactive shells:
   - `enable -f mailheader.so mailheader`
   - `enable -f mailmessage.so mailmessage`
   - `enable -f mailheaderclean.so mailheaderclean`
3. Non-interactive contexts (scripts, cron) must explicitly enable them

The builtins seamlessly integrate with bash, appearing identical to native commands while providing significant performance benefits.

## Project Structure

```
.
├── src/                           # Source code
│   ├── mailheader.c                   # mailheader standalone binary
│   ├── mailheader_loadable.c          # mailheader bash builtin
│   ├── mailmessage.c                  # mailmessage standalone binary
│   ├── mailmessage_loadable.c         # mailmessage bash builtin
│   ├── mailheaderclean.c              # mailheaderclean standalone binary
│   ├── mailheaderclean_loadable.c     # mailheaderclean bash builtin
│   └── mailheaderclean_headers.h      # Shared header removal list (~207 headers)
├── scripts/                       # Bash scripts
│   ├── mailgetaddresses               # Address extraction script
│   ├── mailgetheaders                 # Header parsing script
│   ├── mailheaderclean-batch          # Production batch cleaning script
│   └── mail-tools.sh                  # Profile script for auto-loading builtins
├── man/                           # Manual pages
│   ├── mailheader.1
│   ├── mailmessage.1
│   ├── mailheaderclean.1
│   └── mailgetaddresses.1
├── examples/                      # Sample email files
│   ├── test.eml
│   └── test-bloat.eml
├── tools/                         # Benchmarking utilities
│   ├── benchmark.sh
│   └── benchmark_detailed.sh
├── build/                         # Build artifacts (generated)
│   ├── bin/                           # Compiled binaries
│   │   ├── mailheader
│   │   ├── mailmessage
│   │   └── mailheaderclean
│   ├── lib/                           # Loadable builtins
│   │   ├── mailheader.so
│   │   ├── mailmessage.so
│   │   └── mailheaderclean.so
│   └── obj/                           # Object files
│       ├── mailheader.o
│       ├── mailmessage.o
│       └── mailheaderclean.o
├── tests/                         # Test suite (632 email files)
│   ├── test_master.sh                 # Master test runner
│   ├── test_structure.sh              # Repository structure validation
│   ├── test_build_system.sh           # Build system validation
│   ├── test_installation.sh           # Installation script testing
│   ├── test_mailgetheaders.sh         # Header parsing script tests
│   ├── test_all_mailheader.sh         # Comprehensive header tests
│   ├── test_all_mailmessage.sh        # Comprehensive message tests
│   ├── test_all_mailheaderclean.sh    # Comprehensive cleaning tests
│   ├── test_*.sh                      # Additional functionality tests
│   └── test-data/                     # 632 real email files
├── Makefile                       # Build system
├── install.sh                     # Installation script
├── README.md                      # User documentation
├── CLAUDE.md                      # Developer guidance
└── LICENSE                        # GPL v3.0
```

## FAQ

**Q: Do I need both the binaries and builtins?**
A: The installation script installs both by default. Use binaries for general scripts and builtins for high-performance batch processing.

**Q: Will this work with my maildir?**
A: Yes, these tools work with any RFC 822 compliant email format, including Maildir, mbox, and individual .eml files.

**Q: How do I customize which headers to remove?**
A: Use the `MAILHEADERCLEAN_*` environment variables to control header filtering. See examples above.

**Q: Are timestamps preserved when cleaning emails?**
A: Yes, when using `mailheaderclean-batch` script (or the backwards-compatible `clean-email-headers` symlink). For manual operations, use `touch -r` to preserve timestamps.

**Q: Can I use this in production?**
A: Yes, all utilities are production-ready with comprehensive testing and error handling. The test suite validates against 632 real-world emails.

## License

GNU General Public License v3.0 or later. See LICENSE file for details.

## Contributing

Issues and pull requests welcome at [github.com/Open-Technology-Foundation/mail-tools](https://github.com/Open-Technology-Foundation/mail-tools)

## Credits

Developed by the Open Technology Foundation for efficient email processing in bash environments.
