#!/bin/bash
cd ~/mykiz
set -a
source .env
set +a
export PORT=3000
cd packages/backend/build
exec dart bin/server.dart
