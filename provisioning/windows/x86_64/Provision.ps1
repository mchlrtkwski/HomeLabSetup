# Windows Provisioning Script
# 
# Run this command in an elevated PowerShell prompt:
# Set-ExecutionPolicy Bypass -Scope Process
# First Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Set it back to default when you are done:
# Set-ExecutionPolicy Restricted

# Install WinGet for Windows 10 feature Installations
choco install winget

# Fetch and Install the Latest PowerShell
winget install Microsoft.PowerShell

# Fetch and Install the Latest OpenSSH Windows Feature
# Start the OpenSSH Service and set it to Automatic, 
winget install "openssh beta"
netsh advfirewall firewall add rule name="Open SSH Port 22" dir=in action=allow protocol=TCP localport=22 remoteip=any
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Forget What these Two are for:
# 1) Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
# 2) Enable-NetFirewallRule -DisplayGroup "Remote Desktop" not working yet 

# Install Git and Set it as the Default Shell
choco install git
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\Git\bin\bash.exe" -PropertyType String -Force

# General Development Tools
choco install visualstudio2022community
choco install vscode
choco install 7zip
choco install github-desktop

# Install Windows Subsystem for Linux and Install docker-desktop
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
choco install docker-desktop

# Game Engines and Tools
choco install steamcmd
choco install epicgameslauncher

# Asset Development Tools
choco install gimp
choco install blender

# Customization because Windows is Ugly
choco install rainmeter

# Enabling RDP Wrapper, this requires special attention
Stop-Service 'remote desktop services'
choco install rdpwrapper
Start-Service 'remote desktop services'
