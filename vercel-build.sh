#!/bin/bash
set -e

echo "🚀 Vercel Build Script for Flutter Web"

# Check if build/web already exists (pre-built)
if [ -d "build/web" ] && [ -f "build/web/index.html" ] && [ -f "build/web/main.dart.js" ]; then
    echo "✅ Pre-built Flutter web files found. Using existing build..."
    echo "📁 Verifying build/web directory structure..."
    ls -la build/web/ | head -20
    echo "✅ Build directory verified successfully"
    exit 0
fi

# Try to build if Flutter is available
if command -v flutter &> /dev/null; then
    echo "📦 Flutter found. Building web app..."
    flutter pub get
    flutter build web --release --web-renderer canvaskit
    echo "✅ Build completed!"
else
    echo "⚠️  Flutter not found in PATH."
    echo "📝 To build locally, run: flutter build web --release"
    echo "📁 Then commit the build/web directory and redeploy."
    
    # Check if we have any web files at all
    if [ ! -d "build/web" ]; then
        echo "❌ Error: No build/web directory found!"
        echo "Please build the Flutter web app locally first:"
        echo "  1. Run: flutter build web --release"
        echo "  2. Commit the build/web directory"
        echo "  3. Push and redeploy"
        exit 1
    fi
fi


