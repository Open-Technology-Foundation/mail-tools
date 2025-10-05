# Mail Tools

Fast email parsing utilities for extracting headers and message bodies. Available as both standalone binaries and bash loadable builtins.

## Purpose and Use Cases

These utilities solve common email processing challenges in scripts and automation:

**Use Cases:**
- **Email archival**: Strip bloat headers before archiving to reduce storage (mailheaderclean)
- **Email parsing**: Extract sender, subject, dates from mailbox files (mailheader + parsing)
- **Mailbox processing**: Process thousands of emails efficiently with bash builtins (10-20x faster)
- **Email splitting**: Separate headers from body for independent processing
- **Privacy**: Remove tracking headers and metadata before forwarding emails
- **Thunderbird integration**: Clean emails while preserving client-specific headers

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
- Extracts email headers (everything up to the first blank line)
- Handles RFC 822 continuation lines (joins lines starting with whitespace)
- Normalizes formatting (removes `\r`, converts tabs to spaces)

### mailmessage
- Extracts email message body (everything after the first blank line)
- Skips the header section entirely
- Preserves message formatting

### mailheaderclean
- Filters non-essential email headers from complete email files
- Removes ~207 bloat headers (Microsoft Exchange, security vendors, tracking, etc.)
- Keeps only the first "Received" header
- Preserves essential routing headers and complete message body
- Supports flexible header filtering via environment variables:
  - `MAILHEADERCLEAN`: Replace entire removal list with custom headers
  - `MAILHEADERCLEAN_PRESERVE`: Exclude specific headers from removal (e.g., for Thunderbird features)
  - `MAILHEADERCLEAN_EXTRA`: Add additional headers to the built-in removal list

All utilities support:
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
git clone https://github.com/Open-Technology-Foundation/mailheader.git && cd mailheader && sudo ./install.sh --builtin && cd .. && rm -rf mailheader
```

This will clone, install, and clean up the source in one command.

### Getting the Source

For manual installation or to keep the source:

```bash
git clone https://github.com/Open-Technology-Foundation/mailheader.git
cd mailheader
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
- Check prerequisites and build both utilities
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
# Build both versions
make

# Install system-wide (requires sudo)
sudo make install
```

This installs:
- Standalone binaries: `/usr/local/bin/mailheader`, `/usr/local/bin/mailmessage`, `/usr/local/bin/mailheaderclean`
- Loadable builtins: `/usr/local/lib/bash/loadables/mailheader.so`, `/usr/local/lib/bash/loadables/mailmessage.so`, `/usr/local/lib/bash/loadables/mailheaderclean.so`
- Auto-load script: `/etc/profile.d/mail-tools.sh`
- Manpages: `/usr/local/share/man/man1/mailheader.1`, `/usr/local/share/man/man1/mailmessage.1`, `/usr/local/share/man/man1/mailheaderclean.1`

### Verify Installation

```bash
# Check standalone binaries
which mailheader
which mailmessage
which mailheaderclean

# Check builtins (after opening new shell or sourcing profile)
enable -a | grep mail

# View manpages
man mailheader
man mailmessage
man mailheaderclean

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
```

## Examples

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

Clean bloat headers:
```bash
$ mailheaderclean email.eml > cleaned.eml

# Use custom removal list entirely
$ MAILHEADERCLEAN="X-Spam-Status,Delivered-To" mailheaderclean email.eml

# Preserve specific headers (e.g., for Thunderbird)
$ MAILHEADERCLEAN_PRESERVE="List-Unsubscribe,X-Priority" mailheaderclean email.eml

# Add custom headers to built-in list
$ MAILHEADERCLEAN_EXTRA="X-Custom-Header,X-Internal" mailheaderclean email.eml

# Complex combination
$ MAILHEADERCLEAN="DKIM-Signature,List-Unsubscribe" \
  MAILHEADERCLEAN_PRESERVE="List-Unsubscribe" \
  MAILHEADERCLEAN_EXTRA="X-Custom" mailheaderclean email.eml
