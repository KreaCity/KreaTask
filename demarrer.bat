@echo off
rem Lance les cartes d'equipe sur Windows : pose PocketBase, demarre le serveur,
rem ouvre le tableau dans le navigateur. Arreter : Ctrl + C dans cette fenetre.
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set VERSION=0.40.5
if "%PORT%"=="" set PORT=8090
set ADRESSE=127.0.0.1:%PORT%

rem 1. PocketBase, sorti de son archive au premier lancement.
if not exist pocketbase.exe (
  echo Installation de PocketBase %VERSION%...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -Path 'archives\pocketbase_%VERSION%_windows_amd64.zip' -DestinationPath '_pocketbase'; Move-Item -Force '_pocketbase\pocketbase.exe' '.'; Remove-Item -Recurse -Force '_pocketbase'"
  if not exist pocketbase.exe (
    echo Impossible d'extraire PocketBase. Verifie que le dossier archives est bien la.
    pause
    exit /b 1
  )
)

rem 2. Le navigateur s'ouvre des que le serveur repond.
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "for ($i = 0; $i -lt 40; $i++) { try { Invoke-WebRequest -UseBasicParsing -Uri 'http://%ADRESSE%/api/health' -TimeoutSec 1 | Out-Null; Start-Process 'http://%ADRESSE%'; break } catch { Start-Sleep -Milliseconds 250 } }"

echo Le tableau : http://%ADRESSE%
echo L'administration : http://%ADRESSE%/_/
echo Pour arreter : Ctrl + C
echo.
pocketbase.exe serve --http "%ADRESSE%" --dir pb_data --migrationsDir pb_migrations --publicDir pb_public --hooksDir pb_hooks
pause
