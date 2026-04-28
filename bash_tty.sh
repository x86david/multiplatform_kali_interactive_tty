#!/bin/bash
PORT=${1:-2222}; PASS=$2
[ -z "$PASS" ] && { printf "Uso: %s <puerto> <pass>\n" "$0"; exit 1; }

# --- CERTIFICADOS ---
RAM_DIR="/dev/shm"; [ ! -d "$RAM_DIR" ] && RAM_DIR="/tmp"
COMB="$RAM_DIR/server.pem"
openssl req -x509 -newkey rsa:2048 -keyout "$COMB" -out "$COMB" -days 1 -nodes -subj "/CN=localhost" >/dev/null 2>&1

# Función para restaurar la terminal
cleanup() { rm -f "$COMB"; stty sane; exit; }
trap cleanup INT

while true; do
    printf "\033[1;32m[+]\033[0m ESPERANDO EN PUERTO \033[1;33m%s\033[0m...\n" "$PORT"
    
    # 1. Guardamos estado de la terminal
    OLD_STTY=$(stty -g)
    # 2. Ponemos terminal en modo raw para que pasen flechas/ctrl+c
    stty raw -echo
    # 3. Lanzamos socat. (echo $PASS) inyecta la contraseña al abrir.
    (sleep 1; echo "$PASS"; cat) | socat - OPENSSL-LISTEN:"$PORT",cert="$COMB",verify=0,reuseaddr
    # 4. Restauramos terminal
    stty $OLD_STTY
    
    printf "\n\033[1;31m[-] Sesión cerrada.\033[0m\n"
    sleep 1
done