# Result: Removes DKIM-Signature and X-Custom, preserves List-Unsubscribe
```

Parse headers into associative array (using mailgetheaders.sh example):
```bash
#!/bin/bash
source /usr/local/share/doc/mailheader/mailgetheaders.sh

declare -A Headers
getheader Headers email.eml

echo "From: ${Headers[From]}"
echo "Subject: ${Headers[Subject]}"
echo "Date: ${Headers[Date]}"
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
./benchmark.sh ./test_emails

# Detailed scaling analysis with multiple file counts
./benchmark_detailed.sh ./test_emails
```

Both scripts compare builtin vs standalone performance. Results typically show 10-20x speedup for the bash builtins.

### Testing

The project includes a comprehensive test suite with 632 real email files:

```bash
cd tests

# Run comprehensive tests (all 632 files)
./test_all_mailheader.sh
./test_all_mailmessage.sh
./test_all_mailheaderclean.sh

# Run quick functionality tests
./test_simple.sh
./test_builtin_vs_standalone.sh
./validate_email_format.sh

# Test environment variables
./test_env_vars.sh
```

See `tests/README.md` for detailed test documentation.

## Build Targets

```bash
make                      # Build all utilities (both versions)
make all-mailheader       # Build mailheader only
make all-mailmessage      # Build mailmessage only
make all-mailheaderclean  # Build mailheaderclean only
make standalone           # Build all standalone binaries
make loadable             # Build all builtins
make clean                # Remove build artifacts
sudo make install         # Install all utilities
sudo make uninstall       # Remove all installed files
```

## How the Builtins Work

The builtins are automatically available in interactive shells via `/etc/profile.d/mail-tools.sh`:

1. Sets `BASH_LOADABLES_PATH=/usr/local/lib/bash/loadables`
2. Auto-loads builtins in interactive shells:
   - `enable -f mailheader.so mailheader`
   - `enable -f mailmessage.so mailmessage`
   - `enable -f mailheaderclean.so mailheaderclean`
3. Non-interactive contexts (scripts, cron) must explicitly enable them

## Advanced Examples

### Example: Parse Headers into Associative Array

Use the included `mailgetheaders.sh` helper function:

```bash
#!/bin/bash
# Copy or source the example function
source /usr/local/share/doc/mailheader/mailgetheaders.sh

declare -A Headers
getheader Headers /path/to/email.eml

# Access individual headers
echo "From: ${Headers[From]}"
echo "To: ${Headers[To]}"
echo "Subject: ${Headers[Subject]}"
echo "Date: ${Headers[Date]}"

# List all headers
for header in "${!Headers[@]}"; do
  echo "$header: ${Headers[$header]}"
done
```

### Example: Bulk Email Cleaning

Clean all emails in a Maildir while preserving Thunderbird features:

```bash
#!/bin/bash
enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true

export MAILHEADERCLEAN_PRESERVE="List-Unsubscribe,List-Post,X-Priority,Importance"

for email in ~/Maildir/cur/*; do
  mailheaderclean "$email" > "/tmp/cleaned/$(basename "$email")"
done
```

### Example: Email Archive with Storage Savings

```bash
#!/bin/bash
# Archive emails with bloat headers removed
enable -f mailheaderclean.so mailheaderclean 2>/dev/null || true

for email in /var/mail/archive/*.eml; do
  original_size=$(stat -f%z "$email")
  mailheaderclean "$email" > "/archive/clean/$(basename "$email")"
  cleaned_size=$(stat -f%z "/archive/clean/$(basename "$email")")
  saved=$((original_size - cleaned_size))
  echo "Saved $saved bytes on $(basename "$email")"
done
```

## License

GNU General Public License v3.0 or later. See source files for details.

## Contributing

Issues and pull requests welcome at [github.com/Open-Technology-Foundation/mailheader](https://github.com/Open-Technology-Foundation/mailheader)
