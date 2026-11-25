@echo off
set /p "receiver_ip=IP kompyutera s rozygryshem: "
if "%receiver_ip%"=="" exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0draw-sender.ps1" -ReceiverIp "%receiver_ip%"
pause
