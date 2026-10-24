@echo off
rem IRIDIUM S - First Person Camera: puts back the game's tables.sds saved by
rem INSTALL_FP_CAMERA.bat (the third-person camera again). Close the game first.
setlocal
set "HERE=%~dp0"
for %%I in ("%HERE%..\..") do set "GAME=%%~fI"
set "LIVE=%GAME%\sds_retail\tables\tables.sds"
set "BAK=%HERE%backup\tables.sds.original"
tasklist /FI "IMAGENAME eq Mafia3DefinitiveEdition.exe" 2>nul | find /I "Mafia3DefinitiveEdition.exe" >nul && (
  echo Close Mafia III first.
  goto fail
)
if not exist "%BAK%" (
  echo No backup here: the camera config was never installed from this folder.
  echo Steam - Mafia III - Properties - Installed Files - Verify integrity also restores tables.sds.
  goto fail
)
copy /Y "%BAK%" "%LIVE%" >nul || goto fail
echo OK: the game's own tables.sds is back (third-person camera).
pause
exit /b 0

:fail
pause
exit /b 1
