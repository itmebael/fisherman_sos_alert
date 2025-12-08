#!/bin/bash
echo "Starting local web server for Flutter web app..."
echo ""
echo "Navigate to: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
cd build/web
python3 -m http.server 8000 2>/dev/null || python -m SimpleHTTPServer 8000



