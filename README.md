# mailheader

Fast email header extraction utility available as both a standalone binary and bash loadable builtin.

## Features

- Extracts email headers (everything up to the first blank line)
- Handles RFC 822 continuation lines (joins lines starting with whitespace)
- Normalizes formatting (removes `\r`, converts tabs to spaces)
- **Dual implementation**:
  - Standalone binary for general use
  - Bash loadable builtin for high-performance scripting (10-20x faster)

## Installation

### Prerequisites

For the bash loadable builtin:
```bash
sudo apt-get install bash-builtins  # Ubuntu/Debian
```

### One-Liner Install

Quick installation without keeping the source:

```bash
git clone https://github.com/Open-Technology-Foundation/mailheader.git && cd mailheader && sudo ./install.sh && cd .. && rm -rf mailheader
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
- Check prerequisites and build the binaries
- Prompt whether to install the bash builtin (optional)
- Install all files to the correct locations
- Update the man database

**Options:**
```bash
sudo ./install.sh --help              # Show all options
sudo ./install.sh --builtin           # Force builtin installation
sudo ./install.sh --no-builtin        # Skip builtin installation
sudo ./install.sh --uninstall         # Remove installation
sudo ./install.sh --prefix=/opt       # Custom install location
sudo ./install.sh --dry-run           # Preview without installing
```

### Manual Build and Install

Alternatively, use make directly:

```bash
# Build both versions
make

# Install system-wide (requires sudo)
sudo make install
```

This installs:
- Standalone binary: `/usr/local/bin/mailheader`
- Loadable builtin: `/usr/local/lib/bash/loadables/mailheader.so`
- Auto-load script: `/etc/profile.d/mailheader.sh`
- Manpage: `/usr/local/share/man/man1/mailheader.1`

### Verify Installation

```bash
# Check standalone binary
which mailheader

# Check builtin (after opening new shell or sourcing profile)
enable -a | grep mailheader

# View manpage
man mailheader

# Get help for builtin
help mailheader
```

## Usage

### Interactive Shell

The builtin is automatically loaded in new bash sessions:
```bash
mailheader email.eml
```

### Scripts

Scripts must explicitly enable the builtin:
```bash
#!/bin/bash
enable -f mailheader.so mailheader 2>/dev/null || true

mailheader /path/to/email.eml
```

### Cron Jobs

Cron requires explicit setup:
```bash
# Method 1: Source profile
*/15 * * * * bash -c 'source /etc/profile.d/mailheader.sh; mailheader /path/to/email.eml'

# Method 2: Explicit enable
*/15 * * * * bash -c 'enable -f mailheader.so mailheader; mailheader /path/to/email.eml'
```

## Example

Given `test.eml`:
```
From: sender@example.com
To: recipient@example.com
Subject: Test email with
 continuation line
Date: Mon, 1 Jan 2025 12:00:00 +0000

This is the message body.
```

Output:
```bash
$ mailheader test.eml
From: sender@example.com
To: recipient@example.com
Subject: Test email with continuation line
Date: Mon, 1 Jan 2025 12:00:00 +0000
```

## Performance

The bash builtin eliminates fork/exec overhead:

- **Standalone binary**: ~1-2ms per call (fork + exec + startup)
- **Bash builtin**: ~0.1ms per call (in-process execution)

For scripts processing many emails, this provides **10-20x speedup**.

### Benchmarking

Create a test directory with email files, then:
```bash
./benchmark.sh ./test_emails            # Basic benchmark
./benchmark_detailed.sh ./test_emails   # Detailed scaling analysis
```

## Build Targets

```bash
make                    # Build both versions
make standalone         # Build binary only
make loadable           # Build builtin only
make clean              # Remove build artifacts
sudo make install       # Install both versions
sudo make uninstall     # Remove all installed files
```

## How the Builtin Works

The builtin is automatically available in interactive shells via `/etc/profile.d/mailheader.sh`:

1. Sets `BASH_LOADABLES_PATH=/usr/local/lib/bash/loadables`
2. Auto-loads builtin in interactive shells with `enable -f mailheader.so mailheader`
3. Non-interactive contexts (scripts, cron) must explicitly enable it

## License

GNU General Public License v3.0 or later. See source files for details.

## Contributing

Issues and pull requests welcome at [github.com/Open-Technology-Foundation/mailheader](https://github.com/Open-Technology-Foundation/mailheader)
