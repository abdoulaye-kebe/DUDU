@echo off
echo ========================================
echo BUILD DUDU CLIENT
echo ========================================
echo.

cd dudu_flutter

echo Nettoyage...
call flutter clean

echo.
echo Installation des dependances...
call flutter pub get

echo.
echo Build APK Release...
call flutter build apk --release --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo BUILD CLIENT REUSSI!
    echo ========================================
    echo.
    echo APK genere: dudu_flutter\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    :: Copier vers downloads
    cd ..
    if not exist "backend\public\downloads" mkdir "backend\public\downloads"
    copy /Y "dudu_flutter\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-client.apk"
    
    echo APK copie vers: backend\public\downloads\dudu-client.apk
    echo Telechargement: http://41.208.146.203:3000/download-client.html
) else (
    echo.
    echo ERREUR: Build client echoue!
)

echo.
pause
