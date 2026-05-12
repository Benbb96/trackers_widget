#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_DIR=$(ls -d ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-* | tail -1)
DEV_KEY=~/.Garmin/developer_key
PRG="$SCRIPT_DIR/bin/garmin.prg"
MTP_DEST="mtp://091e_50d9_0000d7709f00/Internal Storage/GARMIN/Apps/Trackers.prg"

echo "→ Build..."
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$SDK_DIR/bin/monkeybrains.jar" \
  -o "$PRG" \
  -f "$SCRIPT_DIR/monkey.jungle" \
  -y "$DEV_KEY" \
  -d epix2pro47mm -w

echo "→ Déploiement sur la montre..."
gio copy -p "$PRG" "$MTP_DEST"

echo "✓ Terminé — débranche et lance Trackers sur la montre"
