#!/bin/bash

# Define variables
INSTALL_DIR="$HOME/adb-photo-sync"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SYSTEMD_DIR/adb-photo-sync.service"
SCRIPT_FILE="$INSTALL_DIR/adb-photo-sync.sh"

# Ensure ~/.local/bin is in PATH for the script
export PATH="$HOME/.local/bin:$PATH"

# Prompt user for the frame's IP address
read -p "Enter the IP address of the smart photo frame: " FRAME_IP

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo "❌ adb is not installed!"
    echo "📌 Please install adb using: sudo apt install adb"
    exit 1
else
    echo "✅ adb is installed!"
fi

echo "📁 Creating sync directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

echo "🚀 Setting up the sync script..."
cat <<EOF > "$SCRIPT_FILE"
#!/bin/bash

# Ensure ~/.local/bin is in the PATH for adb
export PATH="\$HOME/.local/bin:\$PATH"

# Configuration
FRAME_IP="$FRAME_IP"
SYNC_FOLDER="$INSTALL_DIR"
FRAME_SYNC_PATH="/storage/emulated/0/Pictures"

echo "🔌 Connecting to ADB device at \$FRAME_IP..."
adb connect "\$FRAME_IP"
ADB_STATUS=\$?
if [ \$ADB_STATUS -ne 0 ]; then
    echo "❌ ADB connection failed (Exit Code: \$ADB_STATUS)"
    exit 1
fi

echo "📂 Pushing photos to the frame..."
adb push "\$SYNC_FOLDER/" "\$FRAME_SYNC_PATH"
PUSH_STATUS=\$?
if [ \$PUSH_STATUS -ne 0 ]; then
    echo "❌ File push failed (Exit Code: \$PUSH_STATUS)"
    exit 1
fi

echo "🔄 Triggering Media Scanner..."
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://\$FRAME_SYNC_PATH"
SCAN_STATUS=\$?
if [ \$SCAN_STATUS -ne 0 ]; then
    echo "❌ Failed to trigger media scan (Exit Code: \$SCAN_STATUS)"
    exit 1
fi

echo "✅ Sync completed successfully!"
EOF

# Make the script executable
chmod +x "$SCRIPT_FILE"

echo "📁 Creating systemd user directory at $SYSTEMD_DIR..."
mkdir -p "$SYSTEMD_DIR"

echo "📝 Creating user systemd service at $SERVICE_FILE..."
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=ADB Photo Sync Service
After=network.target

[Service]
ExecStart=$SCRIPT_FILE
Restart=always
User=$USER
Group=$USER
WorkingDirectory=$INSTALL_DIR
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

echo "🔄 Reloading user systemd and enabling the service..."
systemctl --user daemon-reload
systemctl --user enable adb-photo-sync
systemctl --user start adb-photo-sync

echo "✅ Installation complete!"
echo "📂 Sync folder: $INSTALL_DIR"
echo "⚙️ User Service Name: adb-photo-sync.service"
echo "🔍 Check status: systemctl --user status adb-photo-sync"
