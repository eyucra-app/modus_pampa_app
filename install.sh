#!/bin/bash

# Install Flutter for Vercel deployment
echo "Installing Flutter..."

# Download and extract Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-cache binaries
flutter precache --web

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

echo "Flutter installation completed!"