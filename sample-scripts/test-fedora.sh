#!/bin/bash
# sample-scripts/test-fedora.sh

echo "--- Verifying Fedora Environment ---"

echo ""
echo "1. Fedora Release Information:"
if [ -f /etc/fedora-release ]; then
    cat /etc/fedora-release
else
    echo "Could not find /etc/fedora-release"
fi

echo ""
echo "2. Kernel Version:"
uname -r

echo ""
echo "3. Current User:"
whoami

echo ""
echo "4. Home Directory Contents:"
ls -la ~

echo ""
echo "5. Checking for dnf (Fedora Package Manager):"
if command -v dnf &> /dev/null; then
    echo "dnf found!"
    dnf --version | head -n 1
else
    echo "dnf command not found."
fi

echo ""
echo "6. Attempting to use a common Fedora tool (e.g., htop, if installed by postCreateCommand):"
if command -v htop &> /dev/null; then
    echo "htop is available. (Not running it interactively in script)"
else
    echo "htop is not installed. You can add 'sudo dnf install -y htop' to postCreateCommand in devcontainer.json."
fi

echo ""
echo "--- Verification Complete ---"
