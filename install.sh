#!/bin/bash

# Define variables
INSTALL_DIR="$HOME/adb-photo-sync"
SERVICE_FILE="/etc/systemd/system/adb-photo-sync.service"
SCRIPT_FILE="$INSTALL_DIR/adb-photo-sync.sh"

# Ensure script is run as root for systemd service installation
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Please run this script as root using sudo."
    exit 1
fi

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

# Check if adb-sync is installed
if ! command -v adb-sync &> /dev/null; then
    echo "❌ adb-sync is not installed!"
    echo "📌 Please install adb-sync using: pip install git+https://github.com/google/adb-sync.git"
    exit 1
else
    echo "✅ adb-sync is installed!"
fi

echo "📁 Creating sync directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

echo "🚀 Setting up the sync script..."
cat <<EOF > "$SCRIPT_FILE"
#!/bin/bash

# Configuration
FRAME_IP="$FRAME_IP"
SYNC_FOLDER="$INSTALL_DIR"
FRAME_SYNC_PATH="/storage/emulated/0/Pictures/"

echo "🔌 Connecting to ADB device at \$FRAME_IP..."
adb connect "\$FRAME_IP" || { echo "❌ ADB connection failed"; exit 1; }

echo "📂 Syncing photos to the frame..."
adb-sync "\$SYNC_FOLDER/" "\$FRAME_SYNC_PATH" || { echo "❌ Sync failed"; exit 1; }

echo "🔄 Triggering Media Scanner..."
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://\$FRAME_SYNC_PATH" || { echo "❌ Failed to trigger media scan"; exit 1; }

echo "✅ Sync completed successfully!"
EOF

chmod +x "$SCRIPT_FILE"

echo "📝 Creating systemd service at $SERVICE_FILE..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=ADB Photo Sync Service
After=network.target

[Service]
ExecStart=$SCRIPT_FILE
Restart=always
User=pi
Group=pi
WorkingDirectory=$INSTALL_DIR
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd and enabling the service..."
systemctl daemon-reload
systemctl enable adb-photo-sync
systemctl start adb-photo-sync

echo "✅ Installation complete!"
echo "📂 Sync folder: $INSTALL_DIR"
echo "⚙️ Service name: adb-photo-sync.service"
echo "🔍 Check status: sudo systemctl status adb-photo-sync"
