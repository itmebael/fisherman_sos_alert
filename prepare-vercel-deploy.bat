@echo off
echo ========================================
echo Preparing Flutter Web Build for Vercel
echo ========================================
echo.

echo Step 1: Building Flutter web app...
flutter build web --release
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Checking build/web directory...
if not exist "build\web\index.html" (
    echo ERROR: build/web/index.html not found!
    pause
    exit /b 1
)

echo.
echo Step 3: Adding build/web to git...
git add -f build/web/
if errorlevel 1 (
    echo WARNING: git add failed. Make sure you're in a git repository.
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Build files are ready.
echo ========================================
echo.
echo Next steps:
echo 1. Commit: git commit -m "Add Flutter web build for Vercel"
echo 2. Push: git push
echo 3. Vercel will auto-deploy, or run: vercel --prod
echo.
pause


