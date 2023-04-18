<#
  .Synopsis
    Installs Windows Subsystem for Linux (WSL).
  .Description
    Installs Windows Subsystem for Linux (WSL) with a specified distribution.
    Designed to be used with Ansible.
  .NOTES
    Author(s)  : kiweezi
  .Parameter Distribution
    The Linux distribution to install.
  .Example
    # Install Ubuntu WSL.
    PS> ./Add-WSL.ps1 -Distribution "Ubuntu"
#>


[CmdletBinding()]
param (
  [Parameter()]
  [string]
  $Distribution = "Ubuntu"
)


# Get credentials.
$username = $env:username
$password = $env:password
# Set defaults.
$changed = $false
$result = ""


function Install-WSL {
  param (
    [string]$Distribution
  )
  # Install WSL feature.
  wsl --distribution $Distribution --install

  # Create user account.
  wsl --distribution $Distribution useradd -m "$username"
  wsl --distribution $Distribution sh -c "echo "${username}:${password}" | chpasswd" # wrapped in sh -c to get the pipe to work
  wsl --distribution $Distribution chsh -s /bin/bash "$username"
  wsl --distribution $Distribution usermod -aG adm, cdrom, sudo, dip, plugdev "$username"
  # Set as default.
  wsl --distribution $Distribution --default-user "$username"

  # Update packages.
  $env:DEBIAN_FRONTEND = "noninteractive"
  $env:WSLENV += ":DEBIAN_FRONTEND"
  wsl --distribution $Distribution --user root sh -c 'apt-get update && apt-get full-upgrade -y && apt-get autoremove -y && apt-get autoclean'
}


try {
  # Install WSL distro if not already installed.
  if ((wsl --list --quiet | Where-Object { $_ -like "$($Distribution)*" }) -ne "") {
    $result = "WSL distribution $($Distribution) not found, installing now."
    Write-Debug $result
    
    # Install.
    Install-WSL -Distribution $Distribution
    $changed = $true
    
    $result = "Successfully installed WSL distribution: $($Distribution)."
    Write-Debug $result
  }
  else {
    $result = "Distribution already found, exiting."
    Write-Debug $result
  }
}
catch {
  $result = "ERROR! Failed to install WSL."
  Write-Output $result
  Write-Output $_
  $Ansible.Failed = $true
}


$Ansible.Changed = $changed
return $result