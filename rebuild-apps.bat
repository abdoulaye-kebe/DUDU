@echo off
echo ========================================
echo REBUILD DUDU APPS - Client et Chauffeur
echo ========================================
echo.

:: Couleurs
color 0A

:: 1. Nettoyer et rebuild App Client
echo [1/4] Nettoyage App Client...
cd dudu_flutter
call flutter clean
echo.

echo [2/4] Build APK Client (Release)...
call flutter build apk --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Build client echoue!
    pause
    exit /b 1
)
echo.

:: 2. Nettoyer et rebuild App Chauffeur
echo [3/4] Nettoyage App Chauffeur...
cd ..\mobile_dudu_pro
call flutter clean
echo.

echo [4/4] Build APK Chauffeur (Release)...
call flutter build apk --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Build chauffeur echoue!
    pause
    exit /b 1
)
echo.

:: 3. Copier les APKs vers le dossier de telechargement
echo Copie des APKs vers backend/public/downloads/...
cd ..
if not exist "backend\public\downloads" mkdir "backend\public\downloads"

copy /Y "dudu_flutter\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-client.apk"
copy /Y "mobile_dudu_pro\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-pro.apk"
copy /Y "mobile_dudu_pro\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-driver.apk"

echo.
echo ========================================
echo BUILD TERMINE AVEC SUCCES!
echo ========================================
echo.
echo APKs generes:
echo - Client: backend\public\downloads\dudu-client.apk
echo - Pro (site): backend\public\downloads\dudu-pro.apk
echo - Chauffeur (alias): backend\public\downloads\dudu-driver.apk
echo.
echo Telechargement disponible sur:
echo - Client: http://41.208.146.203:3000/download-client.html
echo - Chauffeur: http://41.208.146.203:3000/download-driver.html
echo.
pause
