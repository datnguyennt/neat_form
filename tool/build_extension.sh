#!/bin/bash
set -e

# NeatForm Flutter DevTools Extension Build Script
echo "========================================================"
echo "🚀 Building NeatForm Flutter DevTools Extension..."
echo "========================================================"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSION_DIR="$ROOT_DIR/packages/neat_form_devtools_extension"
BUILD_TARGET="$ROOT_DIR/extension/devtools/build"

echo "📁 Root Directory: $ROOT_DIR"
echo "📁 Extension Source: $EXTENSION_DIR"
echo "📁 Output Directory: $BUILD_TARGET"

# 1. Clean previous build target
rm -rf "$BUILD_TARGET"
mkdir -p "$BUILD_TARGET"

# 2. Build Flutter Web Extension
cd "$EXTENSION_DIR"
flutter pub get
flutter build web --pwa-strategy=none --no-tree-shake-icons --output="$BUILD_TARGET"

echo "========================================================"
echo "✅ DevTools Extension successfully built to:"
echo "   $BUILD_TARGET"
echo "========================================================"
