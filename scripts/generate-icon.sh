#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/scripts/AppIcon.iconset"
ICNS="$ROOT/BarCode/AppIcon.icns"

echo "==> Rendering PNGs"
swift "$ROOT/scripts/generate-icon.swift" "$ICONSET"

echo "==> Packing into icns"
iconutil -c icns "$ICONSET" -o "$ICNS"

rm -rf "$ICONSET"
echo "✅ $ICNS"
