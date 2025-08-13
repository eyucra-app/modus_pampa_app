#!/bin/bash

# Install Flutter for Vercel deployment
echo "Installing Flutter..."

# Download and extract Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Set Flutter path
export PATH="$PATH:`pwd`/flutter/bin"
export FLUTTER_ROOT="`pwd`/flutter"

# Pre-cache binaries
./flutter/bin/flutter precache --web

# Enable web support
./flutter/bin/flutter config --enable-web

# Get dependencies
./flutter/bin/flutter pub get

echo "Flutter installation completed!"