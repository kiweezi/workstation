<#
  .Synopsis
    Set list of File/Protocol Type Association Default Application Windows 8/10/11.
  .Description
    Uses PS-SFTA, which doesn't have a PS Gallery listing.
    Repo: https://github.com/DanysysTeam/PS-SFTA.
    Designed to be used with Ansible.
  .Parameter ScriptUrl
    The URL to get the PS-SFTA script from.
  .Parameter Assocations
    A list of dictionaries containing details of the associations required to be set.
  .Example
    # Set Firefox as default http.
    PS> $assocations = @(@{type = "protocol"; application = "FirefoxURL"; extension = "http"})
    PS> ./Apply-FTA.ps1 -Assocations $assocations
#>


param (
  [string]$ScriptUrl = "https://raw.githubusercontent.com/DanysysTeam/PS-SFTA/master/SFTA.ps1",
  [array]$Assocations
)

$filePath = "SFTA.ps1"
$changed = $false

try {
  # Download the script file. It doesn't have a PS Gallery listing.
  Invoke-RestMethod -Uri $ScriptUrl -OutFile $filePath

  # Run the file.
  . ".\$($filePath)"
}
catch {
  Write-Output "Could not download and import the script file."
  Write-Output $_
  $Ansible.Failed = $true
}

try {
  # Invoke the relevant function.
  # I think they both call the same function, weirdly.
  $Assocations | ForEach-Object {
    if ($_.type -eq "file") {
      if ($_.application -ne (Get-FTA $_.extension)) {
        Set-FTA -ProgId $_.application -Extension $_.extension
        $changed = $true
      }
    }
    else {
      if ($_.application -ne (Get-PTA $_.extension)) {
        Set-PTA -ProgId $_.application -Protocol $_.extension
        $changed = $true
      }
    }
  }
}
catch {
  Write-Output "Could not set file assocations."
  Write-Output $_
  $Ansible.Failed = $true
}

# Cleanup.
if (Test-Path $filePath) {
  Remove-Item $filePath
}

$Ansible.Changed = $changed