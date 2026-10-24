@echo off
rem IRIDIUM S - First Person Camera.
rem Writes first-person values into the game's own camera config
rem (sds_retail\tables\tables.sds): mouse, walking where you look, aiming and
rem collision all stay the game's. Close the game first.
rem UNINSTALL_FP_CAMERA.bat puts the game's file back.
setlocal
set "HERE=%~dp0"
for %%I in ("%HERE%..\..") do set "GAME=%%~fI"
if not exist "%GAME%\Mafia3DefinitiveEdition.exe" (
  echo This folder must be ^<Mafia III^>\IRIDIUM\fp_camera
  echo ^(no Mafia3DefinitiveEdition.exe in "%GAME%"^).
  goto fail
)
tasklist /FI "IMAGENAME eq Mafia3DefinitiveEdition.exe" 2>nul | find /I "Mafia3DefinitiveEdition.exe" >nul && (
  echo Close Mafia III first.
  goto fail
)
set "LIVE=%GAME%\sds_retail\tables\tables.sds"
set "BAK=%HERE%backup\tables.sds.original"
set "NEW=%HERE%backup\tables.sds.first_person"
if not exist "%LIVE%" (
  echo No "%LIVE%".
  goto fail
)
if not exist "%HERE%backup" mkdir "%HERE%backup"

rem The game's own file is kept once. If it changed since (a game update, a file
rem check in Steam, another mod), the changed one becomes the original.
if not exist "%BAK%" goto take_backup
fc /b "%LIVE%" "%BAK%" >nul 2>&1 && goto backup_ok
if exist "%NEW%" fc /b "%LIVE%" "%NEW%" >nul 2>&1 && goto backup_ok
echo The game's tables.sds changed since the last install: taking it as the new original.
copy /Y "%BAK%" "%BAK%.old" >nul
:take_backup
copy /Y "%LIVE%" "%BAK%" >nul || goto fail
echo Backup of the game's tables.sds: "%BAK%"
:backup_ok

rem Always built from the untouched original, so installing twice is safe.
rem Python first when it really runs (not the Microsoft Store stub): the one-file
rem fp_camera.exe needs no Python, but antivirus programs sometimes flag such exes.
:build
python -c "import zlib" >nul 2>&1 && goto build_py
if exist "%HERE%fp_camera.exe" goto build_exe
echo Python 3 is needed to run the patcher: https://www.python.org/downloads/
echo ^(tick "Add python.exe to PATH" in its installer^).
goto fail
:build_py
set PYTHONIOENCODING=utf-8
python "%HERE%build_fp_camera.py" "%HERE%fp_rules.json" "%BAK%" "%NEW%"
goto built
:build_exe
"%HERE%fp_camera.exe" "%HERE%fp_rules.json" "%BAK%" "%NEW%"
:built
if errorlevel 3 goto zopfli
if errorlevel 1 goto not_built
goto install

:zopfli
rem A block of the archive needs a stronger compressor than zlib to fit.
if defined TRIED_ZOPFLI goto not_built
set TRIED_ZOPFLI=1
where python >nul 2>&1 || goto not_built
echo A block needs a stronger compressor. Installing zopfli: python -m pip install zopfli
python -m pip install zopfli || goto not_built
set USE_PYTHON=1
goto build

:not_built
echo The patch was not built; the game's tables.sds is left as it was.
echo Details: "%NEW%.report.txt"
goto fail

:install
copy /Y "%NEW%" "%LIVE%" >nul || goto fail
echo.
echo OK: the first-person camera config is installed.
echo In the game the first-person view turns itself on (needs IRIDIUM S - Trainer M3);
echo F5 switches first and third person, F4 - Camera has the settings.
echo Run this again after a game update or a file check in Steam.
pause
exit /b 0

:fail
pause
exit /b 1
