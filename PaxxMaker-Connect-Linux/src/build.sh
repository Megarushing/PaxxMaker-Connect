#!/usr/bin/env bash
# Builds PaxxMaker-Connect for Linux (needs Go) and packs the one download file:
#   ../Release/PaxxMaker-Connect-Linux-<version>.tar.gz
#   (program + Install/Deinstall + icon + Installation.txt)
set -e
cd "$(dirname "$0")"
ROOT="$(cd .. && pwd)"
VER=$(sed -nE 's/^\tversion = "([^"]+)"/\1/p' main.go)

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o build/PaxxMaker-Connect .

STAGE="build/tar/PaxxMaker-Connect"
rm -rf build/tar; mkdir -p "$STAGE"
cp build/PaxxMaker-Connect Installation.txt assets/icon.png "$STAGE/"
cp "$ROOT/PaxxMaker-Connect Install.sh" "$ROOT/PaxxMaker-Connect Deinstall.sh" "$STAGE/"
mkdir -p "$ROOT/Release"
TAR="$ROOT/Release/PaxxMaker-Connect-Linux-$VER.tar.gz"
rm -f "$TAR"
tar -czf "$TAR" -C build/tar PaxxMaker-Connect
rm -rf build/tar
echo "Done: src/build/PaxxMaker-Connect"
echo "Download: Release/$(basename "$TAR")"
