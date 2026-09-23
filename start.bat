@echo off
REM launch.bat — FreeLLMAPI Portable
setlocal
set ROOT=%~dp0
set PATH=%ROOT%runtime\node;%PATH%

if not exist "%ROOT%app\server\dist\index.js" (
    echo First run detected - running setup...
    powershell -ExecutionPolicy Bypass -File "%ROOT%scripts\setup.ps1"
)

cd /d "%ROOT%app"
echo Starting FreeLLMAPI on http://localhost:3001 ...
start "" http://localhost:3001
node server\dist\index.js
pause