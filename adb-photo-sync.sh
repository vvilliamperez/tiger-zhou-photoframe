#!/bin/bash

# Configuration
FRAME_IP="__FRAME_IP__"  # Placeholder, will be replaced by install script
SYNC_FOLDER="$HOME/adb-photo-sync"
FRAME_SYNC_PATH="/storage/emulated/0/Pictures/"

echo "🔌 Connecting to ADB device at $FRAME_IP..."
adb connect "$FRAME_IP" || { echo "❌ ADB connection failed"; exit 1; }

echo "📂 Syncing photos to the frame..."
adb push "$SYNC_FOLDER/" "$FRAME_SYNC_PATH" || { echo "❌ Sync failed"; exit 1; }

echo "🔄 Triggering Media Scanner..."
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$FRAME_SYNC_PATH" || { echo "❌ Failed to trigger media scan"; exit 1; }

echo "✅ Sync completed successfully!"
