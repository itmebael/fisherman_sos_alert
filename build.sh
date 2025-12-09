#!/bin/bash
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "📦 Flutter not found. Installing Flutter SDK..."
    
    # Install Flutter SDK
    FLUTTER_VERSION="3.24.0"
    FLUTTER_SDK_DIR="$HOME/flutter"
    
    if [ ! -d "$FLUTTER_SDK_DIR" ]; then
        echo "Downloading Flutter SDK..."
        git clone --branch stable https://github.com/flutter/flutter.git -c advice.detachedHead=false $FLUTTER_SDK_DIR
        cd $FLUTTER_SDK_DIR
        git checkout $FLUTTER_VERSION
    fi
    
    # Add Flutter to PATH
    export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
    
    # Accept Flutter licenses
    flutter doctor --android-licenses || true
    flutter doctor || true
fi

# Verify Flutter installation
flutter --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"


