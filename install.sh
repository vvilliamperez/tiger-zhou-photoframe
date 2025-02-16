#!/bin/bash

# Define variables
INSTALL_DIR="$HOME/adb-photo-sync"
BINARY_NAME="adb-photo-sync"
SYSTEMD_SERVICE="/etc/systemd/system/adb-photo-sync.service"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Please run this script as root using sudo."
    exit 1
fi

# Prompt user for the frame's IP address
read -p "Enter the IP address of the smart photo frame: " FRAME_IP

echo "📁 Creating sync directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

echo "🚀 Moving compiled binary to /usr/local/bin/..."
if [ -f "target/release/$BINARY_NAME" ]; then
    mv "target/release/$BINARY_NAME" /usr/local/bin/
    chmod +x /usr/local/bin/$BINARY_NAME
else
    echo "❌ Error: Compiled binary not found. Please compile with 'cargo build --release' first."
    exit 1
fi

echo "📝 Creating systemd service at $SYSTEMD_SERVICE..."
cat <<EOF > $SYSTEMD_SERVICE
[Unit]
Description=ADB Photo Sync Service
After=network.target

[Service]
Environment="FRAME_IP=$FRAME_IP"
ExecStart=/usr/local/bin/$BINARY_NAME
Restart=always
User=$(whoami)
Group=$(whoami)
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
