#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_DIR=$(ls -d ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-* | tail -1)
DEV_KEY=~/.Garmin/developer_key
PRG="$SCRIPT_DIR/bin/garmin.prg"
MTP_BASE="mtp://091e_50d9_0000d7709f00/Internal Storage/GARMIN/Apps"
MTP_DEST="$MTP_BASE/Trackers.prg"
RESOURCES="$SCRIPT_DIR/resources/resources.xml"

# Injection du token API depuis .env si présent
REAL_TOKEN=""
ENV_FILE="$SCRIPT_DIR/../.env"
if [ -f "$ENV_FILE" ]; then
    REAL_TOKEN=$(grep '^API_TOKEN=' "$ENV_FILE" | cut -d= -f2)
fi

restore_token() {
    if [ -n "$REAL_TOKEN" ] && [ "$REAL_TOKEN" != "YOUR_API_TOKEN" ]; then
        sed -i "s|$REAL_TOKEN|YOUR_API_TOKEN|g" "$RESOURCES"
    fi
}
trap restore_token EXIT

if [ -n "$REAL_TOKEN" ] && [ "$REAL_TOKEN" != "YOUR_API_TOKEN" ]; then
    echo "→ Injection du token API..."
    sed -i "s|YOUR_API_TOKEN|$REAL_TOKEN|g" "$RESOURCES"
fi

echo "→ Build..."
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$SDK_DIR/bin/monkeybrains.jar" \
  -o "$PRG" \
  -f "$SCRIPT_DIR/monkey.jungle" \
  -y "$DEV_KEY" \
  -d epix2pro47mm -w

echo "→ Déploiement sur la montre..."
SET_DEST="$MTP_BASE/SETTINGS/Trackers.SET"
gio remove "$SET_DEST" 2>/dev/null || true  # supprime le .SET pour forcer la recréation depuis les défauts du .prg
gio copy -p "$PRG" "$MTP_DEST"

echo "✓ Terminé — débranche et lance Trackers sur la montre"
