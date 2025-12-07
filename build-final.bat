@echo off
color 0A
echo ========================================
echo   BUILD FINAL - DUDU Apps
echo ========================================
echo.

:: 1. Build App Client
echo [1/6] Nettoyage complet App Client...
cd dudu_flutter
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
call flutter clean
echo.

echo [2/6] Installation dependances Client...
call flutter pub get
echo.

echo [3/6] Build APK Client (Release)...
call flutter build apk --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERREUR: Build client echoue!
    cd ..
    pause
    exit /b 1
)
echo ✅ APK Client OK
cd ..
echo.

:: 2. Build App Chauffeur
echo [4/6] Nettoyage complet App Chauffeur...
cd mobile_dudu_pro
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool
call flutter clean
echo.

echo [5/6] Installation dependances Chauffeur...
call flutter pub get
echo.

echo [6/6] Build APK Chauffeur (Release)...
call flutter build apk --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERREUR: Build chauffeur echoue!
    cd ..
    pause
    exit /b 1
)
echo ✅ APK Chauffeur OK
cd ..
echo.

:: 3. Copier les APKs
echo Copie des APKs...
if not exist "backend\public\downloads" mkdir "backend\public\downloads"

copy /Y "dudu_flutter\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-client.apk"
copy /Y "mobile_dudu_pro\build\app\outputs\flutter-apk\app-release.apk" "backend\public\downloads\dudu-driver.apk"

echo.
echo ========================================
echo   ✅✅✅ BUILD TERMINE! ✅✅✅
echo ========================================
echo.
echo APKs generes:
echo - Client:    backend\public\downloads\dudu-client.apk
echo - Chauffeur: backend\public\downloads\dudu-driver.apk
echo.
echo Telechargement:
echo - Client:    http://213.154.90.11:3000/download-client.html
echo - Chauffeur: http://213.154.90.11:3000/download-driver.html
echo.
echo Demarrer backend: cd backend ^&^& npm run dev
echo.
pause
