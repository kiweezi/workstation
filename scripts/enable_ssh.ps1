param(
  [string]$PublicKey = ""
)

# Log outputs to a file.
Start-Transcript -Path "C:\mgmt\logs\enable-ssh.log" -Append -Force

# Install OpenSSH Server.
# https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell#install-openssh-for-windows.
# Always install latest version.
Write-Output "Installing and configuring Open SSH server."
Add-WindowsCapability -Online -Name OpenSSH.Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
  New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Add the Ansible ssh key.
# https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration#authorizedkeysfile.
if ($PublicKey -ne "") {
  Write-Output "Adding Ansible ssh public key."
  New-Item -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value "$($PublicKey)" -Force
  icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
}

Stop-Transcript