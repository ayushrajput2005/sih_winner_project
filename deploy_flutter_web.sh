#!/bin/bash

# Configuration
FLUTTER_PROJECT_DIR=$(pwd)
DJANGO_FRONTEND_DIR="$FLUTTER_PROJECT_DIR/backend_django/oil/marketplace/frontend"
BUILD_DIR="$FLUTTER_PROJECT_DIR/build/web"

echo "=========================================="
echo "🚀 Deploying Flutter Web to Django..."
echo "=========================================="

# 1. Build Flutter Web App
echo "📦 Building Flutter Web App..."
flutter build web --release --dart-define=API_BASE_URL=/api

if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed!"
    exit 1
fi

# 2. Clean Destination
echo "🧹 Cleaning Django frontend directory..."
rm -rf "$DJANGO_FRONTEND_DIR"/*

# 3. Copy Assets
echo "📂 Copying build artifacts..."
cp -r "$BUILD_DIR"/* "$DJANGO_FRONTEND_DIR/"

# 4. Patch index.html
echo "🔧 Patching index.html for Django static files..."
INDEX_HTML="$DJANGO_FRONTEND_DIR/index.html"
FLUTTER_BOOTSTRAP_JS="$DJANGO_FRONTEND_DIR/flutter_bootstrap.js"

# Use sed to replace paths with /static/ prefix
# Note: This is tailored to the specific output of Flutter build (icons, manifest, favicon, bootstrap)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS syntax
  sed -i '' 's|href="icons/|href="/static/icons/|g' "$INDEX_HTML"
  sed -i '' 's|href="favicon.png"|href="/static/favicon.png"|g' "$INDEX_HTML"
  sed -i '' 's|href="manifest.json"|href="/static/manifest.json"|g' "$INDEX_HTML"
  sed -i '' 's|src="flutter_bootstrap.js"|src="/static/flutter_bootstrap.js"|g' "$INDEX_HTML"
  # Patch flutter_bootstrap.js to look for main.dart.js in /static/
  sed -i '' 's|serviceWorkerSettings: {|entrypointBaseUrl: "/static/", serviceWorkerSettings: {|g' "$FLUTTER_BOOTSTRAP_JS"
else
  # Linux/GNU syntax
  TIMESTAMP=$(date +%s)
  sed -i 's|href="icons/|href="/static/icons/|g' "$INDEX_HTML"
  sed -i 's|href="favicon.png"|href="/static/favicon.png"|g' "$INDEX_HTML"
  sed -i 's|href="manifest.json"|href="/static/manifest.json"|g' "$INDEX_HTML"
  sed -i "s|src=\"flutter_bootstrap.js\"|src=\"/static/flutter_bootstrap.js?v=$TIMESTAMP\"|g" "$INDEX_HTML"
  sed -i 's|<base href="/">|<base href="/static/">|g' "$INDEX_HTML"
  # Patch flutter_bootstrap.js to look for main.dart.js in /static/
  sed -i 's|serviceWorkerSettings: {|entrypointBaseUrl: "/static/", serviceWorkerSettings: {|g' "$FLUTTER_BOOTSTRAP_JS"
fi

echo "✅ Deployment Complete!"
echo "👉 You can now run: python3 manage.py runserver"
