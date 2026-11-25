@echo off
rem Perezapusk sebya v svernutom okne. Zakryt eto okno na paneli zadach = ostanovit prikol.
if not "%~1"=="run" (
  start "otvety" /min "%~f0" run
  exit /b
)

rem Okno dlya risunka iz Paint na drugom kompyutere.
start "risunok" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0draw-receiver.ps1"

set /a seconds=0

:loop
rem Odno okno cmd poyavlyaetsya na sekundu i zakryvaetsya pered sleduyushchim.
start "" /wait cmd /c "timeout /t 1 /nobreak >nul"
set /a seconds+=1

rem Kazhdye 10 sekund otkryvaem foto iz papki s batnikom.
set /a photo_time=seconds %% 10
if %photo_time%==0 if exist "%~dp0foto.jpg" start "" "%~dp0foto.jpg"

goto loop
