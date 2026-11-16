@echo off
rem Perezapusk sebya v svernutom okne. Zakryt eto okno na paneli zadach = ostanovit prikol.
if not "%~1"=="run" (
  start "otvety - zakroj menya chtoby ostanovit" /min "%~f0" run
  exit /b
)

set m=0

:loop
timeout /t 60 /nobreak >nul
set /a m+=1

rem --- kazhduyu minutu: smena yazyka (Alt+Shift) ---
powershell -NoProfile -Command "$s=New-Object -ComObject WScript.Shell; $s.SendKeys('%%+')"

rem --- kazhdye 2 minuty: klik levoj knopkoj myshi tam, gde stoit kursor ---
set /a r=m %% 2
if %r%==0 powershell -NoProfile -Command "Add-Type -MemberDefinition '[DllImport(\"user32.dll\")] public static extern void mouse_event(int a,int b,int c,int d,int e);' -Name M -Namespace W; [W.M]::mouse_event(2,0,0,0,0); [W.M]::mouse_event(4,0,0,0,0)"

rem --- kazhdye 3 minuty: CapsLock, menyu Pusk i okno komandnoj stroki ---
set /a r=m %% 3
if %r%==0 (
  powershell -NoProfile -Command "$s=New-Object -ComObject WScript.Shell; $s.SendKeys('{CAPSLOCK}'); Start-Sleep 1; $s.SendKeys('^{ESC}'); Start-Sleep 2; $s.SendKeys('{ESC}')"
  start "" cmd /k ver
)

goto loop
