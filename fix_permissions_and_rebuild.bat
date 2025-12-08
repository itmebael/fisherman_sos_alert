@echo off
echo === Fixing Permissions and Rebuilding App ===
echo.

echo 1. Stopping any running Flutter processes...
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dart.exe 2>nul

echo.
echo 2. Cleaning Flutter build cache...
flutter clean

echo.
echo 3. Removing build directories...
if exist build rmdir /s /q build
if exist android\app\build rmdir /s /q android\app\build
if exist ios\build rmdir /s /q ios\build

echo.
echo 4. Getting Flutter packages...
flutter pub get

echo.
echo 5. Verifying Android manifest permissions...
findstr "ACCESS_FINE_LOCATION" android\app\src\main\AndroidManifest.xml
if %errorlevel% neq 0 (
    echo ERROR: Location permissions not found in AndroidManifest.xml
    pause
    exit /b 1
)

echo.
echo 6. Verifying iOS Info.plist permissions...
findstr "NSLocationWhenInUseUsageDescription" ios\Runner\Info.plist
if %errorlevel% neq 0 (
    echo ERROR: Location permissions not found in Info.plist
    pause
    exit /b 1
)

echo.
echo 7. Building Android app...
flutter build apk --debug

echo.
echo 8. Installing and running app...
flutter install
flutter run

echo.
echo === Build Complete ===
echo The PermissionDefinitionsNotFoundException should now be fixed!
echo.
echo If you still get the error:
echo 1. Uninstall the app from your device
echo 2. Run: flutter clean
echo 3. Run: flutter pub get
echo 4. Run: flutter run
echo.
pause


