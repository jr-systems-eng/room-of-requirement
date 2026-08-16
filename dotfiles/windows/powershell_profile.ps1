# Room of Requirement - portable PowerShell defaults

$RorLocalBin = Join-Path $HOME '.local\bin'
if ((Test-Path $RorLocalBin) -and (($env:PATH -split [IO.Path]::PathSeparator) -notcontains $RorLocalBin)) {
    $env:PATH = "$RorLocalBin$([IO.Path]::PathSeparator)$env:PATH"
}

function ll {
    Get-ChildItem -Force @args
}

# Machine-specific PowerShell customizations stay outside Git.
$RorLocalProfile = Join-Path $HOME '.config\ror\local\powershell_profile.ps1'
if (Test-Path $RorLocalProfile) {
    . $RorLocalProfile
}

Remove-Variable RorLocalBin -ErrorAction SilentlyContinue
Remove-Variable RorLocalProfile -ErrorAction SilentlyContinue
