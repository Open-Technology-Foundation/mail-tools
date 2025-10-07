# Contributing to Mail Tools

Thank you for your interest in contributing to the Mail Tools project! We welcome contributions from the community.

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker to report bugs
- Describe the issue in detail, including steps to reproduce
- Include your system information (OS, bash version, etc.)
- For bugs, include relevant error messages and output

### Submitting Changes

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/mailheader.git
   cd mailheader
   ```

3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make your changes**:
   - Follow the existing code style
   - Maintain consistency with the project structure
   - Update documentation as needed
   - Add tests for new functionality

5. **Test your changes**:
   ```bash
   make clean
   make
   cd tests
   ./test_master.sh
   ```

6. **Run shellcheck** on any modified scripts:
   ```bash
   shellcheck install.sh scripts/*.sh tests/*.sh
   ```

7. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Brief description of your changes"
   ```

8. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

9. **Create a Pull Request** on GitHub

## Development Guidelines

### Code Style

#### C Code
- Use consistent indentation (spaces, not tabs)
- Follow existing naming conventions
- Add comments for complex logic
- Keep functions focused and concise
- Use `static` for internal functions
- Handle errors appropriately

#### Bash Scripts
- Follow the patterns in existing scripts
- Use `set -euo pipefail` for safety
- Quote variables properly
- Use shellcheck and fix all warnings
- Follow bash coding standards (see BASH-CODING-STANDARD.md if available)

### Testing

- All changes must pass the existing test suite
- Add new tests for new functionality
- Test both standalone binaries and bash builtins
- Verify your changes work on Ubuntu/Debian systems

### Documentation

- Update README.md if adding new features
- Update man pages for user-facing changes
- Update CLAUDE.md for development-related changes
- Include code comments for non-obvious logic

### Commit Messages

- Use clear, descriptive commit messages
- First line: brief summary (50 chars or less)
- Separate subject from body with blank line
- Use present tense ("Add feature" not "Added feature")
- Reference issue numbers when applicable

Example:
```
Add mailgetaddresses directory processing

- Add support for processing entire directories
- Implement directory exclusion patterns
- Update documentation and man page

Fixes #123
```

## Project Structure

```
src/                    # C source code (standalone + loadable versions)
scripts/                # Bash scripts
man/                    # Man pages
examples/               # Example email files
tools/                  # Benchmarking utilities
tests/                  # Test suite with 632 test emails
build/                  # Build artifacts (not in git)
```

## Building and Installing

### Build
```bash
make                    # Build all utilities
make clean              # Clean build artifacts
```

### Install
```bash
sudo ./install.sh       # Interactive installation
sudo make install       # Direct installation via make
```

### Run Tests
```bash
cd tests
./test_master.sh        # Run complete test suite
```

## Release Process

(For maintainers)

1. Update version numbers in source files
2. Update CHANGELOG.md
3. Run full test suite
4. Create git tag
5. Push to GitHub
6. Create GitHub release

## Questions?

- Open an issue for questions about contributing
- Check existing issues and pull requests
- Review the code and documentation for context

## License

By contributing to this project, you agree that your contributions will be licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later).

## Code of Conduct

This project follows a simple code of conduct: be respectful, collaborative, and constructive. We're all here to create useful tools for the community.
