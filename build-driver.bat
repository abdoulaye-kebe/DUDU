@echo off
echo ========================================
echo BUILD DUDU PRO - CHAUFFEUR
echo ========================================
echo.

cd mobile_dudu_pro

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
    echo BUILD CHAUFFEUR REUSSI!
    echo ========================================
    echo.
    echo APK genere: mobile_dudu_pro\build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    :: Copier vers downloads
    cd ..
    if not exist "backend\public\downloads" mkdir "backend\public\downloads"
    copy /Y "mobile_dudu_pro\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-driver.apk"
    
    echo APK copie vers: backend\public\downloads\dudu-driver.apk
    echo Telechargement: http://213.154.90.11:3000/download-driver.html
) else (
    echo.
    echo ERREUR: Build chauffeur echoue!
)

echo.
pause
