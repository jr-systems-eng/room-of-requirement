# PowerShell Snippets

## Files and paths

```powershell
Get-Location
Get-ChildItem -Force
Get-ChildItem C:\Path -Recurse -File | Sort-Object Length -Descending | Select-Object -First 20 FullName,Length
Test-Path C:\Path\file.txt
Resolve-Path .\relative\path
```

## Services

```powershell
Get-Service
Get-Service sshd
Get-Service sshd | Format-List *
Restart-Service sshd
```

Inspect first; only restart when the remediation calls for it.

## Processes

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10
Get-CimInstance Win32_Process -Filter "ProcessId = 1234" | Select-Object ProcessId,Name,CommandLine
```

## Networking

```powershell
Get-NetIPAddress
Get-NetRoute
Get-NetTCPConnection -State Listen
Test-NetConnection host.example.com -Port 443
Resolve-DnsName host.example.com
ipconfig /all
```

## Event logs

```powershell
Get-WinEvent -LogName System -MaxEvents 50
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2,3; StartTime=(Get-Date).AddHours(-1)}
```

## JSON

```powershell
$data = Get-Content .\file.json -Raw | ConvertFrom-Json
$data.property
$data | ConvertTo-Json -Depth 10
```

## Environment variables

```powershell
$env:PATH
$env:NAME = 'value'
Get-ChildItem Env:
```

## Prompt for a secret without putting it in history

```powershell
$secure = Read-Host 'Password' -AsSecureString
```

For tools that require a plain string, convert only in memory and avoid printing/logging it.

## Timestamped filename

```powershell
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = "collection-$env:COMPUTERNAME-$stamp.txt"
```

## Check command availability

```powershell
if (Get-Command git -ErrorAction SilentlyContinue) {
    git --version
}
```
