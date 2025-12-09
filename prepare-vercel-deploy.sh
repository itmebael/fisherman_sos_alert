#!/bin/bash
set -e

echo "========================================"
echo "Preparing Flutter Web Build for Vercel"
echo "========================================"
echo ""

echo "Step 1: Building Flutter web app..."
flutter build web --release

if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html not found!"
    exit 1
fi

echo ""
echo "Step 2: Adding build/web to git..."
git add -f build/web/

echo ""
echo "========================================"
echo "SUCCESS! Build files are ready."
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Commit: git commit -m 'Add Flutter web build for Vercel'"
echo "2. Push: git push"
echo "3. Vercel will auto-deploy, or run: vercel --prod"
echo ""

