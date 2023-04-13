<#
  .Synopsis
    Installs and configures OpenSSH Server on Windows.
  .Description
    Installs OpenSSH Server and optionally installs a public SSH key on Windows.
  .NOTES
    Author(s)  : kiweezi
  .Parameter PublicKey
    The SSH public key to allow access to the server via SSH key.
  .Example
    # Install SSH server and add a public SSH key to provide access.
    PS> ./Add-SSHServer.ps1 -PublicKey "ssh-public-key"
#>


[CmdletBinding()]
param (
  [Parameter()]
  [string]
  $PublicKey = ""
)


# Log outputs to a file.
Start-Transcript -Path "C:\mgmt\logs\add-sshserver.log" -Append -Force


# Install the latest version of OpenSSH Server.
# https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell#install-openssh-for-windows.
try {
  Write-Debug "Installing and configuring Open SSH Server."
  Add-WindowsCapability -Online -Name OpenSSH.Server
  Start-Service sshd
  Set-Service -Name sshd -StartupType 'Automatic'
  if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
  }
  New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
}
catch {
  Write-Output "ERROR! Failed to install OpenSSH Server."
  Write-Output $_
}

# Add the Ansible ssh key.
# https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_server_configuration#authorizedkeysfile.
try {
  if ($PublicKey -ne "") {
    Write-Debug "Adding public SSH key."
    New-Item -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value "$($PublicKey)" -Force
    icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
  }  
}
catch {
  Write-Output "ERROR! Failed to add public SSH key."
  Write-Output $_
}


Stop-Transcript