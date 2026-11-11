@echo off
rem Pintu masuk Windows. Menjalankan setup.ps1 tanpa perlu mengubah ExecutionPolicy sistem.
rem Contoh: setup.cmd            setup.cmd --profile full            setup.cmd --check
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%
