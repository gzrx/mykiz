#!/bin/bash
set -e
cd ~/mykiz

echo "==> Pulling latest..."
git pull --ff-only

echo "==> Rebuilding shared_core..."
export PATH=$PATH:/opt/dart-sdk/bin:$HOME/.pub-cache/bin:$HOME/flutter/bin
cd packages/shared_core && dart pub get -q && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -1
cd ~/mykiz

echo "==> Rebuilding backend..."
cd packages/backend && dart pub get -q && dart_frog build 2>&1 | tail -1
cd build && sed -i "s/>=3.0.0 <4.0.0/>=3.5.0 <4.0.0/" pubspec.yaml 2>/dev/null; dart pub get -q
cd ~/mykiz

echo "==> Restarting backend..."
echo 123 | sudo -S systemctl restart mykiz-backend 2>/dev/null

echo "==> Rebuilding admin web..."
cd packages/admin_web && flutter pub get -q && flutter build web --release 2>&1 | tail -1
cd ~/mykiz

echo "==> Done!"
