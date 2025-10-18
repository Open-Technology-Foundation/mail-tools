#!/bin/bash
# Diagnostic script to check mail-tools installation status

echo "=== Mail-Tools Installation Diagnostic ==="
echo

echo "1. Checking standalone binaries:"
for cmd in mailheader mailmessage mailheaderclean mailgetaddresses mailgetheaders mailheaderclean-batch clean-email-headers; do
    if [ -f "/usr/local/bin/$cmd" ]; then
        echo "  ✓ /usr/local/bin/$cmd exists"
    else
        echo "  ✗ /usr/local/bin/$cmd NOT FOUND"
    fi
done
echo

echo "2. Checking bash loadable builtins (.so files):"
for builtin in mailheader mailmessage mailheaderclean; do
    if [ -f "/usr/local/lib/bash/loadables/$builtin.so" ]; then
        echo "  ✓ /usr/local/lib/bash/loadables/$builtin.so exists"
    else
        echo "  ✗ /usr/local/lib/bash/loadables/$builtin.so NOT FOUND"
    fi
done
echo

echo "3. Checking profile script:"
if [ -f "/etc/profile.d/mail-tools.sh" ]; then
    echo "  ✓ /etc/profile.d/mail-tools.sh exists"
else
    echo "  ✗ /etc/profile.d/mail-tools.sh NOT FOUND"
fi
echo

echo "4. Checking man pages:"
for man in mailheader mailmessage mailheaderclean mailgetaddresses; do
    if [ -f "/usr/local/share/man/man1/$man.1" ]; then
        echo "  ✓ /usr/local/share/man/man1/$man.1 exists"
    else
        echo "  ✗ /usr/local/share/man/man1/$man.1 NOT FOUND"
    fi
done
echo

echo "5. Checking BASH_LOADABLES_PATH:"
source /etc/profile.d/mail-tools.sh 2>/dev/null || true
echo "  BASH_LOADABLES_PATH=$BASH_LOADABLES_PATH"
echo

echo "6. Testing builtin loading (non-interactive):"
for builtin in mailheader mailmessage mailheaderclean; do
    if enable -f "$builtin.so" "$builtin" 2>/dev/null; then
        echo "  ✓ $builtin loaded successfully"
        type "$builtin"
    else
        echo "  ✗ $builtin FAILED to load"
    fi
done
echo

echo "7. Checking bash-builtins package:"
if command -v dpkg &>/dev/null; then
    if dpkg -l bash-builtins 2>/dev/null | grep -q "^ii"; then
        echo "  ✓ bash-builtins package is installed"
    else
        echo "  ✗ bash-builtins package NOT installed (required for builtins)"
    fi
else
    echo "  ? dpkg not available (not a Debian/Ubuntu system?)"
fi
echo

echo "=== Summary ==="
echo "To install missing components:"
echo "  cd /ai/scripts/lib/mailheader"
echo "  sudo ./install.sh          # Interactive install"
echo "  sudo ./install.sh --builtin # Force builtin installation"
