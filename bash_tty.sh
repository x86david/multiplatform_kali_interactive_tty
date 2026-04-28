#!/bin/bash
# Forzamos que se use bash para evitar errores de sintaxis
PORT=${1:-2222}
PASS=$2

if [ -z "$PASS" ]; then 
    printf "Uso: %s <puerto> <pass>\n" "$0"
    exit 1
fi

# --- MOSTRAR INTERFACES DE RED ---
printf "\033[1;34m[*] Interfaces disponibles:\033[0m\n"
IP_RAW=$(ip -4 -o addr show 2>&1)
if echo "$IP_RAW" | grep -q "Permission denied" || [ -z "$IP_RAW" ]; then
    if command -v ifconfig >/dev/null 2>&1; then
        ifconfig 2>/dev/null | awk '/inet / {print $1 " " $2}' | grep -v "127.0.0.1" | head -n 5 | while read -r iface ip_addr; do
            iface=$(echo "$iface" | sed 's/://')
            ip_addr=$(echo "$ip_addr" | sed 's/addr://')
            printf "    \033[1;33m→\033[0m %s - %s\n" "$iface" "$ip_addr"
        done
    fi
else
    echo "$IP_RAW" | awk '{print $2 " - " $4}' | cut -d/ -f1 | grep -v "lo" | head -n 5 | while read -r line; do
        printf "    \033[1;33m→\033[0m %s\n" "$line"
    done
fi
printf "\n"

# --- VERIFICACIÓN DE DEPENDENCIAS ---
for tool in socat openssl; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf "\033[1;31m[!]\033[0m %s no encontrado. Instalando...\n" "$tool"
        if command -v pkg >/dev/null 2>&1; then pkg install -y "$tool"; else sudo apt-get update && sudo apt-get install -y "$tool"; fi
    fi
done

# --- CERTIFICADOS ---
RAM_DIR="/dev/shm"; [ ! -d "$RAM_DIR" ] && RAM_DIR="/tmp"; [ ! -w "$RAM_DIR" ] && RAM_DIR="."
CERT="$RAM_DIR/cert.pem"; KEY="$RAM_DIR/key.pem"; COMBINED="$RAM_DIR/server.pem"
openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 1 -nodes -subj "/C=US/O=Dev/CN=localhost" >/dev/null 2>&1
cat "$KEY" "$CERT" > "$COMBINED"
trap "rm -f $KEY $CERT $COMBINED; printf '\n\033[1;31m[-]\033[0m RAM limpia. Saliendo...\n'; exit" INT

# --- BUCLE DE ESCUCHA ---
while true; do
    printf "\033[1;32m[+]\033[0m Esperando TLS en puerto \033[1;33m%s\033[0m...\n" "$PORT"
    
    # Fase de Handshake
    IDENT=$(socat -T 2 OPENSSL-LISTEN:"$PORT",cert="$COMBINED",verify=0,reuseaddr - 2>/dev/null | head -n 1 | tr -d '\r\n')
    
    case "$IDENT" in
        *SHELL*)
            printf "[*] Handshake: \033[1;36m%s\033[0m. Autenticando...\n" "$IDENT"
            (sleep 1; echo "$PASS"; cat) | socat OPENSSL-LISTEN:"$PORT",cert="$COMBINED",verify=0,reuseaddr - 2>/dev/null
            printf "\n\033[1;34m[*]\033[0m Sesión cerrada.\n"
            ;;
        "")
            # Timeout sin datos, no hacer nada
            ;;
        *)
            printf "\033[1;31m[!]\033[0m Handshake inválido: '%s'\n" "$IDENT"
            ;;
    esac
    sleep 1
done
