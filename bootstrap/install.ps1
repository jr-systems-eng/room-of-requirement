param(
    [string]$PackageProfile = '',
    [string[]]$Dotfiles = @(),
    [switch]$NoDoctor
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BinDir = Join-Path $HOME '.local\bin'
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

$Wrapper = Join-Path $BinDir 'ror.ps1'
$Ror = Join-Path $Root 'bin\ror'

@"
`$env:ROR_HOME = '$Root'
& bash '$Ror' @args
"@ | Set-Content -Encoding UTF8 $Wrapper

Write-Host 'Room of Requirement command installed.'
Write-Host "Repository: $Root"
Write-Host "Command:    $Wrapper"
Write-Host ''
Write-Host 'This Windows wrapper requires Bash (for example Git Bash or WSL).'

if ($PackageProfile) {
    Write-Host "Installing requested package profile: $PackageProfile"
    & bash $Ror pkg install $PackageProfile
    if ($LASTEXITCODE -ne 0) { throw 'ROR package profile installation failed.' }
}

foreach ($Group in $Dotfiles) {
    Write-Host "Installing requested dotfile group: $Group"
    & bash $Ror dotfiles install $Group
    if ($LASTEXITCODE -ne 0) { throw "ROR dotfile installation failed for $Group." }
}

if (-not $NoDoctor) {
    Write-Host 'Running read-only environment check...'
    & bash $Ror doctor
    if ($LASTEXITCODE -ne 0) { throw 'ROR doctor failed.' }
}

Write-Host ''
Write-Host 'Add $HOME\.local\bin to PATH if needed.'
Write-Host 'Useful next commands:'
Write-Host '  ror.ps1 doctor --install-suggestions'
Write-Host '  ror.ps1 pkg list'
Write-Host '  ror.ps1 dotfiles status'
Write-Host '  ror.ps1 dotfiles diff all'
