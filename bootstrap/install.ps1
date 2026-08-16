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

Write-Host 'Room of Requirement installed.'
Write-Host "Repository: $Root"
Write-Host "Command:    $Wrapper"
Write-Host ''
Write-Host 'This Windows wrapper requires Bash (for example Git Bash or WSL).'
Write-Host 'Add $HOME\.local\bin to PATH if needed, then try:'
Write-Host '  ror.ps1 doctor'
Write-Host '  ror.ps1 find ssh'
