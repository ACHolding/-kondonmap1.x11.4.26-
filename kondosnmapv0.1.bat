@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem KondoSNmap v0.1 - Windows batch TCP connect scanner
rem Scan only systems you own or are authorized to test.
if "%~1"=="" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--help" goto usage
set "TARGET=%~1"
set "PORTS=%~2"
if not defined PORTS set "PORTS=21,22,23,25,53,80,110,135,139,143,443,445,587,993,995,1433,3306,3389,5432,5900,8080,8443"
set "TIMEOUT=400"
if not "%~3"=="" set "TIMEOUT=%~3"
set "KONDO_TARGET=%TARGET%"
set "KONDO_PORTS=%PORTS%"
set "KONDO_TIMEOUT=%TIMEOUT%"
echo.
echo ===== KondoSNmap v0.1 =====
echo Target: %TARGET%
echo Ports: %PORTS%
echo Timeout: %TIMEOUT% ms
echo.
rem PowerShell performs TCP connections; batch handles the command interface.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop'; try { $target=$env:KONDO_TARGET; $timeout=[int]$env:KONDO_TIMEOUT; if($timeout -lt 100 -or $timeout -gt 30000){throw 'Timeout must be 100-30000 ms'}; $ports=New-Object 'System.Collections.Generic.List[int]'; foreach($part in $env:KONDO_PORTS.Split(',')){ $part=$part.Trim(); if($part -match '^([0-9]+)-([0-9]+)$'){ $a=[int]$Matches[1]; $b=[int]$Matches[2]; if($a -gt $b -or ($b-$a) -gt 1023){throw 'Invalid range or range exceeds 1024 ports'}; for($p=$a;$p -le $b;$p++){[void]$ports.Add($p)} } elseif($part -match '^[0-9]+$'){[void]$ports.Add([int]$part)} else {throw ('Invalid port: '+$part)} }; $ports=@($ports | Sort-Object -Unique); if($ports.Count -gt 1024){throw 'Maximum 1024 ports per scan'}; foreach($p in $ports){if($p -lt 1 -or $p -gt 65535){throw ('Port out of range: '+$p)}}; $open=0; foreach($p in $ports){ $client=New-Object System.Net.Sockets.TcpClient; try { $task=$client.ConnectAsync($target,$p); if($task.Wait($timeout) -and $client.Connected){Write-Host ('{0,5}/tcp  OPEN' -f $p) -ForegroundColor Green; $open++} else {Write-Host ('{0,5}/tcp  closed/filtered' -f $p)} } catch {Write-Host ('{0,5}/tcp  closed/filtered' -f $p)} finally {$client.Dispose()} }; Write-Host ('Scan complete: {0} open of {1} TCP ports' -f $open,$ports.Count) } catch {Write-Host ('Error: '+$_.Exception.Message) -ForegroundColor Red; exit 1 }"
set "EXITCODE=%ERRORLEVEL%"
exit /b %EXITCODE%
:usage
echo KondoSNmap v0.1 - TCP connect port scanner for Windows
echo Usage: %~nx0 TARGET [PORTS] [TIMEOUT_MS]
echo Examples:
echo   %~nx0 127.0.0.1
echo   %~nx0 192.168.1.1 22,80,443,8080 500
echo   %~nx0 localhost 1-1000 200
echo Ports: comma-separated numbers or ranges, maximum 1024 ports.
echo Timeout: 100-30000 ms; default 400 ms.
exit /b 0
