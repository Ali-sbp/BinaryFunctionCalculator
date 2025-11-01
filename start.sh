#!/bin/bash

echo "🚀 Boolean Function Calculator - Quick Start"
echo "============================================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install it from the App Store."
    exit 1
fi

echo "✅ Xcode found"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Open the Xcode project
echo "📱 Opening Xcode project..."
open BooleanCalculator.xcodeproj

echo ""
echo "✅ Project opened in Xcode!"
echo ""
echo "Next steps:"
echo "1. Wait for Xcode to load the project"
echo "2. Select your target device (iPhone simulator or Mac)"
echo "3. Press ⌘R (or click the Play button) to build and run"
echo ""
echo "Enjoy your Boolean Function Calculator! 🎉"
