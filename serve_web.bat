@echo off
echo Starting local web server for Flutter web app...
echo.
echo Navigate to: http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo.
cd build\web
python -m http.server 8000
if errorlevel 1 (
    echo Python 3 not found, trying Python 2...
    python -m SimpleHTTPServer 8000
)



