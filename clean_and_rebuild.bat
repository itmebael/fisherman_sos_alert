@echo off
echo === Cleaning and Rebuilding App ===
echo.

echo 1. Cleaning Flutter build cache...
flutter clean

echo.
echo 2. Getting Flutter packages...
flutter pub get

echo.
echo 3. Building Android app...
flutter build apk --debug

echo.
echo 4. Running app...
flutter run

echo.
echo === Build Complete ===
echo The PermissionDefinitionsNotFoundException should now be fixed!
echo.
pause


